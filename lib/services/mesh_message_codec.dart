import 'dart:convert';
import 'dart:typed_data';

import '../models/message.dart';

/// JSON codec for the minimal direct-peer message envelope.
class MeshMessageCodec {
  MeshMessageCodec._();

  static Uint8List encodeTestMessage(Message message) =>
      Uint8List.fromList(utf8.encode(jsonEncode(message.toTestEnvelope())));

  static Message? tryDecodeTestMessage(Uint8List bytes) {
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map) return null;
      return Message.fromTestEnvelope(Map<String, dynamic>.from(decoded));
    } on FormatException {
      return null;
    } on ArgumentError {
      return null;
    }
  }
}
