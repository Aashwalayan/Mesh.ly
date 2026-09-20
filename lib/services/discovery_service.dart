import 'dart:typed_data';

import '../models/message.dart';

/// A peer visible nearby, before or after a connection is established.
class DiscoveredPeer {
  const DiscoveredPeer({required this.endpointId, required this.name});

  /// Session-scoped ID assigned by the transport (BLE/Wi-Fi session), used
  /// to request/accept connections and address messages.
  ///
  /// This is NOT the peer's Mesh ID — it isn't stable across sessions and
  /// says nothing about identity. Real Mesh ID verification (QR-based or
  /// otherwise) is a separate, not-yet-built piece.
  final String endpointId;
  final String name;
}

/// Coarse connection lifecycle state for a given [DiscoveredPeer.endpointId].
///
/// Kept deliberately simple for now: the underlying `nearby_connections`
/// plugin's `Status` enum has more detail (e.g. distinguishing a rejected
/// request from a radio/permission error), but its exact member names
/// aren't documented anywhere we could verify, so [NearbyDiscoveryService]
/// collapses anything that isn't a successful connect into [failed] rather
/// than guess at names that might not compile.
enum PeerConnectionState { connecting, connected, failed, disconnected }

/// Abstraction over "find nearby devices, connect to one, exchange bytes."
///
/// [MockDiscoveryService] backs the UI during frontend-only development.
/// [NearbyDiscoveryService] is the real Android implementation, built on
/// Google's Nearby Connections API — it advertises/discovers over BLE and
/// the plugin auto-upgrades the actual data channel to Wi-Fi once two
/// devices connect. Screens depend only on this interface, never on a
/// specific implementation, so swapping one for the other is a one-line
/// change in [ServiceLocator].
abstract class DiscoveryService {
  Stream<DiscoveredPeer> get onPeerFound;

  /// Emits the endpointId of a peer that's no longer visible.
  Stream<String> get onPeerLost;

  /// Emits whenever a connection's state changes for a given endpointId.
  Stream<(String endpointId, PeerConnectionState state)>
  get onConnectionStateChanged;

  /// Emits bytes received on an established connection. Not yet wired into
  /// the Chat screen — that's the next piece to build on top of this.
  Stream<(String endpointId, Uint8List bytes)> get onPayloadReceived;

  /// Emits validated direct-peer messages. Implementations discard invalid
  /// payloads instead of allowing them to crash the app.
  Stream<(String endpointId, Message message)> get onMessageReceived;

  /// Starts advertising this device AND discovering others at once, using
  /// [myDisplayName] as the name other devices will see.
  Future<void> start(String myDisplayName);

  /// Stops advertising/discovery. Does not disconnect already-connected
  /// peers.
  Future<void> stop();

  /// Requests a connection to a discovered peer.
  Future<void> connectTo(String endpointId);

  Future<void> disconnect(String endpointId);

  Future<void> sendBytes(String endpointId, Uint8List bytes);

  /// Sends one message only to the specified immediately connected peer.
  Future<void> sendTestMessage(
    String endpointId, {
    required String senderId,
    String text = 'Hello from Mesh.ly',
  });

  /// Releases resources (stream controllers, active endpoints). Call when
  /// the owning screen is disposed.
  void dispose();
}
