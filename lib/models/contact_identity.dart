import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart';

/// A signed, public identity card. It is safe to share in a QR code or over
/// Nearby; private signing material never appears here.
class ContactIdentity {
  const ContactIdentity({
    required this.username,
    required this.meshId,
    required this.publicKey,
    required this.signature,
    this.version = 1,
  });

  static const algorithm = 'Ed25519';
  static const schema = 'meshly-contact-card';

  final String username;
  final String meshId;
  final String publicKey; // base64url-encoded Ed25519 public key
  final String signature; // base64url-encoded Ed25519 signature
  final int version;

  String get fingerprint => meshId.replaceFirst('MESH-', '');

  Map<String, dynamic> toJson() => {
        'schema': schema,
        'version': version,
        'algorithm': algorithm,
        'username': username,
        'meshId': meshId,
        'publicKey': publicKey,
        'signature': signature,
      };

  /// The signature deliberately excludes itself and has stable field order.
  String signingPayload() => jsonEncode({
        'schema': schema,
        'version': version,
        'algorithm': algorithm,
        'username': username,
        'meshId': meshId,
        'publicKey': publicKey,
      });

  static String meshIdForPublicKey(String publicKey) {
    final digest =
        sha256.convert(base64Url.decode(base64Url.normalize(publicKey)));
    return 'MESH-${digest.bytes.take(10).map((b) => b.toRadixString(16).padLeft(2, '0')).join().toUpperCase()}';
  }

  static Future<ContactIdentity?> tryParseAndVerify(String raw) async {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return null;
      }
      final json = Map<String, dynamic>.from(decoded);
      if (json['schema'] != schema ||
          json['version'] != 1 ||
          json['algorithm'] != algorithm) {
        return null;
      }
      final username = json['username'];
      final meshId = json['meshId'];
      final publicKey = json['publicKey'];
      final signature = json['signature'];
      if (username is! String ||
          username.trim().isEmpty ||
          username.length > 80 ||
          meshId is! String ||
          publicKey is! String ||
          signature is! String ||
          meshId != meshIdForPublicKey(publicKey)) {
        return null;
      }
      final card = ContactIdentity(
        username: username.trim(),
        meshId: meshId,
        publicKey: publicKey,
        signature: signature,
      );
      final valid = await Ed25519().verify(
        utf8.encode(card.signingPayload()),
        signature: Signature(
          base64Url.decode(base64Url.normalize(signature)),
          publicKey: SimplePublicKey(
            base64Url.decode(base64Url.normalize(publicKey)),
            type: KeyPairType.ed25519,
          ),
        ),
      );
      return valid ? card : null;
    } catch (_) {
      return null;
    }
  }
}
