import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../data/mock_data.dart';
import '../../services/discovery_service.dart';
import '../../services/permissions_service.dart';
import '../../services/service_locator.dart';
import '../../widgets/contact_tile.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/qr_placeholder.dart';
import '../../widgets/tab_chip.dart';

enum AddContactTab { myQr, scanQr, nearby }

/// The "Add someone" flow: share your own QR, scan a peer's QR, or connect
/// to someone nearby. My QR and Scan QR are still frontend-only placeholders;
/// Nearby is wired to real Android Nearby Connections discovery (see
/// lib/services/) as of the mesh-networking work.
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
