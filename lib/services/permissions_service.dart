import 'package:permission_handler/permission_handler.dart';

/// Requests the runtime permissions `nearby_connections` needs, mirroring
/// the exact request pattern from the package's own README/example
/// (https://github.com/mannprerak2/nearby_connections#request-permissions).
///
/// Two things this does NOT do, both worth knowing about:
///
/// 1. It doesn't turn Bluetooth or Wi-Fi on for you. Google announced
///    (Android Developers Blog, 20 Jul 2026) that Nearby Connections will
///    stop auto-enabling those radios for apps, rolling out "late 2026" —
///    so for reliable demos, make sure Bluetooth AND location/Wi-Fi are
///    switched on by hand on both phones beforehand.
/// 2. It doesn't gate discovery on GPS/location being enabled, even though
///    the plugin's own docs say devices "may disconnect more often" if
///    Location is off. Checking/enabling that needs the `location` package,
///    which isn't added yet — for now, just make sure Location is on too.
class PermissionsService {
  PermissionsService._();

  /// Requests every permission `nearby_connections` can need across the
  /// Android versions this runs on. Permissions that don't apply to the
  /// device's current Android version (e.g. BLUETOOTH_SCAN pre-Android 12)
  /// are simply no-ops — permission_handler handles that internally.
  static Future<bool> requestAll() async {
    final statuses = await [
      Permission.location,
      Permission.bluetooth,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.nearbyWifiDevices,
    ].request();

    return statuses.values.every(
      (status) => status.isGranted || status.isLimited,
    );
  }
}
