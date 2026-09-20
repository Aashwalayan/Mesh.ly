import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../data/contacts_repository.dart';
import '../../data/identity_repository.dart';
import '../../models/contact.dart';
import '../../services/discovery_service.dart';
import '../../services/mesh_router.dart';
import '../../widgets/contact_tile.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/tab_chip.dart';

enum AddContactTab { myQr, scanQr, nearby }

/// The "Add someone" flow: share your own QR, scan a peer's QR, or connect
/// to someone nearby. My QR (qr_flutter) and Scan QR (mobile_scanner) are
/// real — scanning a valid Mesh.ly QR adds a Contact via
/// [ContactsRepository]. Nearby is wired to real Android Nearby Connections
/// discovery too (see lib/services/), though still being debugged as of
/// this writing.
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
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
    final user = IdentityRepository.instance.user!;

    // What the other phone's camera actually decodes. Kept as plain JSON —
    // human-readable if you print it while debugging, no external schema.
    // NOTE: this is still just a claimed identity, not a verified one —
    // there's no signing/crypto here, matching where the rest of the app
    // is at (see lib/services/README.md).
    final payload = jsonEncode({
      'username': user.username,
      'meshId': user.meshId,
    });

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
            child: QrImageView(
              data: payload,
              version: QrVersions.auto,
              size: 188,
              backgroundColor: Colors.white,
            ),
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

/// Real camera-based QR scanning. On a successful, well-formed scan, adds
/// the peer as a Contact (via [ContactsRepository]) and shows a
/// confirmation instead of immediately closing — so you can see what was
/// added before backing out.
class _ScanQrTab extends StatefulWidget {
  const _ScanQrTab();

  @override
  State<_ScanQrTab> createState() => _ScanQrTabState();
}

class _ScanQrTabState extends State<_ScanQrTab> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  Contact? _scannedContact;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDetect(BarcodeCapture capture) {
    if (_scannedContact != null) return; // already handled a scan

    final raw = capture.barcodes.isEmpty
        ? null
        : capture.barcodes.first.rawValue;
    if (raw == null) return;

    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final username = data['username'] as String?;
      final meshId = data['meshId'] as String?;
      if (username == null || username.isEmpty || meshId == null || meshId.isEmpty) {
        throw const FormatException('Missing username/meshId');
      }

      final contact = Contact(
        id: meshId,
        username: username,
        meshId: meshId,
        lastSeen: 'Added via QR',
      );
      ContactsRepository.instance.addOrUpdate(contact);
      _controller.stop();
      setState(() {
        _scannedContact = contact;
        _error = null;
      });
    } catch (_) {
      setState(() {
        _error = "That doesn't look like a Mesh.ly QR code.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_scannedContact != null) {
      final contact = _scannedContact!;
      return Center(
        key: const ValueKey('scan-qr-success'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.accent,
              size: 56,
            ),
            const SizedBox(height: 16),
            Text(
              '${contact.username} added',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              contact.meshId,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 220,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      key: const ValueKey('scan-qr-tab'),
      borderRadius: BorderRadius.circular(AppRadii.panel),
      child: SizedBox(
        width: double.infinity,
        height: 300,
        child: Stack(
          fit: StackFit.expand,
          children: [
            MobileScanner(
              controller: _controller,
              onDetect: _handleDetect,
              errorBuilder: (context, error) => const ColoredBox(
                color: AppColors.conversationTop,
                child: EmptyState(
                  icon: Icons.camera_alt_outlined,
                  message:
                      'Camera permission is needed to scan QR codes. Grant '
                      'it in system settings and reopen this tab.',
                ),
              ),
            ),
            Center(
              child: Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
            if (_error != null)
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NearbyTab extends StatelessWidget {
  const _NearbyTab();

  String _stateLabel(PeerConnectionState? state) {
    switch (state) {
      case PeerConnectionState.connecting:
        return 'Connecting';
      case PeerConnectionState.connected:
        return 'Connected';
      case PeerConnectionState.failed:
        return 'Failed';
      case PeerConnectionState.disconnected:
        return 'Disconnected';
      default:
        return 'Discovered';
    }
  }

  IconData _stateIcon(PeerConnectionState? state) {
    switch (state) {
      case PeerConnectionState.connected:
        return Icons.check_circle_rounded;
      case PeerConnectionState.connecting:
        return Icons.sync_rounded;
      case PeerConnectionState.failed:
        return Icons.error_outline_rounded;
      case PeerConnectionState.disconnected:
        return Icons.link_off_rounded;
      default:
        return Icons.devices_other_rounded;
    }
  }

  Color _stateColor(PeerConnectionState? state) {
    switch (state) {
      case PeerConnectionState.connected:
        return AppColors.accent;
      case PeerConnectionState.failed:
        return Colors.redAccent;
      case PeerConnectionState.connecting:
      case PeerConnectionState.disconnected:
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: MeshRouter.instance,
      builder: (context, _) {
        final router = MeshRouter.instance;
        final peers = router.peers;
        final peerStates = router.peerStates;

        if (peers.isEmpty) {
          return const EmptyState(
            icon: Icons.radar_rounded,
            message: 'No Mesh.ly devices nearby.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 20),
          itemCount: peers.length,
          separatorBuilder: (_, i) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final peer = peers.values.elementAt(index);
            final state = peerStates[peer.endpointId];

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.panel),
                border: Border.all(
                  color: AppColors.divider,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.accentSoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.devices_rounded,
                      color: AppColors.accentDark,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          peer.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              _stateIcon(state),
                              size: 16,
                              color: _stateColor(state),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _stateLabel(state),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: _stateColor(state),
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}