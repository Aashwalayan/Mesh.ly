import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/identity_repository.dart';
import '../data/messages_repository.dart';
import '../models/mesh_envelope.dart';
import '../models/message.dart';
import 'discovery_service.dart';
import 'mesh_envelope_codec.dart';
import 'permissions_service.dart';
import 'service_locator.dart';

/// The app-level mesh protocol, sitting above [DiscoveryService] per the
/// project's architecture doc (Section 17):
///
///   Nearby Connections → DiscoveryService → Mesh Transport →
///   Mesh Message Protocol → Forwarding/Routing → Chat UI
///
/// This is that "Mesh Transport + Protocol + Forwarding" middle section.
/// [DiscoveryService] only knows about bytes and endpoints; this class is
/// the first thing that knows what a message actually IS.
///
/// Owns ONE [DiscoveryService] for the whole app session — started once,
/// from [AppStartupGate], not per-screen. Screens (like the Nearby tab)
/// read this class's state instead of creating their own discovery
/// instance, so the mesh keeps running regardless of which screen is
/// visible.
///
/// Implements Stage 2 of the architecture doc: direct + multi-hop
/// forwarding, TTL, and a seen-message cache — deliberately NOT geographic
/// forwarding yet (Stage 3), so this floods to every connected neighbor
/// rather than picking a "closer" one. There's no location data to pick
/// with yet.
class MeshRouter extends ChangeNotifier {
  MeshRouter._();

  static final MeshRouter instance = MeshRouter._();

  /// Matches the TTL example in the architecture doc (Section 9) — large
  /// enough to survive several hops during initial discovery/fallback.
  static const int defaultTtl = 20;

  late final DiscoveryService _discovery;
  bool _started = false;
  bool _permissionsGranted = false;
  bool _startFailed = false;

  bool get permissionsGranted => _permissionsGranted;
  bool get startFailed => _startFailed;

  final Map<String, DiscoveredPeer> _peers = {};
  final Map<String, PeerConnectionState> _peerStates = {};

  /// endpointId → the peer's real Mesh ID, learned via a hello handshake
  /// right after connecting. A peer stays in [_peers]/[_peerStates] under
  /// its endpointId (session-scoped); this map is the only place that
  /// links that session to a stable identity. Not read anywhere yet — it's
  /// here because Stage 3 (geographic forwarding) will need to match a
  /// connection back to an identity to attach location data to it.
  final Map<String, String> _endpointToMeshId = {};

  /// messageIds this device has already processed — prevents the same
  /// chat message being re-delivered or re-forwarded if it loops back
  /// (architecture doc, Section 8). Hellos are NOT put in here — a fresh
  /// hello should fire on every new connection.
  final Set<String> _seenMessageIds = {};

  Map<String, DiscoveredPeer> get peers => Map.unmodifiable(_peers);
  Map<String, PeerConnectionState> get peerStates =>
      Map.unmodifiable(_peerStates);

  /// True once this device has exchanged hellos with at least one peer —
  /// i.e. there's a live neighbor it could forward through right now.
  bool get hasConnectedNeighbor =>
      _peerStates.values.any((s) => s == PeerConnectionState.connected);

  Future<void> start() async {
    if (_started) return;
    _started = true;

    _discovery = createDiscoveryService();

    _discovery.onPeerFound.listen((peer) {
      _peers[peer.endpointId] = peer;
      _peerStates.putIfAbsent(peer.endpointId, () => PeerConnectionState.connecting);
      notifyListeners();
      // Neighbors are physical-proximity based, not tied to the Contacts
      // list (architecture doc, Section 1) — connect to every Mesh.ly
      // device found, no manual "Add" step.
      _discovery.connectTo(peer.endpointId);
    });

    _discovery.onPeerLost.listen((endpointId) {
      _peers.remove(endpointId);
      _peerStates.remove(endpointId);
      _endpointToMeshId.remove(endpointId);
      notifyListeners();
    });

    _discovery.onConnectionStateChanged.listen((event) {
      final (endpointId, state) = event;
      _peerStates[endpointId] = state;
      notifyListeners();

      if (state == PeerConnectionState.connected) {
        _sendHello(endpointId);
      } else if (state == PeerConnectionState.disconnected ||
          state == PeerConnectionState.failed) {
        _endpointToMeshId.remove(endpointId);
      }
    });

    _discovery.onPayloadReceived.listen((event) {
      final (endpointId, bytes) = event;
      final envelope = MeshEnvelopeCodec.tryDecode(bytes);
      if (envelope == null) return; // malformed — drop, never crash
      _handleEnvelope(endpointId, envelope);
    });

    _permissionsGranted = await PermissionsService.requestAll();
    notifyListeners();
    if (!_permissionsGranted) return;

    final identity = IdentityRepository.instance.user!;
    try {
      await _discovery.start(identity.username);
    } catch (_) {
      _startFailed = true;
      notifyListeners();
    }
  }

