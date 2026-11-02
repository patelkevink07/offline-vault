/// Compression quality presets for uploaded images.
///
/// Controls the trade-off between image quality and storage/bandwidth
/// usage. Each preset defines a JPEG quality level and maximum dimension.
enum CompressionQuality {
  /// No compression; upload the original file as-is.
  original(
    value: 'original',
    displayName: 'Original',
    description: 'No compression — best quality, largest file size',
    jpegQuality: 100,
    maxDimension: null,
  ),

  /// High-quality compression; visually indistinguishable for most images.
  high(
    value: 'high',
    displayName: 'High quality',
    description: 'Slight compression — great quality, smaller files',
    jpegQuality: 85,
    maxDimension: 4096,
  ),

  /// Aggressive compression to minimize bandwidth and storage.
  dataSaver(
    value: 'data_saver',
    displayName: 'Data saver',
    description: 'Smaller files — uses less storage and mobile data',
    jpegQuality: 60,
    maxDimension: 2048,
  );

  const CompressionQuality({
    required this.value,
    required this.displayName,
    required this.description,
    required this.jpegQuality,
    required this.maxDimension,
  });

  /// The string value persisted to preferences.
  final String value;

  /// Human-readable name for display in the UI.
  final String displayName;

  /// Longer description explaining the trade-off.
  final String description;

  /// JPEG quality level (1-100).
  final int jpegQuality;

  /// Maximum width or height in pixels, or null for no limit.
  final int? maxDimension;

  /// Parse from a persisted string, defaulting to [high].
  static CompressionQuality fromString(String raw) {
    return CompressionQuality.values.firstWhere(
      (e) => e.value == raw,
      orElse: () => CompressionQuality.high,
    );
  }
}
