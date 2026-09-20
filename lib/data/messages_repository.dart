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

  List<Message> threadWith(String meshId) =>
      List.unmodifiable(_threads[meshId] ?? const []);

  /// Mesh IDs with messages, including peers the user has not saved as a
  /// contact. The repository is the inbox; Contacts remain an address book.
  List<String> get conversationMeshIds => List.unmodifiable(_threads.keys);

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
}
