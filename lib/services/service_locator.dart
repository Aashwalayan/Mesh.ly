import 'discovery_service.dart';
import 'mock_discovery_service.dart';
import 'nearby_discovery_service.dart';

/// Single switch controlling which [DiscoveryService] the app uses.
///
/// Flip to `false` to fall back to the frontend-only mock — e.g. if the
/// real Nearby Connections setup misbehaves right before a demo. Nothing
/// else in the app needs to change either way, since every screen depends
/// on [DiscoveryService], not on which implementation is behind it.
const bool kUseRealNearbyConnections = true;

/// App-wide identifier so Mesh.ly installs find each other and not other
/// apps using the same Nearby Connections API on the same devices.
const String kMeshlyServiceId = 'com.example.minor_app.meshly';

/// Creates the [DiscoveryService] the app should use, per
/// [kUseRealNearbyConnections].
///
/// Call this once per screen that needs discovery (e.g. in `initState`),
/// and call `dispose()` on the result when that screen is disposed —
/// [DiscoveryService] instances aren't shared/reused across screens yet.
DiscoveryService createDiscoveryService() {
  return kUseRealNearbyConnections
      ? NearbyDiscoveryService(serviceId: kMeshlyServiceId)
      : MockDiscoveryService();
}
