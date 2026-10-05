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
    required this.publicKey,
    this.keyAlgorithm = 'Ed25519',
    this.keyVersion = 1,
    this.isVerified = true,
  });

  final String id;
  final String username;
  final String meshId;
  final String? avatar;
  final String? lastSeen;
  final String publicKey;
  final String keyAlgorithm;
  final int keyVersion;

  /// True means the signed key was checked and accepted during an explicit
  /// QR scan or Nearby add action. It does not assert real-world identity.
  final bool isVerified;

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'meshId': meshId,
        'avatar': avatar,
        'lastSeen': lastSeen,
        'publicKey': publicKey,
        'keyAlgorithm': keyAlgorithm,
        'keyVersion': keyVersion,
        'isVerified': isVerified,
      };

  static Contact? tryFromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final username = json['username'];
    final meshId = json['meshId'];
    final publicKey = json['publicKey'];
    if (id is! String ||
        username is! String ||
        username.isEmpty ||
        meshId is! String ||
        meshId.isEmpty ||
        publicKey is! String ||
        publicKey.isEmpty) {
      return null;
    }
    return Contact(
        id: id,
        username: username,
        meshId: meshId,
        publicKey: publicKey,
        avatar: json['avatar'] as String?,
        lastSeen: json['lastSeen'] as String?,
        keyAlgorithm: json['keyAlgorithm'] as String? ?? 'Ed25519',
        keyVersion: json['keyVersion'] as int? ?? 1,
        isVerified: json['isVerified'] as bool? ?? true);
  }
}
