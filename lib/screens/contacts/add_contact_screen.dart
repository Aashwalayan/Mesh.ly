import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../data/contacts_repository.dart';
import '../../data/mock_data.dart';
import '../../models/contact.dart';
import '../../services/discovery_service.dart';
import '../../services/permissions_service.dart';
import '../../services/service_locator.dart';
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
    final user = MockData.currentUser;

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

/// Real-device state for a peer shown in the list: found, connecting,
/// connected, or failed. Distinct from [MockData]'s old "added" concept —
/// this now reflects an actual Nearby Connections session, not a local set.
enum _PeerRowState { found, connecting, connected, failed }

class _NearbyTab extends StatefulWidget {
  const _NearbyTab();

  @override
  State<_NearbyTab> createState() => _NearbyTabState();
}

class _NearbyTabState extends State<_NearbyTab> {
  late final DiscoveryService _discovery;

  final Map<String, DiscoveredPeer> _peers = {};
  final Map<String, _PeerRowState> _peerStates = {};

  bool _permissionsGranted = false;
  bool _checkingPermissions = true;

  @override
  void initState() {
    super.initState();
    _discovery = createDiscoveryService();
    _discovery.onPeerFound.listen((peer) {
      // ignore: avoid_print
      print(
          'NearbyTab: stream received peer (id=${peer.endpointId}, name=${peer.name})');
      if (!mounted) return;
      setState(() {
        _peers[peer.endpointId] = peer;
        _peerStates.putIfAbsent(peer.endpointId, () => _PeerRowState.found);
      });
    });
    _discovery.onPeerLost.listen((endpointId) {
      if (!mounted) return;
      setState(() {
        _peers.remove(endpointId);
        _peerStates.remove(endpointId);
      });
    });
    _discovery.onConnectionStateChanged.listen((event) {
      if (!mounted) return;
      final (endpointId, state) = event;
      setState(() {
        _peerStates[endpointId] = switch (state) {
          PeerConnectionState.connecting => _PeerRowState.connecting,
          PeerConnectionState.connected => _PeerRowState.connected,
          PeerConnectionState.failed => _PeerRowState.failed,
          PeerConnectionState.disconnected => _PeerRowState.found,
        };
      });
    });
    _startDiscovery();
  }

  Future<void> _startDiscovery() async {
    final granted = await PermissionsService.requestAll();
    // ignore: avoid_print
    print('NearbyTab: permissions granted=$granted');
    if (!mounted) return;
    setState(() {
      _permissionsGranted = granted;
      _checkingPermissions = false;
    });
    if (granted) {
      try {
        await _discovery.start(MockData.currentUser.username);
      } catch (error, stackTrace) {
        // ignore: avoid_print
        print('NearbyTab: discovery failed: $error\n$stackTrace');
      }
    }
  }

  @override
  void dispose() {
    _discovery.stop();
    _discovery.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingPermissions) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_permissionsGranted) {
      return const EmptyState(
        icon: Icons.bluetooth_disabled_rounded,
        message: 'Bluetooth and location/nearby-device permissions are needed '
            'to find people nearby. Grant them in system settings and '
            'reopen this tab.',
      );
    }

    final nearbyPeers = _peers.values.toList();

    if (nearbyPeers.isEmpty) {
      return const EmptyState(
        icon: Icons.wifi_tethering_rounded,
        message: 'Looking for nearby Mesh.ly devices...\n'
            'Make sure Bluetooth and Wi-Fi are both turned on.',
      );
    }

    return ListView.separated(
      key: const ValueKey('nearby-tab'),
      itemCount: nearbyPeers.length,
      separatorBuilder: (_, i) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final peer = nearbyPeers[index];
        final state = _peerStates[peer.endpointId] ?? _PeerRowState.found;

        return ContactTile(
          name: peer.name,
          subtitle: switch (state) {
            _PeerRowState.found => 'Nearby',
            _PeerRowState.connecting => 'Connecting...',
            _PeerRowState.connected => 'Connected',
            _PeerRowState.failed => 'Connection failed — tap to retry',
          },
          trailing: FilledButton.tonal(
            onPressed: state == _PeerRowState.connected
                ? null
                : () => _discovery.connectTo(peer.endpointId),
            style: FilledButton.styleFrom(
              backgroundColor: state == _PeerRowState.connected
                  ? const Color(0xFFE7EFED)
                  : AppColors.accentSoft,
              foregroundColor: state == _PeerRowState.connected
                  ? AppColors.textFaded
                  : AppColors.accentDark,
            ),
            child: Text(switch (state) {
              _PeerRowState.found => 'Add',
              _PeerRowState.connecting => 'Connecting',
              _PeerRowState.connected => 'Connected',
              _PeerRowState.failed => 'Retry',
            }),
          ),
        );
      },
    );
  }
}