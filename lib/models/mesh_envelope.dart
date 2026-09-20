/// The wire-level packet every device forwards, per the mesh protocol
/// (messageId / origin / destination / ttl / payload — see the project's
/// architecture doc, Section 6).
///
/// Distinct from [Message] on purpose: this is what travels between
/// devices and gets forwarded by strangers' phones that have never heard
/// of the conversation; [Message] is what the Chat UI displays once an
/// envelope has actually reached its destination.
class MeshEnvelope {
  /// A normal chat message, delivered to the UI when it reaches its
  /// destination.
  static const chatType = 'chat';

  /// Sent once, single-hop only, right after two devices connect — lets
  /// each side learn the other's real Mesh ID. Never forwarded, never
  /// deduped via [seenMessageIds] (a fresh hello should fire on every new
  /// connection, not just the first one ever seen).
  static const helloType = 'hello';

  MeshEnvelope({
    required this.messageId,
    required this.origin,
    required this.destination,
    required this.ttl,
    required this.type,
    this.payload = '',
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  final String messageId;

  /// The ORIGINAL author's Mesh ID — not necessarily the peer bytes just
  /// arrived from, since this may have already been forwarded by others.
  final String origin;

  /// The final intended recipient's Mesh ID. Empty for [helloType], which
  /// has no destination — it's addressed to whichever device is on the
  /// other end of the connection that was just made.
  final String destination;

  final int ttl;
  final String type;
  final String payload;
  final DateTime timestamp;

  /// Returns a copy with [ttl] decremented — used when forwarding.
  MeshEnvelope decremented() => MeshEnvelope(
    messageId: messageId,
    origin: origin,
    destination: destination,
    ttl: ttl - 1,
    type: type,
    payload: payload,
    timestamp: timestamp,
  );

  Map<String, dynamic> toJson() => {
    'messageId': messageId,
    'origin': origin,
    'destination': destination,
    'ttl': ttl,
    'type': type,
    'payload': payload,
    'timestamp': timestamp.millisecondsSinceEpoch,
  };

  /// Returns null for malformed data rather than throwing — a payload from
  /// an untrusted nearby device should never be able to crash the app.
  static MeshEnvelope? tryFromJson(Map<String, dynamic> json) {
    final messageId = json['messageId'];
    final origin = json['origin'];
    final destination = json['destination'];
    final ttl = json['ttl'];
    final type = json['type'];
    final payload = json['payload'];
    final timestampMs = json['timestamp'];

    if (messageId is! String ||
        messageId.isEmpty ||
        origin is! String ||
        origin.isEmpty ||
        destination is! String ||
        ttl is! int ||
        type is! String) {
      return null;
    }

    return MeshEnvelope(
      messageId: messageId,
      origin: origin,
      destination: destination,
      ttl: ttl,
      type: type,
      payload: payload is String ? payload : '',
      timestamp: timestampMs is int
          ? DateTime.fromMillisecondsSinceEpoch(timestampMs)
          : DateTime.now(),
    );
  }
}