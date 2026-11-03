import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:offline_vault/sync/background_sync_service.dart';
import 'package:offline_vault/sync/sync_lease_manager.dart';
import 'package:workmanager/workmanager.dart';

class MockWorkmanager extends Mock implements Workmanager {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late SyncLeaseManager leaseManager;
  late MockWorkmanager mockWorkmanager;

  setUpAll(() {
    registerFallbackValue(ExistingWorkPolicy.keep);
    registerFallbackValue(BackoffPolicy.linear);
    registerFallbackValue(Constraints(networkType: NetworkType.connected));
    registerFallbackValue(const Duration(minutes: 15));
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('lease_test_');
    leaseManager = SyncLeaseManager(customDir: tempDir.path);
    mockWorkmanager = MockWorkmanager();
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Phase 5: Background Sync & Lease Manager Tests', () {
    test('Background acquires lease when idle; second background request is rejected', () async {
      // 1. Initial lease is idle/none
      final initial = await leaseManager.getLeaseInfo();
      expect(initial.holder, 'none');

      // 2. Background acquires lease
      final acquired = await leaseManager.acquireBackgroundLease();
      expect(acquired, isTrue);

      final current = await leaseManager.getLeaseInfo();
      expect(current.holder, 'background');
      expect(current.yieldRequested, isFalse);

      // 3. Second background request is rejected (prevents concurrent background syncs)
      final secondAttempt = await leaseManager.acquireBackgroundLease();
      expect(secondAttempt, isFalse);

      // 4. Release lease
      await leaseManager.releaseLease('background');
      final released = await leaseManager.getLeaseInfo();
      expect(released.holder, 'none');
    });

    test('Foreground takes precedence over background and forces yield within timeout', () async {
      // 1. Background holds lease
      await leaseManager.acquireBackgroundLease();
      expect((await leaseManager.getLeaseInfo()).holder, 'background');

      // 2. Simulate background task yielding when yield is requested
      Future.delayed(const Duration(milliseconds: 150), () async {
        final shouldYield = await leaseManager.shouldBackgroundYield();
        if (shouldYield) {
          await leaseManager.releaseLease('background');
        }
      });

      // 3. Foreground acquires lease (signals yield and waits)
      final acquired = await leaseManager.acquireForegroundLease(
        timeout: const Duration(seconds: 2),
      );
      expect(acquired, isTrue);

      // 4. Foreground is now the sole lease holder
      final finalInfo = await leaseManager.getLeaseInfo();
      expect(finalInfo.holder, 'foreground');

      // 5. While foreground holds lease, background cannot acquire
      final bgAttempt = await leaseManager.acquireBackgroundLease();
      expect(bgAttempt, isFalse);

      await leaseManager.releaseLease('foreground');
    });

    test('Background task schedules 6-hour periodic sync with unmetered & charging constraints', () async {
      when(
        () => mockWorkmanager.registerPeriodicTask(
          any(),
          any(),
          frequency: any(named: 'frequency'),
          constraints: any(named: 'constraints'),
          existingWorkPolicy: any(named: 'existingWorkPolicy'),
          backoffPolicy: any(named: 'backoffPolicy'),
          backoffPolicyDelay: any(named: 'backoffPolicyDelay'),
        ),
      ).thenAnswer((_) async {});

      final service = BackgroundSyncService(workmanager: mockWorkmanager);
      await service.schedulePeriodicSync();

      verify(
        () => mockWorkmanager.registerPeriodicTask(
          'periodic-sync-6h',
          kPeriodicSyncTask,
          frequency: const Duration(hours: 6),
          constraints: any(
            named: 'constraints',
            that: isA<Constraints>()
                .having((c) => c.networkType, 'networkType', NetworkType.unmetered)
                .having((c) => c.requiresCharging, 'requiresCharging', isTrue),
          ),
          existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
          backoffPolicy: BackoffPolicy.linear,
          backoffPolicyDelay: const Duration(minutes: 15),
        ),
      ).called(1);
    });

    test('Background task schedules one-off reconnect sync with connected constraint', () async {
      when(
        () => mockWorkmanager.registerOneOffTask(
          any(),
          any(),
          constraints: any(named: 'constraints'),
          existingWorkPolicy: any(named: 'existingWorkPolicy'),
          backoffPolicy: any(named: 'backoffPolicy'),
          backoffPolicyDelay: any(named: 'backoffPolicyDelay'),
        ),
      ).thenAnswer((_) async {});

      final service = BackgroundSyncService(workmanager: mockWorkmanager);
      await service.scheduleOneOffReconnectSync();

      verify(
        () => mockWorkmanager.registerOneOffTask(
          'reconnect-sync-oneoff',
          kReconnectSyncTask,
          constraints: any(
            named: 'constraints',
            that: isA<Constraints>()
                .having((c) => c.networkType, 'networkType', NetworkType.connected),
          ),
          existingWorkPolicy: ExistingWorkPolicy.replace,
          backoffPolicy: BackoffPolicy.linear,
          backoffPolicyDelay: const Duration(minutes: 15),
        ),
      ).called(1);
    });
  });
}
