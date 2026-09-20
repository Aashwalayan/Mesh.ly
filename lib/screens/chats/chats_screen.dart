import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../data/contacts_repository.dart';
import '../../data/messages_repository.dart';
import '../../models/contact.dart';
import '../../models/message.dart';
import '../../widgets/chat_tile.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/mesh_search_field.dart';
import '../contacts/add_contact_screen.dart';
import 'chat_screen.dart';

/// The primary screen: search, recent conversations, and an entry point
/// into the add-contact flow.
///
/// Reads contacts from [ContactsRepository] and previews from
/// [MessagesRepository] (both wrapped in [ListenableBuilder]s), so a
/// contact added via QR/Nearby or a message arriving over the mesh shows
/// up here immediately — this screen stays mounted in the bottom-nav's
/// IndexedStack, so without those listeners it would keep showing stale
/// data after either changes elsewhere.
class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Contact> _filter(List<Contact> contacts) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return contacts;

    return contacts
        .where(
          (contact) =>
              contact.username.toLowerCase().contains(query) ||
              contact.meshId.toLowerCase().contains(query),
        )
        .toList();
  }

  bool _matchesQuery(String meshId, String? username) {
    final query = _query.trim().toLowerCase();
    return query.isEmpty ||
        meshId.toLowerCase().contains(query) ||
        (username?.toLowerCase().contains(query) ?? false);
  }

  /// Builds a "last message + unread count" preview for a contact from
  /// their real message thread, keyed by Mesh ID (see MessagesRepository).
  ({String preview, String time, int unread}) _previewFor(Contact contact) {
    final thread = MessagesRepository.instance.threadWith(contact.meshId);
    if (thread.isEmpty) {
      return (preview: 'Say hello 👋', time: '', unread: 0);
    }

    final last = thread.last;
    final unread = thread
        .where((m) => m.senderId == contact.meshId && !m.isRead)
        .length;

    return (preview: last.content, time: _formatTime(last), unread: unread);
  }

  String _formatTime(Message message) {
    final now = DateTime.now();
    final diff = now.difference(message.timestamp);

    if (diff.inDays >= 1) {
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return diff.inDays == 1 && now.day - message.timestamp.day == 1
          ? 'Yesterday'
          : weekdays[message.timestamp.weekday - 1];
    }

    final hour = message.timestamp.hour.toString().padLeft(2, '0');
    final minute = message.timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mesh.ly',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textHeading,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Offline-ready conversations',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.tonal(
                  onPressed: () => showAddContactSheet(context),
                  style: FilledButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(14),
                    backgroundColor: AppColors.accentSoft,
                    foregroundColor: AppColors.accentDark,
                  ),
                  child: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 18),
            MeshSearchField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListenableBuilder(
                listenable: Listenable.merge([
                  ContactsRepository.instance,
                  MessagesRepository.instance,
                ]),
                builder: (context, _) {
                  final allContacts = ContactsRepository.instance.contacts;
                  final contacts = _filter(allContacts);
                  final savedMeshIds = allContacts
                      .map((contact) => contact.meshId)
                      .toSet();
                  final unknownMeshIds = MessagesRepository.instance
                      .conversationMeshIds
                      .where((meshId) =>
                          !savedMeshIds.contains(meshId) &&
                          _matchesQuery(meshId, null))
                      .toList();

                  if (contacts.isEmpty && unknownMeshIds.isEmpty) {
                    return const EmptyState(
                      message: 'No contacts match your search.',
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.only(bottom: 20),
                    itemCount: contacts.length + unknownMeshIds.length,
                    separatorBuilder: (_, i) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final isUnknownPeer = index >= contacts.length;
                      final meshId = isUnknownPeer
                          ? unknownMeshIds[index - contacts.length]
                          : contacts[index].meshId;
                      final contact = isUnknownPeer ? null : contacts[index];
                      final preview = isUnknownPeer
                          ? _previewForMeshId(meshId)
                          : _previewFor(contact!);

                      return ChatTile(
                        name: isUnknownPeer ? meshId : contact!.username,
                        lastMessage: preview.preview,
                        time: preview.time,
                        unreadCount: preview.unread,
                        isUnknownPeer: isUnknownPeer,
                        isSelected: false,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              meshId: meshId,
                              contact: contact,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  ({String preview, String time, int unread}) _previewForMeshId(String meshId) {
    final thread = MessagesRepository.instance.threadWith(meshId);
    if (thread.isEmpty) return (preview: 'No messages yet', time: '', unread: 0);
    final last = thread.last;
    final unread = thread.where((message) => !message.isRead).length;
    return (preview: last.content, time: _formatTime(last), unread: unread);
  }
}
