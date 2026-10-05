import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/contact_identity.dart';

/// Owns the device's long-lived Ed25519 keypair. Android uses encrypted
/// Keystore-backed storage through flutter_secure_storage; no private key is
/// written to SharedPreferences or sent over the mesh.
class IdentityKeyService {
  IdentityKeyService._();
  static final instance = IdentityKeyService._();

  static const _privateKeyStorageKey = 'meshly_ed25519_private_key_v1';
  final _storage = const FlutterSecureStorage();
  final _algorithm = Ed25519();
  SimpleKeyPairData? _keyPair;

  Future<SimpleKeyPairData> keyPair() async {
    if (_keyPair != null) return _keyPair!;
    final saved = await _storage.read(key: _privateKeyStorageKey);
    if (saved != null) {
      try {
        final decoded = jsonDecode(saved) as Map<String, dynamic>;
        final privateBytes = base64Url
            .decode(base64Url.normalize(decoded['privateKey'] as String));
        final publicBytes = base64Url
            .decode(base64Url.normalize(decoded['publicKey'] as String));
        return _keyPair = SimpleKeyPairData(privateBytes,
            publicKey: SimplePublicKey(publicBytes, type: KeyPairType.ed25519),
            type: KeyPairType.ed25519);
      } catch (_) {
        // An unreadable key cannot safely be reused. Generate a new identity;
        // callers will derive a new Mesh ID from it.
      }
    }
    final generated = await _algorithm.newKeyPair();
    final extracted = await generated.extract();
    await _storage.write(
      key: _privateKeyStorageKey,
      value: jsonEncode({
        'privateKey': base64UrlEncode(extracted.bytes),
        'publicKey': base64UrlEncode(extracted.publicKey.bytes),
      }),
    );
    return _keyPair = extracted;
  }

  Future<ContactIdentity> createSignedCard(String username) async {
    final pair = await keyPair();
    final publicKey = base64UrlEncode(pair.publicKey.bytes);
    final unsigned = ContactIdentity(
      username: username,
      meshId: ContactIdentity.meshIdForPublicKey(publicKey),
      publicKey: publicKey,
      signature: '',
    );
    final signature = await _algorithm.sign(
      utf8.encode(unsigned.signingPayload()),
      keyPair: pair,
    );
    return ContactIdentity(
      username: unsigned.username,
      meshId: unsigned.meshId,
      publicKey: publicKey,
      signature: base64UrlEncode(signature.bytes),
    );
  }
}
