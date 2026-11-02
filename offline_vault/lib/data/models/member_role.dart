/// Represents a member's role within a group.
///
/// Roles determine what actions a member can perform. They are ordered
/// from most to least privileged.
enum MemberRole {
  /// Full control: manage members, delete group, all editor abilities.
  owner('owner', 'Owner'),

  /// Can upload, delete files, create folders. Cannot manage members.
  editor('editor', 'Editor'),

  /// Read-only access to files and folders.
  viewer('viewer', 'Viewer');

  const MemberRole(this.value, this.displayName);

  /// The string value persisted to the database and sent over the wire.
  final String value;

  /// Human-readable name for display in the UI.
  final String displayName;

  /// Whether this role can upload files and create folders (all group members can share).
  bool get canEdit => true;

  /// Whether this role can manage group members and settings.
  bool get canManageMembers => this == owner;

  /// Parse from a database/API string, defaulting to [viewer] for unknown values.
  static MemberRole fromString(String raw) {
    return MemberRole.values.firstWhere(
      (e) => e.value == raw,
      orElse: () => MemberRole.viewer,
    );
  }
}
