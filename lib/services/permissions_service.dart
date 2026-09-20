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

  /// Requests the runtime permissions needed by Nearby Connections.
  ///
  /// `Permission.bluetooth` is deliberately absent: it represents legacy
  /// `BLUETOOTH`, which is an install-time permission through Android 11 and
  /// is capped at API 30 in the manifest. Requiring its status on Android 12+
  /// would always report denied even when the three applicable Nearby Devices
  /// permissions have been granted.
  ///
  /// On older Android releases, permission_handler maps the modern Bluetooth
  /// entries below to the legacy Bluetooth status; on Android 12+ it requests
  /// SCAN, ADVERTISE, and CONNECT. It ignores entries not available on the
  /// device's SDK level.
  static Future<bool> requestAll() async {
    final statuses = await [
      Permission.location,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.nearbyWifiDevices,
    ].request();

    final granted = statuses.values.every(
      (status) => status.isGranted || status.isLimited,
    );
    // ignore: avoid_print
    print('[Mesh/diag] Runtime permissions: $statuses; allGranted=$granted');
    await _logServiceStatus();
    return granted;
  }

  /// Permissions being granted does not mean the underlying radio or Location
  /// service is currently switched on. Log both before Nearby is started.
  static Future<void> _logServiceStatus() async {
    try {
      final location = await Permission.location.serviceStatus;
      final bluetooth = await Permission.bluetooth.serviceStatus;
      // ignore: avoid_print
      print(
        '[Mesh/diag] Service status: location=$location, bluetooth=$bluetooth',
      );
    } catch (error) {
      // Some Android versions do not expose one of these service checks.
      // ignore: avoid_print
      print('[Mesh/diag] Could not read radio/service status: $error');
    }
  }
}
