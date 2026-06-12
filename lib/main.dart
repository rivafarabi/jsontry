import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jsontry/providers/app_provider.dart';
import 'package:provider/provider.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:window_manager/window_manager.dart';
import 'providers/json_provider.dart';
import 'screens/json_viewer_screen.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(size: Size(500, 650), minimumSize: Size(400, 650), skipTaskbar: false, title: "JSONTry");
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  final jsonProvider = JsonProvider();
  unawaited(jsonProvider.initialize(launchArgs: args));

  runApp(JsonTryApp(jsonProvider: jsonProvider));
}

class JsonTryApp extends StatelessWidget {
  final JsonProvider jsonProvider;

  const JsonTryApp({super.key, required this.jsonProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => AppProvider(),
        ),
        ChangeNotifierProvider.value(
          value: jsonProvider,
        ),
      ],
      child: Consumer2<AppProvider, JsonProvider>(
        builder: (context, appProvider, jsonProvider, child) {
          if (UniversalPlatform.isMacOS) {
            return MacosApp(
              title: jsonProvider.windowTitle,
              theme: MacosThemeData.light(),
              darkTheme: MacosThemeData.dark(),
              home: const JsonViewerScreen(),
              themeMode: appProvider.themeMode,
              debugShowCheckedModeBanner: false,
            );
          } else if (UniversalPlatform.isWindows) {
            return fluent.FluentApp(
              title: jsonProvider.windowTitle,
              theme: fluent.FluentThemeData.light(),
              darkTheme: fluent.FluentThemeData.dark(),
              home: const JsonViewerScreen(),
              themeMode: appProvider.themeMode,
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
              themeMode: appProvider.themeMode,
              debugShowCheckedModeBanner: false,
            );
          }
        },
      ),
    );
  }
}
