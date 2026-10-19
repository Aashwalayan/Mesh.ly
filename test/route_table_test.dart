import 'package:flutter_test/flutter_test.dart';
import 'package:meshly/services/route_table.dart';

void main() {
  test('uses a fresh route and removes it after expiry', () {
    final table = RouteTable(routeLifetime: const Duration(minutes: 1));
    final now = DateTime.utc(2026, 10, 19, 12);
    table.install(destinationNodeId: 'D', nextHopNodeId: 'B', now: now);

    expect(table.routeFor('D', now: now)?.nextHopNodeId, 'B');
    expect(
        table.routeFor('D', now: now.add(const Duration(minutes: 1))), isNull);
  });

  test('invalidates every route that uses a disconnected next hop', () {
    final table = RouteTable();
    final now = DateTime.utc(2026, 10, 19, 12);
    table.install(destinationNodeId: 'D', nextHopNodeId: 'B', now: now);
    table.install(destinationNodeId: 'E', nextHopNodeId: 'B', now: now);
    table.install(destinationNodeId: 'F', nextHopNodeId: 'C', now: now);

    table.invalidateNextHop('B');

    expect(table.routeFor('D', now: now), isNull);
    expect(table.routeFor('E', now: now), isNull);
    expect(table.routeFor('F', now: now)?.nextHopNodeId, 'C');
  });
}
