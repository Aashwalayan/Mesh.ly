import 'dart:convert';
import 'dart:typed_data';

import '../models/mesh_envelope.dart';

/// JSON codec for [MeshEnvelope] — the bytes that actually travel over
/// [DiscoveryService.sendBytes]/[DiscoveryService.onPayloadReceived].
class MeshEnvelopeCodec {
  MeshEnvelopeCodec._();

  static Uint8List encode(MeshEnvelope envelope) =>
      Uint8List.fromList(utf8.encode(jsonEncode(envelope.toJson())));

  static MeshEnvelope? tryDecode(Uint8List bytes) {
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map) return null;
      return MeshEnvelope.tryFromJson(Map<String, dynamic>.from(decoded));
    } on FormatException {
      return null;
    }
  }
}