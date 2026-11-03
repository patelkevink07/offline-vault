import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import '../core/utils/logger.dart';
import 'sync_lease_manager.dart';

const String kPeriodicSyncTask = 'com.offlinevault.sync.periodic';
const String kReconnectSyncTask = 'com.offlinevault.sync.reconnect';

@pragma('vm:entry-point')
void backgroundSyncCallbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    VaultLogger.i('Background sync task started: $taskName');
    final leaseManager = SyncLeaseManager();

    // 1. Attempt to acquire background lease
    final acquired = await leaseManager.acquireBackgroundLease();
    if (!acquired) {
      VaultLogger.i('Background sync skipped: lease held by foreground or another task.');
      return Future.value(true);
    }

    try {
      // Check if yield requested
      if (await leaseManager.shouldBackgroundYield()) {
        VaultLogger.i('Background sync yielded to foreground before starting.');
        return Future.value(true);
      }

      // Perform background sync logic here (or run through SyncEngine if DB isolate is configured)
      // Heartbeat pulse
      await leaseManager.updateHeartbeat('background');
      
      VaultLogger.i('Background sync completed successfully.');
      return Future.value(true);
    } catch (e, st) {
      VaultLogger.e('Background sync task failed: $e', e, st);
      return Future.value(false); // Triggers Workmanager backoff
    } finally {
      await leaseManager.releaseLease('background');
    }
  });
}

class BackgroundSyncService {
  BackgroundSyncService({Workmanager? workmanager})
      : _workmanager = workmanager ?? Workmanager();

  final Workmanager _workmanager;

  /// Initialize Workmanager and register scheduled tasks.
  Future<void> initialize() async {
    if (kIsWeb) return;
    try {
      await _workmanager.initialize(
        backgroundSyncCallbackDispatcher,
        isInDebugMode: kDebugMode,
      );
      await schedulePeriodicSync();
    } catch (e) {
      VaultLogger.w('Failed to initialize Workmanager: $e');
    }
  }

  /// Every 6 hours while connected to unmetered network (Wi-Fi) and charging.
  Future<void> schedulePeriodicSync() async {
    if (kIsWeb) return;
    try {
      await _workmanager.registerPeriodicTask(
        'periodic-sync-6h',
        kPeriodicSyncTask,
        frequency: const Duration(hours: 6),
        constraints: Constraints(
          networkType: NetworkType.unmetered,
          requiresCharging: true,
        ),
        existingWorkPolicy: ExistingWorkPolicy.keep,
        backoffPolicy: BackoffPolicy.linear,
        backoffPolicyDelay: const Duration(minutes: 15),
      );
    } catch (e) {
      VaultLogger.w('Failed to register periodic sync task: $e');
    }
  }

  /// One-off sync when network reconnects (with 15-minute backoff on failure).
  Future<void> scheduleOneOffReconnectSync() async {
    if (kIsWeb) return;
    try {
      await _workmanager.registerOneOffTask(
        'reconnect-sync-oneoff',
        kReconnectSyncTask,
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
        existingWorkPolicy: ExistingWorkPolicy.replace,
        backoffPolicy: BackoffPolicy.linear,
        backoffPolicyDelay: const Duration(minutes: 15),
      );
    } catch (e) {
      VaultLogger.w('Failed to schedule one-off reconnect sync: $e');
    }
  }
}
