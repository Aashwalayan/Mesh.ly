import 'dart:collection';

/// Bounded, expiring duplicate suppression for untrusted packet IDs.
///
/// An ID is recorded before delivery/forwarding so concurrently arriving
/// copies cannot create duplicate chat entries. Expiry and capacity limits
/// prevent sustained discovery or retry traffic from consuming memory.
class RecentIdCache {
  RecentIdCache({
    this.capacity = 2048,
    this.lifetime = const Duration(minutes: 30),
  });

  final int capacity;
  final Duration lifetime;
  final LinkedHashMap<String, DateTime> _entries = LinkedHashMap();

  bool contains(String id, {DateTime? now}) {
    _prune((now ?? DateTime.now()).toUtc());
    return _entries.containsKey(id);
  }

  /// Returns false for a duplicate; true only for a newly accepted ID.
  bool recordIfAbsent(String id, {DateTime? now}) {
    final current = (now ?? DateTime.now()).toUtc();
    _prune(current);
    if (_entries.containsKey(id)) return false;
    _entries[id] = current.add(lifetime);
    while (_entries.length > capacity) {
      _entries.remove(_entries.keys.first);
    }
    return true;
  }

  void _prune(DateTime now) {
    _entries.removeWhere((_, expiry) => !expiry.isAfter(now));
  }
}
