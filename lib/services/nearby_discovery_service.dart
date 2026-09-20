import 'dart:async';
import 'dart:typed_data';

import 'package:nearby_connections/nearby_connections.dart';

import '../models/message.dart';
import 'discovery_service.dart';
import 'mesh_message_codec.dart';

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
  final _messageController =
      StreamController<(String, Message)>.broadcast();

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
  Stream<(String, Message)> get onMessageReceived => _messageController.stream;

  @override
  Future<void> start(String myDisplayName) async {
    _myDisplayName = myDisplayName;
    // ignore: avoid_print
    print(
      '[Mesh/diag] Starting P2P_CLUSTER '
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
      print('[Mesh/diag] Advertising started successfully');

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
      print('[Mesh/diag] Discovery started successfully');
    } catch (error, stackTrace) {
      // Surface this instead of failing silently — e.g. "unable to start
      // bluetooth" or "insufficient permissions" per the plugin's own docs.
      // ignore: avoid_print
      print('[Mesh/diag] Nearby start failed: $error\n$stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> stop() async {
    // ignore: avoid_print
    print('[Mesh/diag] Stopping advertising and discovery');
    await Nearby().stopAdvertising();
    await Nearby().stopDiscovery();
  }

  @override
  Future<void> connectTo(String endpointId) async {
    // ignore: avoid_print
    print('[Mesh/diag] Requesting connection to $endpointId');
    _connectionStateController.add((
      endpointId,
      PeerConnectionState.connecting,
    ));
    try {
      final requested = await Nearby().requestConnection(
        _myDisplayName,
        endpointId,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
      );
      // ignore: avoid_print
      print('[Mesh/diag] Connection request to $endpointId accepted=$requested');
      if (!requested) {
        _connectionStateController.add((endpointId, PeerConnectionState.failed));
      }
    } catch (error, stackTrace) {
      // ignore: avoid_print
      print('[Mesh/diag] Connection request to $endpointId failed: '
          '$error\n$stackTrace');
      _connectionStateController.add((endpointId, PeerConnectionState.failed));
    }
  }

  void _onConnectionInitiated(String id, ConnectionInfo info) {
    // ignore: avoid_print
    print('[Mesh/diag] Connection initiated (id=$id, '
        'name=${info.endpointName}, incoming=${info.isIncomingConnection}, '
        'token=${info.authenticationToken})');
    // Auto-accept: there's no incoming-request UI yet (see class doc).
    Nearby().acceptConnection(
      id,
      onPayLoadRecieved: (endpointId, payload) {
        if (payload.bytes != null) {
          final bytes = payload.bytes!;
          _payloadController.add((endpointId, bytes));
          _handleReceivedPayload(endpointId, bytes);
        }
      },
      onPayloadTransferUpdate: (endpointId, update) {
        // Not surfaced yet — a per-message progress indicator can hook in
        // here once file/large payloads matter.
      },
    ).then((accepted) {
      // ignore: avoid_print
      print('[Mesh/diag] acceptConnection($id) accepted=$accepted');
    }).catchError((Object error, StackTrace stackTrace) {
      // ignore: avoid_print
      print('[Mesh/diag] acceptConnection($id) failed: $error\n$stackTrace');
      _connectionStateController.add((id, PeerConnectionState.failed));
    });
  }

  void _onConnectionResult(String id, Status status) {
    // ignore: avoid_print
    print('NearbyDiscoveryService: connection result (id=$id, status=$status)');
    final state = status == Status.CONNECTED
        ? PeerConnectionState.connected
        : PeerConnectionState.failed;
    // ignore: avoid_print
    print('[Mesh/diag] Connection result for $id: status=$status, state=$state');
    _connectionStateController.add((id, state));
    if (state == PeerConnectionState.connected) {
      // ignore: avoid_print
      print('[Mesh] Connected to $id');
    }
  }

  void _onDisconnected(String id) {
    // ignore: avoid_print
    print('[Mesh/diag] Disconnected from $id');
    _connectionStateController.add((id, PeerConnectionState.disconnected));
  }

  @override
  Future<void> disconnect(String endpointId) async {
    await Nearby().disconnectFromEndpoint(endpointId);
  }

  @override
  Future<void> sendBytes(String endpointId, Uint8List bytes) async {
    // ignore: avoid_print
    print('[Mesh/diag] Sending ${bytes.length} bytes to $endpointId');
    await Nearby().sendBytesPayload(endpointId, bytes);
  }

  @override
  Future<void> sendTestMessage(
    String endpointId, {
    required String senderId,
    String text = 'Hello from Mesh.ly',
  }) async {
    final message = Message(
      id: 'test-${DateTime.now().microsecondsSinceEpoch}',
      senderId: senderId,
      receiverId: endpointId,
      content: text,
      timestamp: DateTime.now(),
      type: Message.testMessageType,
    );
    // ignore: avoid_print
    print('[Mesh] Sending message ${message.id}');
    await sendBytes(endpointId, MeshMessageCodec.encodeTestMessage(message));
  }

  void _handleReceivedPayload(String endpointId, Uint8List bytes) {
    // ignore: avoid_print
    print('[Mesh/diag] Received ${bytes.length} raw bytes from $endpointId');
    final message = MeshMessageCodec.tryDecodeTestMessage(bytes);
    if (message == null) {
      // ignore: avoid_print
      print('[Mesh] Ignored malformed payload from $endpointId');
      return;
    }
    // ignore: avoid_print
    print('[Mesh] Received message ${message.id} from $endpointId');
    _messageController.add((endpointId, message));
  }

  @override
  void dispose() {
    Nearby().stopAllEndpoints();
    _peerFoundController.close();
    _peerLostController.close();
    _connectionStateController.close();
    _payloadController.close();
    _messageController.close();
  }
}
