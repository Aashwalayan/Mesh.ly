import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshly/models/mesh_envelope.dart';
import 'package:meshly/services/mesh_envelope_codec.dart';

void main() {
  test('round-trips a bounded direct chat envelope', () {
    final envelope = MeshEnvelope(
      messageId: 'message-1',
      origin: 'alice',
      destination: 'bob',
      ttl: 8,
      type: MeshEnvelope.chatType,
      payload: 'Hello',
      timestamp: DateTime.utc(2026, 10, 19, 12),
      expiresAt: DateTime.utc(2026, 10, 19, 12, 30),
    );

    final decoded =
        MeshEnvelopeCodec.tryDecode(MeshEnvelopeCodec.encode(envelope));

    expect(decoded, isNotNull);
    expect(decoded!.messageId, 'message-1');
    expect(decoded.payload, 'Hello');
    expect(decoded.hopCount, 0);
    expect(decoded.expiresAt, DateTime.utc(2026, 10, 19, 12, 30));
  });

  test('forwarding retains message identity and increments hop count', () {
    final envelope = MeshEnvelope(
      messageId: 'stable-id',
      origin: 'alice',
      destination: 'dina',
      ttl: 3,
      type: MeshEnvelope.chatType,
      timestamp: DateTime.utc(2026, 10, 19),
      expiresAt: DateTime.utc(2026, 10, 20),
    );

    final forwarded = envelope.decremented();

    expect(forwarded.messageId, envelope.messageId);
    expect(forwarded.origin, envelope.origin);
    expect(forwarded.ttl, 2);
    expect(forwarded.hopCount, 1);
  });

  test('rejects malformed or unbounded wire payloads', () {
    Uint8List bytes(Map<String, dynamic> json) =>
        Uint8List.fromList(utf8.encode(jsonEncode(json)));
    final valid = MeshEnvelope(
      messageId: 'id',
      origin: 'a',
      destination: 'b',
      ttl: 1,
      type: MeshEnvelope.chatType,
      timestamp: DateTime.utc(2026),
      expiresAt: DateTime.utc(2026, 1, 2),
    ).toJson();

    expect(
        MeshEnvelopeCodec.tryDecode(bytes({...valid, 'payload': 42})), isNull);
    expect(
        MeshEnvelopeCodec.tryDecode(bytes({...valid, 'hopCount': -1})), isNull);
    expect(
      MeshEnvelopeCodec.tryDecode(
          bytes({...valid, 'expiresAt': valid['timestamp']})),
      isNull,
    );
  });

  test('accepts a legacy direct-chat envelope during rollout', () {
    final legacy = {
      'messageId': 'old-id',
      'origin': 'a',
      'destination': 'b',
      'ttl': 1,
      'type': MeshEnvelope.chatType,
      'payload': 'existing peer',
      'timestamp': DateTime.utc(2026).millisecondsSinceEpoch,
    };

    final decoded = MeshEnvelopeCodec.tryDecode(
      Uint8List.fromList(utf8.encode(jsonEncode(legacy))),
    );
    expect(decoded, isNotNull);
    expect(decoded!.hopCount, 0);
  });
}
