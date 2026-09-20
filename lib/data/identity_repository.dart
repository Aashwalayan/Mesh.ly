import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';

/// The local user's identity: a display name they choose once on first
/// launch, plus a random Mesh ID generated for this install. Persisted
/// on-device via shared_preferences — nothing here ever touches a network
/// or a server.
///
/// This is NOT a verified/cryptographic identity. Anyone can type any name,
/// and the Mesh ID is just a random string, not a public key or signature
/// — there's no way (yet) for a peer to confirm someone is who they claim
/// to be. What this DOES fix: every install used to share one hardcoded
/// identity (MockData.currentUser), so two phones scanning each other's QR
/// codes were really just each scanning a copy of the same fake person.
/// Now every install gets its own random Mesh ID the first time it runs.
class IdentityRepository extends ChangeNotifier {
  IdentityRepository._();

  static final IdentityRepository instance = IdentityRepository._();

  static const _usernameKey = 'identity_username';
  static const _meshIdKey = 'identity_mesh_id';

  User? _user;
  bool _loaded = false;

  /// The saved identity, or null if none has been created yet (or hasn't
  /// finished loading — check [isLoaded] first).
  User? get user => _user;

  /// True once the on-device check for an existing identity has finished.
  bool get isLoaded => _loaded;

  bool get hasIdentity => _user != null;

  /// Reads any previously saved identity from disk. Call once at startup.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString(_usernameKey);
    final meshId = prefs.getString(_meshIdKey);

    if (username != null && meshId != null) {
      _user = User(username: username, meshId: meshId);
    }

    _loaded = true;
    notifyListeners();
  }

  /// Creates this install's identity: the given display name, plus a fresh
  /// random Mesh ID, and saves both to disk.
  Future<void> create(String username) async {
    final meshId = _generateMeshId();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey, username);
    await prefs.setString(_meshIdKey, meshId);

    _user = User(username: username, meshId: meshId);
    notifyListeners();
  }

  /// 8 cryptographically-random bytes, hex-encoded — e.g. "MESH-3F9A21C0B6D4E812".
  /// Unique per install; not tied to any account or server.
  String _generateMeshId() {
    final random = Random.secure();
    final bytes = List<int>.generate(8, (_) => random.nextInt(256));
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return 'MESH-${hex.toUpperCase()}';
  }
}