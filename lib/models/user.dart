/// The local user's frontend-only profile.
///
/// NOTE: `meshId` is a mock string for now. There is no real cryptographic
/// identity yet — when that lands, this model just gains a field, callers
/// don't need to change.
class User {
  const User({
    required this.username,
    required this.meshId,
    this.avatar,
  });

  final String username;
  final String meshId;

  /// Path/asset for an avatar image. Null falls back to initials in the UI.
  final String? avatar;
}
