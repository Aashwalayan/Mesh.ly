/// Transient, local route state. Entries are learned from successful route
/// discovery responses; they are never treated as proof that the neighbour
/// is still connected after a lifecycle event or process restart.
class RouteTable {
  RouteTable({
    this.routeLifetime = const Duration(minutes: 5),
    this.maxEntries = 256,
  });

  final Duration routeLifetime;
  final int maxEntries;
  final Map<String, ActiveRoute> _routes = {};

  ActiveRoute? routeFor(String destinationNodeId, {DateTime? now}) {
    final route = _routes[destinationNodeId];
    if (route == null) return null;
    if (!route.expiresAt.isAfter((now ?? DateTime.now()).toUtc())) {
      _routes.remove(destinationNodeId);
      return null;
    }
    return route;
  }

  void install({
    required String destinationNodeId,
    required String nextHopNodeId,
    DateTime? now,
  }) {
    final installedAt = (now ?? DateTime.now()).toUtc();
    _routes[destinationNodeId] = ActiveRoute(
      destinationNodeId: destinationNodeId,
      nextHopNodeId: nextHopNodeId,
      installedAt: installedAt,
      expiresAt: installedAt.add(routeLifetime),
    );
    if (_routes.length > maxEntries) {
      final oldest = _routes.entries.reduce(
        (left, right) =>
            left.value.installedAt.isBefore(right.value.installedAt)
                ? left
                : right,
      );
      _routes.remove(oldest.key);
    }
  }

  void invalidateDestination(String destinationNodeId) {
    _routes.remove(destinationNodeId);
  }

  void invalidateNextHop(String nodeId) {
    _routes.removeWhere((_, route) => route.nextHopNodeId == nodeId);
  }
}

class ActiveRoute {
  const ActiveRoute({
    required this.destinationNodeId,
    required this.nextHopNodeId,
    required this.installedAt,
    required this.expiresAt,
  });

  final String destinationNodeId;
  final String nextHopNodeId;
  final DateTime installedAt;
  final DateTime expiresAt;
}
