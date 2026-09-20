/// Local delivery state only. Mesh.ly does not implement end-to-end ACKs yet,
/// so [sent] means the message was handed to at least one connected neighbor,
/// not that its final recipient confirmed delivery.
enum MessageDeliveryState { sending, sent, received }

/// A single chat message.
///
/// This model also provides the minimal envelope used for direct Nearby
/// Connections test messages. Routing fields intentionally do not exist yet.
class Message {
  static const chatMessageType = 'chat_message';
  static const testMessageType = 'test_message';

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    this.isRead = false,
    this.type = chatMessageType,
    this.deliveryState = MessageDeliveryState.received,
  });

  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime timestamp;
  bool isRead;
  final String type;
  MessageDeliveryState deliveryState;

  Map<String, String> toTestEnvelope() => {
    'type': testMessageType,
    'id': id,
    'senderId': senderId,
    'text': content,
  };

  /// Returns null for unknown message types or malformed data.
  static Message? fromTestEnvelope(Map<String, dynamic> envelope) {
    final type = envelope['type'];
    final id = envelope['id'];
    final senderId = envelope['senderId'];
    final text = envelope['text'];
    if (type != testMessageType ||
        id is! String ||
        id.isEmpty ||
        senderId is! String ||
        senderId.isEmpty ||
        text is! String) {
      return null;
    }

    return Message(
      id: id,
      senderId: senderId,
      receiverId: '',
      content: text,
      timestamp: DateTime.now(),
      type: type,
    );
  }
}
