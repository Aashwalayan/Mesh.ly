import '../models/contact.dart';
import '../models/message.dart';
import '../models/user.dart';

class MockData {
  MockData._();

  static const currentUserId = 'me';

  static const currentUser = User(
    username: 'Anish Sharma',
    meshId: 'MESH-ANISH-001',
  );

  static const contacts = <Contact>[
    Contact(
      id: 'c1',
      username: 'Aradhy',
      meshId: 'MESH-ARADHY-104',
      lastSeen: 'Active now',
    ),
    Contact(
      id: 'c2',
      username: 'Aashwalayan',
      meshId: 'MESH-AASHWALAYAN-228',
      lastSeen: '10 min ago',
    ),
    Contact(
      id: 'c3',
      username: 'Ankit',
      meshId: 'MESH-ANKIT-067',
      lastSeen: 'Yesterday',
    ),
    Contact(
      id: 'c4',
      username: 'Rohan',
      meshId: 'MESH-ROHAN-512',
      lastSeen: 'Monday',
    ),
  ];

  static const nearbyContacts = <Contact>[
    Contact(id: 'c1', username: 'Aradhy', meshId: 'MESH-ARADHY-104'),
    Contact(id: 'c2', username: 'Aashwalayan', meshId: 'MESH-AASHWALAYAN-228'),
    Contact(id: 'c3', username: 'Ankit', meshId: 'MESH-ANKIT-067'),
  ];

  static final List<Message> messages = [
    Message(
      id: 'm1',
      senderId: 'c1',
      receiverId: currentUserId,
      content: 'Mesh route found. Messages can sync when peers appear.',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      isRead: true,
    ),
    Message(
      id: 'm2',
      senderId: currentUserId,
      receiverId: 'c1',
      content: 'Nice, testing it out now.',
      timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 40)),
      isRead: true,
    ),
    Message(
      id: 'm3',
      senderId: 'c1',
      receiverId: currentUserId,
      content: 'I am on the move. Ping me when you are nearby.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 20)),
    ),
    Message(
      id: 'm4',
      senderId: 'c1',
      receiverId: currentUserId,
      content: 'Also, battery is at 40%, might drop off mesh soon.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 18)),
    ),
    Message(
      id: 'm5',
      senderId: 'c2',
      receiverId: currentUserId,
      content: 'Shared the offline meetup point.',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      isRead: true,
    ),
    Message(
      id: 'm6',
      senderId: currentUserId,
      receiverId: 'c2',
      content: 'Got it, see you there.',
      timestamp: DateTime.now().subtract(const Duration(hours: 4, minutes: 50)),
      isRead: true,
    ),
    Message(
      id: 'm7',
      senderId: 'c3',
      receiverId: currentUserId,
      content: 'Connection was stable near the station.',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
    ),
    Message(
      id: 'm8',
      senderId: 'c4',
      receiverId: currentUserId,
      content: 'Let us sync later tonight.',
      timestamp: DateTime.now().subtract(const Duration(days: 3)),
      isRead: true,
    ),
  ];

  /// Messages exchanged with a given contact, oldest first.
  static List<Message> messagesWith(String contactId) {
    final thread = messages
        .where((m) => m.senderId == contactId || m.receiverId == contactId)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return thread;
  }
}
