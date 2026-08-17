import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../data/mock_data.dart';
import '../../models/contact.dart';
import '../../models/message.dart';
import '../../widgets/chat_tile.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/mesh_search_field.dart';
import '../contacts/add_contact_screen.dart';
import 'chat_screen.dart';

/// The primary screen: search, recent conversations, and an entry point
/// into the add-contact flow.
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

  List<Contact> get _filteredContacts {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return MockData.contacts;

    return MockData.contacts
        .where(
          (contact) =>
              contact.username.toLowerCase().contains(query) ||
              contact.meshId.toLowerCase().contains(query),
        )
        .toList();
  }

  /// Builds a "last message + unread count" preview for a contact from the
  /// mock message thread. Once real messaging exists this is where a
  /// message-store lookup would go instead.
  ({String preview, String time, int unread}) _previewFor(Contact contact) {
    final thread = MockData.messagesWith(contact.id);
    if (thread.isEmpty) {
      return (preview: 'Say hello 👋', time: '', unread: 0);
    }

    final last = thread.last;
    final unread = thread
        .where((m) => m.senderId == contact.id && !m.isRead)
        .length;

    return (preview: last.content, time: _formatTime(last), unread: unread);
  }

  String _formatTime(Message message) {
    final now = DateTime.now();
    final diff = now.difference(message.timestamp);

    if (diff.inDays >= 1) {
      const weekdays = [
        'Mon',
        'Tue',
        'Wed',
        'Thu',
        'Fri',
        'Sat',
        'Sun',
      ];
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
    final contacts = _filteredContacts;

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
              child: contacts.isEmpty
                  ? const EmptyState(message: 'No contacts match your search.')
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: 20),
                      itemCount: contacts.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final contact = contacts[index];
                        final preview = _previewFor(contact);

                        return ChatTile(
                          name: contact.username,
                          lastMessage: preview.preview,
                          time: preview.time,
                          unreadCount: preview.unread,
                          isSelected: false,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(contact: contact),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