  void _sendHello(String endpointId) {
    final identity = IdentityRepository.instance.user!;
    final hello = MeshEnvelope(
      messageId: _randomId(),
      origin: identity.meshId,
      destination: '',
      ttl: 1,
      type: MeshEnvelope.helloType,
      payload: identity.username,
    );
    _discovery.sendBytes(endpointId, MeshEnvelopeCodec.encode(hello));
  }

  void _handleEnvelope(String fromEndpointId, MeshEnvelope envelope) {
    if (envelope.type == MeshEnvelope.helloType) {
      _endpointToMeshId[fromEndpointId] = envelope.origin;
      notifyListeners();
      return;
    }

    // Duplicate-prevention cache (Section 8) — drop anything already
    // processed instead of re-delivering or re-forwarding it.
    if (_seenMessageIds.contains(envelope.messageId)) return;
    _seenMessageIds.add(envelope.messageId);

    final myMeshId = IdentityRepository.instance.user!.meshId;
    if (envelope.type == MeshEnvelope.chatType &&
        envelope.destination == myMeshId) {
      MessagesRepository.instance.recordIncoming(
        envelope.origin,
        Message(
          id: envelope.messageId,
          senderId: envelope.origin,
          receiverId: myMeshId,
          content: envelope.payload,
          timestamp: envelope.timestamp,
        ),
      );
    }

    // Forward regardless of whether this device was the destination — a
    // message not addressed here always needs forwarding while TTL allows.
    if (envelope.destination != myMeshId && envelope.ttl > 1) {
      final forwarded = envelope.decremented();
      final bytes = MeshEnvelopeCodec.encode(forwarded);
      for (final endpointId in _peerStates.keys) {
        if (endpointId == fromEndpointId) continue;
        if (_peerStates[endpointId] != PeerConnectionState.connected) continue;
        _discovery.sendBytes(endpointId, bytes);
      }
    }
  }

  /// Sends a chat message toward [destinationMeshId]. Floods to every
  /// currently connected neighbor — if the recipient is a direct neighbor
  /// it's delivered immediately; otherwise it's up to those neighbors
  /// (running this same logic) to keep it moving.
  Future<void> sendChatMessage(String destinationMeshId, String text) async {
    final identity = IdentityRepository.instance.user!;
    final messageId = _randomId();
    final envelope = MeshEnvelope(
      messageId: messageId,
      origin: identity.meshId,
      destination: destinationMeshId,
      ttl: defaultTtl,
      type: MeshEnvelope.chatType,
      payload: text,
    );

    // Never re-process our own message if it loops back through the mesh.
    _seenMessageIds.add(messageId);

    MessagesRepository.instance.recordOutgoing(
      destinationMeshId,
      Message(
        id: messageId,
        senderId: identity.meshId,
        receiverId: destinationMeshId,
        content: text,
        timestamp: envelope.timestamp,
        isRead: true,
      ),
    );

    final bytes = MeshEnvelopeCodec.encode(envelope);
    for (final entry in _peerStates.entries) {
      if (entry.value != PeerConnectionState.connected) continue;
      await _discovery.sendBytes(entry.key, bytes);
    }
  }

  String _randomId() {
    final random = Random.secure();
    final bytes = List<int>.generate(8, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}