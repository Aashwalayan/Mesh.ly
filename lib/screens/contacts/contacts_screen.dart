import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../data/contacts_repository.dart';
import '../../models/contact.dart';
import '../../widgets/contact_tile.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/mesh_search_field.dart';
import 'add_contact_screen.dart';

/// Dedicated Contacts tab: search + full contact list + add-contact entry
/// point (as its own screen, separate from the quick-add sheet on Chats).
///
/// Reads from [ContactsRepository] (wrapped in a [ListenableBuilder]) rather
/// than the static mock list directly, so a contact added via the real Scan
/// QR flow appears here immediately — this screen stays mounted in the
/// bottom-nav's IndexedStack, so without that listener it would keep
/// showing a stale list after returning from Add Contact.
class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
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
                  child: Text(
                    'Contacts',
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textHeading,
                        ),
                  ),
                ),
                FilledButton.tonal(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AddContactScreen(),
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(14),
                    backgroundColor: AppColors.accentSoft,
                    foregroundColor: AppColors.accentDark,
                  ),
                  child: const Icon(Icons.person_add_alt_1_rounded),
                ),
              ],
            ),
            const SizedBox(height: 16),
            MeshSearchField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              hintText: 'Search contacts...',
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListenableBuilder(
                listenable: ContactsRepository.instance,
                builder: (context, _) {
                  final contacts = _filter(ContactsRepository.instance.contacts);

                  if (contacts.isEmpty) {
                    return const EmptyState(
                      message: 'No contacts match your search.',
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.only(bottom: 20),
                    itemCount: contacts.length,
                    separatorBuilder: (_, i) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final contact = contacts[index];
                      return ContactTile(
                        name: contact.username,
                        subtitle: contact.lastSeen ?? contact.meshId,
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
}