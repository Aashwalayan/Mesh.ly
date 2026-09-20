import 'dart:async';
import 'dart:typed_data';

import '../data/mock_data.dart';
import '../models/message.dart';
import 'discovery_service.dart';

/// Frontend-only stand-in for [DiscoveryService]. Emits the existing mock
/// nearby contacts after a short delay so the Nearby tab has something to
/// show without any real Bluetooth/Wi-Fi involved. This is what the app
/// used before real discovery existed, and stays available as a fallback
/// (see [ServiceLocator]) in case the real one misbehaves during a demo.
class MockDiscoveryService implements DiscoveryService {
  final _peerFoundController = StreamController<DiscoveredPeer>.broadcast();
  final _peerLostController = StreamController<String>.broadcast();
  final _connectionStateController =
      StreamController<(String, PeerConnectionState)>.broadcast();
  final _payloadController =
      StreamController<(String, Uint8List)>.broadcast();
  final _messageController =
      StreamController<(String, Message)>.broadcast();

  Timer? _emitTimer;

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
    _emitTimer = Timer(const Duration(milliseconds: 600), () {
      for (final contact in MockData.nearbyContacts) {
        _peerFoundController.add(
          DiscoveredPeer(endpointId: contact.id, name: contact.username),
        );
      }
    });
  }

  @override
  Future<void> stop() async {
    _emitTimer?.cancel();
  }

  @override
  Future<void> connectTo(String endpointId) async {
    _connectionStateController.add((
      endpointId,
      PeerConnectionState.connecting,
    ));
    await Future.delayed(const Duration(milliseconds: 400));
    _connectionStateController.add((
      endpointId,
      PeerConnectionState.connected,
    ));
  }

  @override
  Future<void> disconnect(String endpointId) async {
    _connectionStateController.add((
      endpointId,
      PeerConnectionState.disconnected,
    ));
  }

  @override
  Future<void> sendBytes(String endpointId, Uint8List bytes) async {
    // No-op: nothing is really listening on the other end.
  }

  @override
  Future<void> sendTestMessage(
    String endpointId, {
    required String senderId,
    String text = 'Hello from Mesh.ly',
  }) async {
    // Keep mock mode transport-free; use the real Nearby service for this.
  }

  @override
  void dispose() {
    _emitTimer?.cancel();
    _peerFoundController.close();
    _peerLostController.close();
    _connectionStateController.close();
    _payloadController.close();
    _messageController.close();
  }
}
