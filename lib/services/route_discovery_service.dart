import 'dart:collection';
import 'dart:convert';

/// A protocol-only implementation of controlled route discovery.
///
/// It owns no radio connections and has no Flutter dependency. The router
/// supplies an incoming neighbour ID and acts on the returned decision. This
/// separation keeps flooding/reverse-path rules testable without Bluetooth.
class RouteDiscoveryService {
  RouteDiscoveryService({
    required this.localNodeId,
    this.maxEntries = 512,
    this.defaultHopLimit = 8,
  });

  final String localNodeId;
  final int maxEntries;
  final int defaultHopLimit;

  final LinkedHashMap<String, DateTime> _seenRequests = LinkedHashMap();
  final LinkedHashMap<String, ReversePathEntry> _reversePaths = LinkedHashMap();

  RouteDiscoveryRequest createRequest({
    required String requestId,
    required String destinationNodeId,
    DateTime? now,
    Duration lifetime = const Duration(minutes: 2),
    int? hopLimit,
  }) {
    final createdAt = (now ?? DateTime.now()).toUtc();
    final request = RouteDiscoveryRequest(
      requestId: requestId,
      originNodeId: localNodeId,
      destinationNodeId: destinationNodeId,
      hopLimit: hopLimit ?? defaultHopLimit,
      hopCount: 0,
      createdAt: createdAt,
      expiresAt: createdAt.add(lifetime),
    );
    _rememberSeen(request);
    return request;
  }

  /// Records a reverse path for a first valid arrival and says whether the
  /// request should be forwarded, consumed as the destination, or dropped.
  RouteDiscoveryDecision receiveRequest({
    required RouteDiscoveryRequest request,
    required String incomingNeighborNodeId,
    DateTime? now,
  }) {
    final current = (now ?? DateTime.now()).toUtc();
    _prune(current);
    if (!request.isValid || !request.expiresAt.isAfter(current)) {
      return RouteDiscoveryDecision.drop(RouteDiscoveryDropReason.expired);
    }
    if (_seenRequests.containsKey(request.requestId)) {
      return RouteDiscoveryDecision.drop(RouteDiscoveryDropReason.duplicate);
    }

    _rememberSeen(request);
    _rememberReversePath(
      ReversePathEntry(
        requestId: request.requestId,
        originNodeId: request.originNodeId,
        previousHopNodeId: incomingNeighborNodeId,
        createdAt: current,
        expiresAt: request.expiresAt,
      ),
    );

    if (request.destinationNodeId == localNodeId) {
      return const RouteDiscoveryDecision.destinationReached();
    }
    if (request.hopCount >= request.hopLimit) {
      return RouteDiscoveryDecision.drop(RouteDiscoveryDropReason.hopLimit);
    }
    return RouteDiscoveryDecision.forward(request.forwarded());
  }

  /// Returns the local next reverse hop for a discovery response, if its
  /// matching discovery record is still fresh.
  String? reverseHopFor(String requestId, {DateTime? now}) {
    _prune((now ?? DateTime.now()).toUtc());
    return _reversePaths[requestId]?.previousHopNodeId;
  }

  void _rememberSeen(RouteDiscoveryRequest request) {
    _seenRequests.remove(request.requestId);
    _seenRequests[request.requestId] = request.expiresAt;
    _trim(_seenRequests);
  }

  void _rememberReversePath(ReversePathEntry entry) {
    _reversePaths.remove(entry.requestId);
    _reversePaths[entry.requestId] = entry;
    _trim(_reversePaths);
  }

  void _trim(LinkedHashMap map) {
    while (map.length > maxEntries) {
      map.remove(map.keys.first);
    }
  }

  void _prune(DateTime now) {
    _seenRequests.removeWhere((_, expiry) => !expiry.isAfter(now));
    _reversePaths.removeWhere((_, entry) => !entry.expiresAt.isAfter(now));
  }
}

enum RouteDiscoveryDropReason { duplicate, expired, hopLimit }

class RouteDiscoveryDecision {
  const RouteDiscoveryDecision._(
      {this.forwardedRequest, this.dropReason, this.isDestination = false});

  const RouteDiscoveryDecision.destinationReached()
      : this._(isDestination: true);

  factory RouteDiscoveryDecision.forward(RouteDiscoveryRequest request) =>
      RouteDiscoveryDecision._(forwardedRequest: request);

  factory RouteDiscoveryDecision.drop(RouteDiscoveryDropReason reason) =>
      RouteDiscoveryDecision._(dropReason: reason);

  final RouteDiscoveryRequest? forwardedRequest;
  final RouteDiscoveryDropReason? dropReason;
  final bool isDestination;

  bool get shouldForward => forwardedRequest != null;
}

class ReversePathEntry {
  const ReversePathEntry({
    required this.requestId,
    required this.originNodeId,
    required this.previousHopNodeId,
    required this.createdAt,
    required this.expiresAt,
  });

  final String requestId;
  final String originNodeId;
  final String previousHopNodeId;
  final DateTime createdAt;
  final DateTime expiresAt;
}

class RouteDiscoveryRequest {
  const RouteDiscoveryRequest({
    required this.requestId,
    required this.originNodeId,
    required this.destinationNodeId,
    required this.hopLimit,
    required this.hopCount,
    required this.createdAt,
    required this.expiresAt,
  });

  final String requestId;
  final String originNodeId;
  final String destinationNodeId;
  final int hopLimit;
  final int hopCount;
  final DateTime createdAt;
  final DateTime expiresAt;

  bool get isValid =>
      requestId.isNotEmpty &&
      requestId.length <= 128 &&
      originNodeId.isNotEmpty &&
      destinationNodeId.isNotEmpty &&
      hopLimit > 0 &&
      hopLimit <= 20 &&
      hopCount >= 0 &&
      hopCount <= hopLimit &&
      expiresAt.isAfter(createdAt);

  RouteDiscoveryRequest forwarded() => RouteDiscoveryRequest(
        requestId: requestId,
        originNodeId: originNodeId,
        destinationNodeId: destinationNodeId,
        hopLimit: hopLimit,
        hopCount: hopCount + 1,
        createdAt: createdAt,
        expiresAt: expiresAt,
      );

  Map<String, dynamic> toJson() => {
        'requestId': requestId,
        'originNodeId': originNodeId,
        'destinationNodeId': destinationNodeId,
        'hopLimit': hopLimit,
        'hopCount': hopCount,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'expiresAt': expiresAt.millisecondsSinceEpoch,
      };

  String encode() => jsonEncode(toJson());

  static RouteDiscoveryRequest? tryDecode(String source) {
    try {
      final value = jsonDecode(source);
      if (value is! Map) {
        return null;
      }
      final json = Map<String, dynamic>.from(value);
      final requestId = json['requestId'];
      final origin = json['originNodeId'];
      final destination = json['destinationNodeId'];
      final hopLimit = json['hopLimit'];
      final hopCount = json['hopCount'];
      final createdAt = json['createdAt'];
      final expiresAt = json['expiresAt'];
      if (requestId is! String ||
          origin is! String ||
          destination is! String ||
          hopLimit is! int ||
          hopCount is! int ||
          createdAt is! int ||
          expiresAt is! int) {
        return null;
      }
      final request = RouteDiscoveryRequest(
        requestId: requestId,
        originNodeId: origin,
        destinationNodeId: destination,
        hopLimit: hopLimit,
        hopCount: hopCount,
        createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt, isUtc: true),
        expiresAt: DateTime.fromMillisecondsSinceEpoch(expiresAt, isUtc: true),
      );
      return request.isValid ? request : null;
    } on FormatException {
      return null;
    }
  }
}
