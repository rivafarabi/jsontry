import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'providers/json_provider.dart';
import 'screens/json_viewer_screen.dart';

void main() {
  runApp(const JsonTryApp());
}

class JsonTryApp extends StatelessWidget {
  const JsonTryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => JsonProvider(),
      child: Consumer<JsonProvider>(
        builder: (context, jsonProvider, child) {
          if (UniversalPlatform.isMacOS) {
            return MacosApp(
              title: jsonProvider.windowTitle,
              theme: MacosThemeData.light(),
              darkTheme: MacosThemeData.dark(),
              home: const JsonViewerScreen(),
              debugShowCheckedModeBanner: false,
            );
          } else if (UniversalPlatform.isWindows) {
            return fluent.FluentApp(
              title: jsonProvider.windowTitle,
              theme: fluent.FluentThemeData.light(),
              darkTheme: fluent.FluentThemeData.dark(),
              home: const JsonViewerScreen(),
              debugShowCheckedModeBanner: false,
            );
          } else {
            return MaterialApp(
              title: jsonProvider.windowTitle,
              theme: ThemeData(
                primarySwatch: Colors.blue,
                useMaterial3: true,
              ),
              home: const JsonViewerScreen(),
              debugShowCheckedModeBanner: false,
            );
          }
        },
      ),
    );
  }
}

