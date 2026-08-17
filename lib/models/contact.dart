/// A saved contact in the user's mesh network.
///
/// `lastSeen` is a free-text mock ("Nearby", "2h ago", ...) — it will
/// eventually be derived from real peer-discovery data.
class Contact {
  const Contact({
    required this.id,
    required this.username,
    required this.meshId,
    this.avatar,
    this.lastSeen,
  });

  final String id;
  final String username;
  final String meshId;
  final String? avatar;
  final String? lastSeen;
}
