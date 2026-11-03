import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/utils/logger.dart';

class SyncLeaseInfo {
  final String holder; // 'none', 'foreground', 'background'
  final DateTime acquiredAt;
  final DateTime heartbeat;
  final bool yieldRequested;

  const SyncLeaseInfo({
    required this.holder,
    required this.acquiredAt,
    required this.heartbeat,
    required this.yieldRequested,
  });

  Map<String, dynamic> toJson() => {
        'holder': holder,
        'acquiredAt': acquiredAt.toIso8601String(),
        'heartbeat': heartbeat.toIso8601String(),
        'yieldRequested': yieldRequested,
      };

  factory SyncLeaseInfo.fromJson(Map<String, dynamic> json) {
    return SyncLeaseInfo(
      holder: json['holder'] as String? ?? 'none',
      acquiredAt: DateTime.tryParse(json['acquiredAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      heartbeat: DateTime.tryParse(json['heartbeat'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      yieldRequested: json['yieldRequested'] as bool? ?? false,
    );
  }

  static SyncLeaseInfo none() => SyncLeaseInfo(
        holder: 'none',
        acquiredAt: DateTime.fromMillisecondsSinceEpoch(0),
        heartbeat: DateTime.fromMillisecondsSinceEpoch(0),
        yieldRequested: false,
      );
}

/// Coordinates sync operations across foreground and background isolates.
/// Prevents concurrent SQLite access and guarantees foreground precedence.
class SyncLeaseManager {
  SyncLeaseManager({String? customDir}) : _customDir = customDir;

  final String? _customDir;

  Future<File> _getLeaseFile() async {
    final dir = _customDir ?? (await getApplicationSupportDirectory()).path;
    return File(p.join(dir, 'sync_lease.json'));
  }

  Future<SyncLeaseInfo> getLeaseInfo() async {
    try {
      final file = await _getLeaseFile();
      if (!file.existsSync()) {
        return SyncLeaseInfo.none();
      }
      final content = await file.readAsString();
      if (content.trim().isEmpty) return SyncLeaseInfo.none();
      return SyncLeaseInfo.fromJson(jsonDecode(content) as Map<String, dynamic>);
    } catch (_) {
      return SyncLeaseInfo.none();
    }
  }

  Future<void> _writeLeaseInfo(SyncLeaseInfo info) async {
    try {
      final file = await _getLeaseFile();
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode(info.toJson()), flush: true);
    } catch (e) {
      VaultLogger.w('Failed to write sync lease info: $e');
    }
  }

  /// Foreground attempts to acquire the lease.
  /// If background holds it, foreground requests yield and waits up to 2 seconds.
  /// If background does not yield within 2 seconds, foreground preempts it.
  Future<bool> acquireForegroundLease({
    Duration timeout = const Duration(seconds: 2),
  }) async {
    final current = await getLeaseInfo();
    final now = DateTime.now();

    if (current.holder == 'background') {
      // Signal background task to yield
      await _writeLeaseInfo(
        SyncLeaseInfo(
          holder: 'background',
          acquiredAt: current.acquiredAt,
          heartbeat: current.heartbeat,
          yieldRequested: true,
        ),
      );

      // Wait up to timeout for background to release
      final stopwatch = Stopwatch()..start();
      while (stopwatch.elapsed < timeout) {
        await Future.delayed(const Duration(milliseconds: 100));
        final updated = await getLeaseInfo();
        if (updated.holder != 'background') {
          break;
        }
      }
    }

    // Acquire lease for foreground
    await _writeLeaseInfo(
      SyncLeaseInfo(
        holder: 'foreground',
        acquiredAt: now,
        heartbeat: now,
        yieldRequested: false,
      ),
    );
    return true;
  }

  /// Background attempts to acquire the lease.
  /// Returns false if foreground holds lease or background is already running.
  Future<bool> acquireBackgroundLease() async {
    final current = await getLeaseInfo();
    final now = DateTime.now();

    // Check if foreground active (heartbeat within 15 seconds)
    if (current.holder == 'foreground' &&
        now.difference(current.heartbeat).inSeconds < 15) {
      return false;
    }

    // Check if another background task is already active
    if (current.holder == 'background' &&
        now.difference(current.heartbeat).inSeconds < 15 &&
        !current.yieldRequested) {
      return false;
    }

    // Acquire lease for background
    await _writeLeaseInfo(
      SyncLeaseInfo(
        holder: 'background',
        acquiredAt: now,
        heartbeat: now,
        yieldRequested: false,
      ),
    );
    return true;
  }

  /// Background worker checks if it should yield to foreground immediately.
  Future<bool> shouldBackgroundYield() async {
    final current = await getLeaseInfo();
    if (current.holder != 'background' || current.yieldRequested) {
      return true;
    }
    return false;
  }

  /// Update heartbeat during long sync operations.
  Future<void> updateHeartbeat(String holder) async {
    final current = await getLeaseInfo();
    if (current.holder == holder) {
      await _writeLeaseInfo(
        SyncLeaseInfo(
          holder: holder,
          acquiredAt: current.acquiredAt,
          heartbeat: DateTime.now(),
          yieldRequested: current.yieldRequested,
        ),
      );
    }
  }

  /// Release lease when sync finishes.
  Future<void> releaseLease(String holder) async {
    final current = await getLeaseInfo();
    if (current.holder == holder) {
      await _writeLeaseInfo(SyncLeaseInfo.none());
    }
  }
}
