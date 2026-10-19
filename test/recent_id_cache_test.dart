import 'package:flutter_test/flutter_test.dart';
import 'package:meshly/services/recent_id_cache.dart';

void main() {
  test('suppresses duplicates until their configured expiry', () {
    final cache = RecentIdCache(lifetime: const Duration(seconds: 10));
    final now = DateTime.utc(2026, 10, 19, 12);
    expect(cache.recordIfAbsent('message', now: now), isTrue);
    expect(cache.recordIfAbsent('message', now: now), isFalse);
    expect(
        cache.recordIfAbsent('message',
            now: now.add(const Duration(seconds: 10))),
        isTrue);
  });

  test('evicts the oldest IDs when capacity is reached', () {
    final cache = RecentIdCache(capacity: 2);
    final now = DateTime.utc(2026, 10, 19, 12);
    cache.recordIfAbsent('one', now: now);
    cache.recordIfAbsent('two', now: now.add(const Duration(seconds: 1)));
    cache.recordIfAbsent('three', now: now.add(const Duration(seconds: 2)));
    expect(cache.contains('one', now: now.add(const Duration(seconds: 2))),
        isFalse);
    expect(cache.contains('two', now: now.add(const Duration(seconds: 2))),
        isTrue);
  });
}
