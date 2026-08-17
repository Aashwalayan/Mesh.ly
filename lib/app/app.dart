import 'package:flutter/material.dart';
import 'routes.dart';
import 'theme/app_theme.dart';

/// Root widget: sets up the MaterialApp shell, theme, and route table.
class MeshlyApp extends StatelessWidget {
  const MeshlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mesh.ly',
      theme: AppTheme.light(),
      initialRoute: Routes.home,
      routes: Routes.table,
    );
  }
}
