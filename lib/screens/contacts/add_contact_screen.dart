import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../data/mock_data.dart';
import '../../widgets/contact_tile.dart';
import '../../widgets/qr_placeholder.dart';
import '../../widgets/tab_chip.dart';

enum AddContactTab { myQr, scanQr, nearby }

/// The "Add someone" flow: share your own QR, scan a peer's QR, or pick
/// from nearby mesh users. All three tabs are mock/frontend-only for now —
/// this is where the real QR + peer-discovery services will plug in later.
///
/// Used both as a full [Scaffold] screen (pushed from Contacts) and as the
/// body of a modal bottom sheet (opened from Chats) via [showAddContactSheet].
class AddContactScreen extends StatelessWidget {
  const AddContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add someone')),
      body: const Padding(
        padding: EdgeInsets.all(20),
        child: AddContactContent(),
      ),
    );
  }
}

/// Opens the add-contact flow as a bottom sheet (used from the Chats screen).
Future<void> showAddContactSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => SafeArea(
      top: false,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.82,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.sheet),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            children: [
              Container(
                width: 52,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Text(
                    'Add someone',
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Expanded(child: AddContactContent()),
            ],
          ),
        ),
      ),
    ),
  );
}

/// The tab switcher + tab body, shared by the screen and the sheet.
class AddContactContent extends StatefulWidget {
  const AddContactContent({super.key});

  @override
  State<AddContactContent> createState() => _AddContactContentState();
}

class _AddContactContentState extends State<AddContactContent> {
  AddContactTab _activeTab = AddContactTab.myQr;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TabChip(
                label: 'My QR',
                isSelected: _activeTab == AddContactTab.myQr,
                onTap: () => setState(() => _activeTab = AddContactTab.myQr),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TabChip(
                label: 'Scan QR',
                isSelected: _activeTab == AddContactTab.scanQr,
                onTap: () => setState(() => _activeTab = AddContactTab.scanQr),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TabChip(
                label: 'Nearby',
                isSelected: _activeTab == AddContactTab.nearby,
                onTap: () => setState(() => _activeTab = AddContactTab.nearby),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: switch (_activeTab) {
              AddContactTab.myQr => const _MyQrTab(),
              AddContactTab.scanQr => const _ScanQrTab(),
              AddContactTab.nearby => const _NearbyTab(),
            },
          ),
        ),
      ],
    );
  }
}

class _MyQrTab extends StatelessWidget {
  const _MyQrTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = MockData.currentUser;

    return SingleChildScrollView(
      key: const ValueKey('my-qr-tab'),
      child: Column(
        children: [
          Container(
            width: 220,
            height: 220,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadii.panel),
              border: Border.all(color: AppColors.divider),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: const QrPlaceholder(),
          ),
          const SizedBox(height: 18),
          Text(
            user.username,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mesh ID: ${user.meshId}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              // TODO: wire up to a real clipboard/share service later.
              onPressed: () {},
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Copy Mesh ID'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanQrTab extends StatelessWidget {
  const _ScanQrTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      key: const ValueKey('scan-qr-tab'),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.panel),
              gradient: const LinearGradient(
                colors: [AppColors.conversationTop, Color(0xFF204C46)],
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
                Positioned(
                  top: 54,
                  child: Text(
                    'QR scanning preview',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 44,
                  child: Text(
                    'Camera placeholder only',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            // TODO: plug in a real camera/QR scanning package later.
            child: FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.videocam_outlined),
              label: const Text('Open Camera'),
            ),
          ),
        ],
      ),
    );
  }
}

class _NearbyTab extends StatefulWidget {
  const _NearbyTab();

  @override
  State<_NearbyTab> createState() => _NearbyTabState();
}

class _NearbyTabState extends State<_NearbyTab> {
  final Set<String> _addedMeshIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final nearbyUsers = MockData.nearbyContacts;

    return ListView.separated(
      key: const ValueKey('nearby-tab'),
      itemCount: nearbyUsers.length,
      separatorBuilder: (_, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final user = nearbyUsers[index];
        final isAdded = _addedMeshIds.contains(user.meshId);

        return ContactTile(
          name: user.username,
          subtitle: 'Nearby',
          trailing: FilledButton.tonal(
            onPressed: isAdded
                ? null
                : () => setState(() => _addedMeshIds.add(user.meshId)),
            style: FilledButton.styleFrom(
              backgroundColor: isAdded
                  ? const Color(0xFFE7EFED)
                  : AppColors.accentSoft,
              foregroundColor: isAdded
                  ? AppColors.textFaded
                  : AppColors.accentDark,
            ),
            child: Text(isAdded ? 'Added' : 'Add'),
          ),
        );
      },
    );
  }
}
