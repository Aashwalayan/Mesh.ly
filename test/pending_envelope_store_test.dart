import 'package:flutter_test/flutter_test.dart';
import 'package:meshly/models/mesh_envelope.dart';
import 'package:meshly/services/pending_envelope_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  MeshEnvelope envelope(String id, DateTime expiresAt) => MeshEnvelope(
        messageId: id,
        origin: 'A',
        destination: 'D',
        ttl: 4,
        type: MeshEnvelope.chatType,
        expiresAt: expiresAt,
      );

  test('restores valid pending envelopes with stable IDs', () async {
    final store = PendingEnvelopeStore();
    final pending =
        envelope('stable-id', DateTime.now().add(const Duration(minutes: 1)));
    await store.save([pending]);

    final restored = await store.load();

    expect(restored, hasLength(1));
    expect(restored.single.messageId, 'stable-id');
  });

  test('does not restore expired envelopes', () async {
    final store = PendingEnvelopeStore();
    await store.save(
        [envelope('old', DateTime.now().subtract(const Duration(seconds: 1)))]);

    expect(await store.load(), isEmpty);
  });
}
