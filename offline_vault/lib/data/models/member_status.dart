/// Represents whether a member is currently active in a group.
enum MemberStatus {
  /// The member is active and has access.
  active('active', 'Active'),

  /// The member has been removed from the group.
  removed('removed', 'Removed');

  const MemberStatus(this.value, this.displayName);

  /// The string value persisted to the database.
  final String value;

  /// Human-readable name for display in the UI.
  final String displayName;

  /// Parse from a database/API string, defaulting to [active].
  static MemberStatus fromString(String raw) {
    return MemberStatus.values.firstWhere(
      (e) => e.value == raw,
      orElse: () => MemberStatus.active,
    );
  }
}
