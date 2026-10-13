import 'package:flutter/foundation.dart';

import '../models/message.dart';

/// In-memory, session-only chat threads, keyed by the OTHER party's Mesh
/// ID. Replaces the old MockData.messagesWith() now that messages actually
/// travel over the mesh (see [MeshRouter]) instead of being seeded data.
///
/// Like [ContactsRepository], nothing here persists across app restarts
/// yet — a natural next step once this is proven out.
class MessagesRepository extends ChangeNotifier {
  MessagesRepository._();

  static final MessagesRepository instance = MessagesRepository._();

  final Map<String, List<Message>> _threads = {};

  /// Returns a conversation in chronological order, even if packets arrived
  /// out of order after reconnecting through the mesh.
  List<Message> threadWith(String meshId) {
    final thread = List<Message>.of(_threads[meshId] ?? const []);
    thread.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return List.unmodifiable(thread);
  }

  /// Mesh IDs with messages, including peers the user has not saved as a
  /// contact. The repository is the inbox; Contacts remain an address book.
  List<String> get conversationMeshIds => List.unmodifiable(_threads.keys);

  /// Conversations with the most recently active one first. Contacts without
  /// a real message are deliberately absent: the Chats tab is a history of
  /// conversations, while the Contacts tab is where a new conversation
  /// begins.
  List<String> get conversationMeshIdsByRecency {
    final meshIds = _threads.keys.toList();
    meshIds.sort((a, b) {
      final latestA = _latestTimestamp(a);
      final latestB = _latestTimestamp(b);
      final byTime = latestB.compareTo(latestA);
      return byTime != 0 ? byTime : a.compareTo(b);
    });
    return List.unmodifiable(meshIds);
  }

  DateTime _latestTimestamp(String meshId) => _threads[meshId]!
      .map((message) => message.timestamp)
      .reduce((latest, timestamp) =>
          timestamp.isAfter(latest) ? timestamp : latest);

  void _append(String meshId, Message message) {
    _threads.putIfAbsent(meshId, () => []).add(message);
    notifyListeners();
  }

  /// Records a message this device just sent to [recipientMeshId].
  void recordOutgoing(String recipientMeshId, Message message) {
    _append(recipientMeshId, message);
  }

  /// Records a message that arrived FOR this device, originally sent by
  /// [senderMeshId] (who may not be whoever it was physically received
  /// from — it could have been relayed).
  void recordIncoming(String senderMeshId, Message message) {
    _append(senderMeshId, message);
  }

  void markOutgoingSent(String messageId) {
    for (final thread in _threads.values) {
      for (final message in thread) {
        if (message.id == messageId &&
            message.deliveryState == MessageDeliveryState.sending) {
          message.deliveryState = MessageDeliveryState.sent;
          notifyListeners();
          return;
        }
      }
    }
  }

  /// Opening a conversation acknowledges all messages already visible in it.
  void markThreadRead(String meshId) {
    final thread = _threads[meshId];
    if (thread == null) return;

    var changed = false;
    for (final message in thread) {
      if (!message.isRead) {
        message.isRead = true;
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }
}
