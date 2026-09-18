# Services

This folder is the swap point between "the UI talks to mock data" and "the
UI talks to real device-to-device networking." Every screen depends only on
`discovery_service.dart`'s `DiscoveryService` interface — never on
`MockDiscoveryService` or `NearbyDiscoveryService` directly — so the two are
interchangeable.

## Files

- `discovery_service.dart` — the interface. Start here to understand what a
  "discovery service" can do (find peers, connect, send/receive bytes).
- `mock_discovery_service.dart` — frontend-only implementation, backed by
  `data/mock_data.dart`. No Bluetooth/Wi-Fi involved.
- `nearby_discovery_service.dart` — real Android implementation, built on
  Google's [Nearby Connections API](https://developers.google.com/nearby/connections/overview)
  via the [`nearby_connections`](https://pub.dev/packages/nearby_connections)
  plugin. Advertises and discovers over BLE; the plugin auto-upgrades the
  data channel to Wi-Fi once two devices connect. **Android only.**
- `permissions_service.dart` — requests the runtime permissions
  `nearby_connections` needs (Bluetooth, location, nearby Wi-Fi devices).
- `service_locator.dart` — the one switch (`kUseRealNearbyConnections`)
  that picks mock vs. real. Flip it to `false` to fall back to mock data
  without touching any screen.

## Known limitations (Day 1 scope)

- **No incoming-connection UI.** Both sides auto-accept connection
  requests. The plugin's own example shows a proper accept/reject sheet —
  worth adding once there's a reason to reject someone.
- **Connection state is coarse.** `PeerConnectionState` only has
  `connecting` / `connected` / `failed` / `disconnected`. The plugin's
  underlying `Status` enum likely has more detail (e.g. distinguishing a
  rejected request from a radio/permission error), but its exact member
  names beyond `Status.ERROR` weren't confirmable from public docs at the
  time this was written — rather than guess names that might not compile,
  anything that isn't a clean success collapses into `failed`. If you need
  finer-grained status handling, check the installed package version's
  actual enum (e.g. via your IDE's "go to definition" on `Status`) and
  expand `_onConnectionResult` in `nearby_discovery_service.dart`.
- **Radios aren't auto-enabled.** Google announced (Android Developers
  Blog, 20 Jul 2026) that Nearby Connections will stop auto-enabling
  Bluetooth/Wi-Fi for apps, rolling out "late 2026." Make sure both are
  switched on by hand on test devices — this app doesn't check or prompt
  for that yet.
- **No message wiring yet.** `onPayloadReceived` exists on the interface
  and is populated by `NearbyDiscoveryService`, but nothing in the Chat
  screen listens to it yet — that's the next piece to build (see the
  4-day roadmap, Day 2).
