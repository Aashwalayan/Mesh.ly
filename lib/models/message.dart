/// A single chat message.
///
/// Frontend-only: there is no networking behind this yet. Sending a message
/// just appends a new [Message] to local state (see ChatScreen).
class Message {
  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    this.isRead = false,
  });

  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime timestamp;
  bool isRead;
}
