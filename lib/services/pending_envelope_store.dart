import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/mesh_envelope.dart';

/// Small, bounded store-and-forward queue. Routes and neighbour state remain
/// transient; only valid, not-yet-expired envelopes are restored after a
/// process restart.
class PendingEnvelopeStore {
  static const _storageKey = 'mesh_pending_envelopes_v1';

  PendingEnvelopeStore({this.capacity = 100});

  final int capacity;

  Future<List<MeshEnvelope>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final values = prefs.getStringList(_storageKey) ?? const [];
    final result = <MeshEnvelope>[];
    for (final value in values) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is! Map) continue;
        final envelope = MeshEnvelope.tryFromJson(
          Map<String, dynamic>.from(decoded),
        );
        if (envelope != null && !envelope.isExpired) result.add(envelope);
      } on FormatException {
        // Corrupt persisted data is untrusted just like incoming packets.
      }
    }
    if (result.length != values.length) await save(result);
    return result;
  }

  Future<void> save(Iterable<MeshEnvelope> envelopes) async {
    final valid = envelopes.where((envelope) => !envelope.isExpired).toList();
    if (valid.length > capacity) {
      valid.removeRange(0, valid.length - capacity);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _storageKey,
      valid.map((envelope) => jsonEncode(envelope.toJson())).toList(),
    );
  }
}
