/// The wire-level packet every device forwards.
///
/// This is deliberately a transport envelope rather than a second chat
/// model: [payload] remains the existing direct-chat payload.  The routing
/// fields are additive, so a directly connected peer uses exactly the same
/// path as before while future route discovery can use the same codec.
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

  /// A bounded broadcast used only to locate an unknown destination.
  static const routeDiscoveryType = 'route_discovery';

  /// A unicast reply that follows temporary reverse-path state back to the
  /// node that started [routeDiscoveryType].
  static const routeDiscoveryResponseType = 'route_discovery_response';

  MeshEnvelope({
    required this.messageId,
    required this.origin,
    required this.destination,
    required this.ttl,
    required this.type,
    this.payload = '',
    DateTime? timestamp,
    DateTime? expiresAt,
    this.hopCount = 0,
  })  : timestamp = timestamp ?? DateTime.now(),
        expiresAt = expiresAt ??
            (timestamp ?? DateTime.now()).add(const Duration(minutes: 30));

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

  /// Absolute expiry is separate from [ttl].  TTL limits relays; expiry
  /// limits lifetime even when a message is being retried after a delay.
  final DateTime expiresAt;

  /// Number of relays already traversed.  [ttl] remains the remaining
  /// budget for compatibility with the currently deployed direct path.
  final int hopCount;

  bool get isExpired => !expiresAt.isAfter(DateTime.now().toUtc());

  /// Returns a copy with [ttl] decremented — used when forwarding.
  MeshEnvelope decremented() => MeshEnvelope(
        messageId: messageId,
        origin: origin,
        destination: destination,
        ttl: ttl - 1,
        type: type,
        payload: payload,
        timestamp: timestamp,
        expiresAt: expiresAt,
        hopCount: hopCount + 1,
      );

  Map<String, dynamic> toJson() => {
        'messageId': messageId,
        'origin': origin,
        'destination': destination,
        'ttl': ttl,
        'type': type,
        'payload': payload,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'expiresAt': expiresAt.millisecondsSinceEpoch,
        'hopCount': hopCount,
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
    final expiresAtMs = json['expiresAt'];
    final hopCount = json['hopCount'];

    if (messageId is! String ||
        messageId.length > 128 ||
        messageId.isEmpty ||
        origin is! String ||
        origin.length > 128 ||
        origin.isEmpty ||
        destination is! String ||
        destination.length > 128 ||
        ttl is! int ||
        ttl < 0 ||
        ttl > 20 ||
        type is! String ||
        (type != chatType &&
            type != helloType &&
            type != routeDiscoveryType &&
            type != routeDiscoveryResponseType) ||
        payload is! String ||
        payload.length > 65536 ||
        timestampMs is! int ||
        (expiresAtMs != null && expiresAtMs is! int) ||
        (hopCount != null &&
            (hopCount is! int || hopCount < 0 || hopCount > 20))) {
      return null;
    }
    if ((type == helloType && (destination.isNotEmpty || ttl != 1)) ||
        (type != helloType && (destination.isEmpty || ttl < 1))) {
      return null;
    }

    final timestamp =
        DateTime.fromMillisecondsSinceEpoch(timestampMs, isUtc: true);
    // Older direct-chat peers did not send expiry or hop-count fields. Keep
    // accepting those packets while ensuring newly emitted packets are fully
    // bounded.
    final expiresAt = expiresAtMs is int
        ? DateTime.fromMillisecondsSinceEpoch(expiresAtMs, isUtc: true)
        : timestamp.add(const Duration(minutes: 30));
    if (!expiresAt.isAfter(timestamp)) return null;

    return MeshEnvelope(
      messageId: messageId,
      origin: origin,
      destination: destination,
      ttl: ttl,
      type: type,
      payload: payload,
      timestamp: timestamp,
      expiresAt: expiresAt,
      hopCount: hopCount is int ? hopCount : 0,
    );
  }
}
