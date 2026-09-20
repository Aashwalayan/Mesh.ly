import '../models/contact.dart';
import '../models/message.dart';

/// What's left of the original mock data now that real identity (see
/// IdentityRepository) and real contact-adding (QR/Nearby) exist: just the
/// "me" sentinel used to tag locally-sent messages as your own, plus empty
/// seed lists so a fresh install starts with zero contacts and zero chats
/// — only people actually added via QR or Nearby ever show up.
class MockData {
  MockData._();

  static const currentUserId = 'me';

  static const contacts = <Contact>[];

  static const nearbyContacts = <Contact>[];

  static final List<Message> messages = <Message>[];

  /// Messages exchanged with a given contact, oldest first. Always empty
  /// now — kept as a method (not inlined at call sites) so chat_screen.dart
  /// and chats_screen.dart don't need to change if real message
  /// persistence gets added here later.
  static List<Message> messagesWith(String contactId) {
    return messages
        .where((m) => m.senderId == contactId || m.receiverId == contactId)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }
}