import 'dart:math';

/// Utility for retrying async operations with exponential backoff and jitter.
///
/// Backoff formula: `min(maxDelay, baseDelay * 2^attempt) + random_jitter`.
class RetryHelper {
  const RetryHelper({
    this.maxAttempts = 5,
    this.baseDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 30),
    this.jitterFactor = 0.25,
  });

  /// Maximum number of attempts before giving up.
  final int maxAttempts;

  /// Base delay for the first retry.
  final Duration baseDelay;

  /// Upper bound for the backoff delay.
  final Duration maxDelay;

  /// Jitter as a fraction of the computed delay (0.0 - 1.0).
  final double jitterFactor;

  /// Run [action] with retries on failure.
  ///
  /// Optionally pass [shouldRetry] to control which exceptions trigger a retry.
  /// Returns the result of the first successful call, or rethrows the last
  /// exception after [maxAttempts] failures.
  Future<T> run<T>(
    Future<T> Function() action, {
    bool Function(Exception)? shouldRetry,
  }) async {
    final random = Random();
    Exception? lastException;

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        return await action();
      } on Exception catch (e) {
        lastException = e;

        if (shouldRetry != null && !shouldRetry(e)) {
          rethrow;
        }

        if (attempt < maxAttempts - 1) {
          final delay = _computeDelay(attempt, random);
          await Future<void>.delayed(delay);
        }
      }
    }

    throw lastException!;
  }

  /// Compute the delay for a given attempt number.
  Duration _computeDelay(int attempt, Random random) {
    final exponentialMs =
        baseDelay.inMilliseconds * (1 << attempt); // 2^attempt
    final clampedMs = min(exponentialMs, maxDelay.inMilliseconds);
    final jitterMs = (clampedMs * jitterFactor * random.nextDouble()).round();
    return Duration(milliseconds: clampedMs + jitterMs);
  }
}

/// A default [RetryHelper] suitable for network requests.
const networkRetry = RetryHelper(
  maxAttempts: 5,
  baseDelay: Duration(seconds: 1),
  maxDelay: Duration(seconds: 30),
  jitterFactor: 0.25,
);

/// A more aggressive [RetryHelper] for critical operations like uploads.
const uploadRetry = RetryHelper(
  maxAttempts: 8,
  baseDelay: Duration(seconds: 2),
  maxDelay: Duration(minutes: 2),
  jitterFactor: 0.3,
);
