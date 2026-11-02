/// The result of a synchronisation cycle.
///
/// Captures timing, byte counts, and whether the sync completed, failed,
/// or was cancelled (e.g. by the user going offline mid-sync).
class SyncResult {
  const SyncResult({
    required this.startedAt,
    required this.endedAt,
    required this.bytesDown,
    required this.bytesUp,
    required this.result,
    this.errorMessage,
  });

  /// When the sync cycle began.
  final DateTime startedAt;

  /// When the sync cycle ended (may be null if still running).
  final DateTime? endedAt;

  /// Total bytes downloaded during this cycle.
  final int bytesDown;

  /// Total bytes uploaded during this cycle.
  final int bytesUp;

  /// Outcome label: 'success', 'partial', 'failed', 'cancelled'.
  final SyncOutcome result;

  /// Human-readable error message if [result] is [SyncOutcome.failed].
  final String? errorMessage;

  /// Duration of the sync cycle, or null if it hasn't ended.
  Duration? get duration => endedAt?.difference(startedAt);

  /// Total bytes transferred in both directions.
  int get totalBytes => bytesDown + bytesUp;

  SyncResult copyWith({
    DateTime? startedAt,
    DateTime? endedAt,
    int? bytesDown,
    int? bytesUp,
    SyncOutcome? result,
    String? errorMessage,
  }) {
    return SyncResult(
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      bytesDown: bytesDown ?? this.bytesDown,
      bytesUp: bytesUp ?? this.bytesUp,
      result: result ?? this.result,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  String toString() =>
      'SyncResult(result: $result, down: $bytesDown, up: $bytesUp)';
}

/// Possible outcomes of a sync cycle.
enum SyncOutcome {
  /// All pending changes were synchronised successfully.
  success('success'),

  /// Some changes were synchronised but others remain pending.
  partial('partial'),

  /// The sync cycle failed due to an error.
  failed('failed'),

  /// The sync cycle was cancelled by the user or a connectivity change.
  cancelled('cancelled');

  const SyncOutcome(this.value);

  final String value;

  static SyncOutcome fromString(String raw) {
    return SyncOutcome.values.firstWhere(
      (e) => e.value == raw,
      orElse: () => SyncOutcome.failed,
    );
  }
}
