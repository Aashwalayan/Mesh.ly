import 'package:flutter_test/flutter_test.dart';
import 'package:meshly/services/route_discovery_service.dart';

void main() {
  final now = DateTime.utc(2026, 10, 19, 12);

  test('discovers D from A through B and C using reverse paths', () {
    final a = RouteDiscoveryService(localNodeId: 'A');
    final b = RouteDiscoveryService(localNodeId: 'B');
    final c = RouteDiscoveryService(localNodeId: 'C');
    final d = RouteDiscoveryService(localNodeId: 'D');
    final request = a.createRequest(
      requestId: 'request-1',
      destinationNodeId: 'D',
      now: now,
    );

    final atB = b.receiveRequest(
      request: request,
      incomingNeighborNodeId: 'A',
      now: now,
    );
    final atC = c.receiveRequest(
      request: atB.forwardedRequest!,
      incomingNeighborNodeId: 'B',
      now: now,
    );
    final atD = d.receiveRequest(
      request: atC.forwardedRequest!,
      incomingNeighborNodeId: 'C',
      now: now,
    );

    expect(atD.isDestination, isTrue);
    expect(d.reverseHopFor('request-1', now: now), 'C');
    expect(c.reverseHopFor('request-1', now: now), 'B');
    expect(b.reverseHopFor('request-1', now: now), 'A');
  });

  test('suppresses duplicate arrivals and keeps the first reverse path', () {
    final b = RouteDiscoveryService(localNodeId: 'B');
    final request = RouteDiscoveryRequest(
      requestId: 'same-request',
      originNodeId: 'A',
      destinationNodeId: 'D',
      hopLimit: 4,
      hopCount: 0,
      createdAt: now,
      expiresAt: now.add(const Duration(minutes: 1)),
    );

    expect(
        b
            .receiveRequest(
                request: request, incomingNeighborNodeId: 'A', now: now)
            .shouldForward,
        isTrue);
    final duplicate = b.receiveRequest(
        request: request, incomingNeighborNodeId: 'E', now: now);
    expect(duplicate.dropReason, RouteDiscoveryDropReason.duplicate);
    expect(b.reverseHopFor('same-request', now: now), 'A');
  });

  test('enforces hop limits and expires reverse paths', () {
    final b = RouteDiscoveryService(localNodeId: 'B');
    final request = RouteDiscoveryRequest(
      requestId: 'limited',
      originNodeId: 'A',
      destinationNodeId: 'D',
      hopLimit: 1,
      hopCount: 1,
      createdAt: now,
      expiresAt: now.add(const Duration(seconds: 10)),
    );

    final decision = b.receiveRequest(
        request: request, incomingNeighborNodeId: 'A', now: now);
    expect(decision.dropReason, RouteDiscoveryDropReason.hopLimit);
    expect(b.reverseHopFor('limited', now: now), 'A');
    expect(
        b.reverseHopFor('limited', now: now.add(const Duration(seconds: 10))),
        isNull);
  });

  test('keeps concurrent discovery attempts separate', () {
    final b = RouteDiscoveryService(localNodeId: 'B');
    for (final id in ['route-1', 'route-2']) {
      expect(
          b
              .receiveRequest(
                request: RouteDiscoveryRequest(
                  requestId: id,
                  originNodeId: 'A',
                  destinationNodeId: 'D',
                  hopLimit: 4,
                  hopCount: 0,
                  createdAt: now,
                  expiresAt: now.add(const Duration(minutes: 1)),
                ),
                incomingNeighborNodeId: id == 'route-1' ? 'A' : 'E',
                now: now,
              )
              .shouldForward,
          isTrue);
    }
    expect(b.reverseHopFor('route-1', now: now), 'A');
    expect(b.reverseHopFor('route-2', now: now), 'E');
  });
}
