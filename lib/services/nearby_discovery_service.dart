import 'dart:async';
import 'dart:typed_data';

import 'package:nearby_connections/nearby_connections.dart';

import 'discovery_service.dart';

/// Real Android implementation of [DiscoveryService], built directly on
/// Google's Nearby Connections API via the `nearby_connections` plugin
/// (https://pub.dev/packages/nearby_connections).
///
/// Uses [Strategy.P2P_CLUSTER] so every device can simultaneously advertise
/// AND discover — the closest fit to "a mesh of peers" rather than a fixed
/// client/host pair. The plugin picks the underlying radio itself (BLE for
/// discovery, upgrading to Wi-Fi for the actual data channel) — this class
/// never touches Bluetooth/Wi-Fi APIs directly, and per a July 2026 Android
/// Developers Blog post, that auto-upgrade will stop auto-enabling radios
/// for the user starting "late 2026" — so for now, Bluetooth and Wi-Fi
/// need to be switched on by hand on both test phones (see
/// [PermissionsService]'s doc comment for more on this).
///
/// Design choices worth knowing about, since they're simplifications made
/// to fit this into Day 1's scope rather than gaps in understanding:
/// - Connections are auto-accepted on both sides (no incoming-request UI
///   yet). The official example shows a proper accept/reject sheet; this
///   skips that for now.
/// - [PeerConnectionState] collapses "rejected" and "error" into [failed]
///   — see that enum's doc comment for why.
class NearbyDiscoveryService implements DiscoveryService {
  NearbyDiscoveryService({required this.serviceId});

  /// Uniquely identifies this app to other Mesh.ly installs. Must match on
  /// both the advertiser and the discoverer to see each other.
  final String serviceId;

  static const _strategy = Strategy.P2P_CLUSTER;

  String _myDisplayName = 'Mesh.ly user';

  final _peerFoundController = StreamController<DiscoveredPeer>.broadcast();
  final _peerLostController = StreamController<String>.broadcast();
  final _connectionStateController =
      StreamController<(String, PeerConnectionState)>.broadcast();
  final _payloadController = StreamController<(String, Uint8List)>.broadcast();

  @override
  Stream<DiscoveredPeer> get onPeerFound => _peerFoundController.stream;

  @override
  Stream<String> get onPeerLost => _peerLostController.stream;

  @override
  Stream<(String, PeerConnectionState)> get onConnectionStateChanged =>
      _connectionStateController.stream;

  @override
  Stream<(String, Uint8List)> get onPayloadReceived =>
      _payloadController.stream;

  @override
  Future<void> start(String myDisplayName) async {
    _myDisplayName = myDisplayName;
    // ignore: avoid_print
    print(
      'NearbyDiscoveryService: starting P2P_CLUSTER '
      '(name=$myDisplayName, serviceId=$serviceId)',
    );

    try {
      final advertisingStarted = await Nearby().startAdvertising(
        myDisplayName,
        _strategy,
        serviceId: serviceId,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
      );
      // `nearby_connections` 4.3.0 reports a native failure as `false`,
      // rather than necessarily throwing a PlatformException.
      if (!advertisingStarted) {
        throw StateError('Nearby advertising returned false');
      }
      // ignore: avoid_print
      print('NearbyDiscoveryService: advertising started');

      final discoveryStarted = await Nearby().startDiscovery(
        myDisplayName,
        _strategy,
        serviceId: serviceId,
        onEndpointFound: (id, name, foundServiceId) {
          // ignore: avoid_print
          print(
            'NearbyDiscoveryService: endpoint found '
            '(id=$id, name=$name, serviceId=$foundServiceId)',
          );
          _peerFoundController.add(DiscoveredPeer(endpointId: id, name: name));
        },
        onEndpointLost: (id) {
          // ignore: avoid_print
          print('NearbyDiscoveryService: endpoint lost (id=$id)');
          if (id != null) _peerLostController.add(id);
        },
      );
      if (!discoveryStarted) {
        throw StateError('Nearby discovery returned false');
      }
      // ignore: avoid_print
      print('NearbyDiscoveryService: discovery started');
    } catch (error, stackTrace) {
      // Surface this instead of failing silently — e.g. "unable to start
      // bluetooth" or "insufficient permissions" per the plugin's own docs.
      // ignore: avoid_print
      print('NearbyDiscoveryService.start failed: $error\n$stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> stop() async {
    await Nearby().stopAdvertising();
    await Nearby().stopDiscovery();
  }

  @override
  Future<void> connectTo(String endpointId) async {
    _connectionStateController.add((
      endpointId,
      PeerConnectionState.connecting,
    ));
    try {
      await Nearby().requestConnection(
        _myDisplayName,
        endpointId,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
      );
    } catch (_) {
      _connectionStateController.add((endpointId, PeerConnectionState.failed));
    }
  }

  void _onConnectionInitiated(String id, ConnectionInfo info) {
    // ignore: avoid_print
    print('NearbyDiscoveryService: connection initiated (id=$id)');
    // Auto-accept: there's no incoming-request UI yet (see class doc).
    Nearby().acceptConnection(
      id,
      onPayLoadRecieved: (endpointId, payload) {
        if (payload.bytes != null) {
          _payloadController.add((endpointId, payload.bytes!));
        }
      },
      onPayloadTransferUpdate: (endpointId, update) {
        // Not surfaced yet — a per-message progress indicator can hook in
        // here once file/large payloads matter.
      },
    );
  }

  void _onConnectionResult(String id, Status status) {
    // ignore: avoid_print
    print('NearbyDiscoveryService: connection result (id=$id, status=$status)');
    // We can only confirm Status.ERROR's exact name from the plugin's
    // source; treat anything else as success rather than guess at other
    // member names (e.g. a rejection) that might not compile.
    final state = status == Status.ERROR
        ? PeerConnectionState.failed
        : PeerConnectionState.connected;
    _connectionStateController.add((id, state));
  }

  void _onDisconnected(String id) {
    // ignore: avoid_print
    print('NearbyDiscoveryService: disconnected (id=$id)');
    _connectionStateController.add((id, PeerConnectionState.disconnected));
  }

  @override
  Future<void> disconnect(String endpointId) async {
    await Nearby().disconnectFromEndpoint(endpointId);
  }

  @override
  Future<void> sendBytes(String endpointId, Uint8List bytes) async {
    await Nearby().sendBytesPayload(endpointId, bytes);
  }

  @override
  void dispose() {
    Nearby().stopAllEndpoints();
    _peerFoundController.close();
    _peerLostController.close();
    _connectionStateController.close();
    _payloadController.close();
  }
}
