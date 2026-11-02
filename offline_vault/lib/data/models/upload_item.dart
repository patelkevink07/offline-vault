/// Represents an item in the upload queue.
///
/// Tracks the local file that needs to be uploaded to Supabase Storage,
/// its progress, and any errors encountered during upload attempts.
class UploadItem {
  const UploadItem({
    required this.id,
    required this.localPath,
    required this.groupId,
    this.folderId,
    required this.name,
    required this.mime,
    required this.state,
    required this.bytesSent,
    required this.attempts,
    this.lastError,
    required this.createdAt,
  });

  /// Unique identifier for this upload queue entry.
  final String id;

  /// Absolute path to the local file waiting to be uploaded.
  final String localPath;

  /// The group this file belongs to.
  final String groupId;

  /// Optional folder within the group.
  final String? folderId;

  /// Display name for the file.
  final String name;

  /// MIME type of the file (e.g. 'image/jpeg').
  final String mime;

  /// Current upload state.
  final UploadState state;

  /// Number of bytes successfully sent so far (for resumable uploads).
  final int bytesSent;

  /// Number of upload attempts made.
  final int attempts;

  /// Error message from the last failed attempt, if any.
  final String? lastError;

  /// When this item was added to the queue.
  final DateTime createdAt;

  /// Whether this item can be retried.
  bool get canRetry =>
      state == UploadState.failed || state == UploadState.pending;

  /// Whether this item is currently being uploaded.
  bool get isActive => state == UploadState.uploading;

  UploadItem copyWith({
    String? id,
    String? localPath,
    String? groupId,
    String? folderId,
    String? name,
    String? mime,
    UploadState? state,
    int? bytesSent,
    int? attempts,
    String? lastError,
    DateTime? createdAt,
  }) {
    return UploadItem(
      id: id ?? this.id,
      localPath: localPath ?? this.localPath,
      groupId: groupId ?? this.groupId,
      folderId: folderId ?? this.folderId,
      name: name ?? this.name,
      mime: mime ?? this.mime,
      state: state ?? this.state,
      bytesSent: bytesSent ?? this.bytesSent,
      attempts: attempts ?? this.attempts,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'UploadItem(name: $name, state: $state)';
}

/// Possible states of an upload queue item.
enum UploadState {
  /// Waiting to be picked up by the upload worker.
  pending('pending'),

  /// Currently being uploaded.
  uploading('uploading'),

  /// Successfully uploaded and confirmed.
  done('done'),

  /// Upload failed after all retry attempts.
  failed('failed');

  const UploadState(this.value);

  final String value;

  static UploadState fromString(String raw) {
    return UploadState.values.firstWhere(
      (e) => e.value == raw,
      orElse: () => UploadState.pending,
    );
  }
}
