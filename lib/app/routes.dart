import 'package:flutter/material.dart';
import '../screens/home/home_screen.dart';
import '../screens/settings/settings_screen.dart';

/// Named routes for screens that don't need constructor arguments.
///
/// Screens that need arguments (e.g. [ChatScreen] needs a `Contact`) are
/// pushed directly with `Navigator.push(MaterialPageRoute(...))` from their
/// call site instead of being listed here — that keeps argument-passing
/// type-safe without a routing package.
class Routes {
  Routes._();

  static const home = '/';
  static const settings = '/settings';

  static Map<String, WidgetBuilder> table = {
    home: (_) => const HomeScreen(),
    settings: (_) => const SettingsScreen(),
  };
}
