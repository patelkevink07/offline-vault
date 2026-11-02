/// Represents the synchronisation state of a file's thumbnail or original.
enum FileSyncState {
  /// The file exists only on the server; no local data.
  remote('remote'),

  /// The file has been queued for download but hasn't started.
  queued('queued'),

  /// The file is currently being downloaded.
  downloading('downloading'),

  /// The file has been downloaded and is ready to view.
  ready('ready'),

  /// The download failed after all retry attempts.
  failed('failed');

  const FileSyncState(this.value);

  /// The string value persisted to the database.
  final String value;

  /// Parse from a database string, defaulting to [remote] for unknown values.
  static FileSyncState fromString(String raw) {
    return FileSyncState.values.firstWhere(
      (e) => e.value == raw,
      orElse: () => FileSyncState.remote,
    );
  }
}
