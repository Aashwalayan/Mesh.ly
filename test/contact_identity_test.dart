import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshly/models/contact_identity.dart';

Future<ContactIdentity> _card(String name) async {
  final algorithm = Ed25519();
  final pair = await algorithm.newKeyPair();
  final publicKey = base64UrlEncode((await pair.extractPublicKey()).bytes);
  final unsigned = ContactIdentity(
    username: name,
    meshId: ContactIdentity.meshIdForPublicKey(publicKey),
    publicKey: publicKey,
    signature: '',
  );
  final signature = await algorithm.sign(
    utf8.encode(unsigned.signingPayload()),
    keyPair: pair,
  );
  return ContactIdentity(
    username: name,
    meshId: unsigned.meshId,
    publicKey: publicKey,
    signature: base64UrlEncode(signature.bytes),
  );
}

void main() {
  test('a signed contact card round-trips and verifies', () async {
    final card = await _card('Alice');
    final parsed =
        await ContactIdentity.tryParseAndVerify(jsonEncode(card.toJson()));
    expect(parsed?.meshId, card.meshId);
    expect(parsed?.publicKey, card.publicKey);
  });

  test('a changed card field is rejected', () async {
    final card = await _card('Alice');
    final json = card.toJson()..['username'] = 'Mallory';
    expect(await ContactIdentity.tryParseAndVerify(jsonEncode(json)), isNull);
  });

  test('malformed QR payload is rejected', () async {
    expect(await ContactIdentity.tryParseAndVerify('{not json'), isNull);
  });
}
