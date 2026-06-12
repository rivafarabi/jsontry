import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jsontry/models/json_node.dart';
import 'package:jsontry/providers/app_provider.dart';
import 'package:jsontry/providers/json_provider.dart';
import 'package:jsontry/utils/app_theme.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class MacosPlatformMenu extends StatefulWidget {
  final Widget child;

  const MacosPlatformMenu({super.key, required this.child});

  @override
  State<MacosPlatformMenu> createState() => _MacosPlatformMenuState();
}

class _MacosPlatformMenuState extends State<MacosPlatformMenu> {
  Future<String?> _getAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  @override
  Widget build(BuildContext context) {
    return Selector2<AppProvider, JsonProvider, (ThemeMode, bool)>(
      selector: (_, appProvider, jsonProvider) => (appProvider.themeMode, jsonProvider.selectedNode != null),
      builder: (_, selector, ___) {
        final (themeMode, nodeSelected) = selector;

        return PlatformMenuBar(
          menus: [
            PlatformMenu(
              label: 'App Menu',
              menus: [
                const PlatformMenuItemGroup(
                  members: [
                    PlatformProvidedMenuItem(type: PlatformProvidedMenuItemType.about),
                  ],
                ),
                const PlatformMenuItemGroup(
                  members: [
                    PlatformProvidedMenuItem(type: PlatformProvidedMenuItemType.hide),
                  ],
                ),
                if (PlatformProvidedMenuItem.hasMenu(PlatformProvidedMenuItemType.quit))
                  const PlatformProvidedMenuItem(type: PlatformProvidedMenuItemType.quit),
              ],
            ),
            PlatformMenu(
              label: 'File',
              menus: [
                PlatformMenuItemGroup(
                  members: [
                    PlatformMenuItem(
                      label: 'Open...',
                      shortcut: const SingleActivator(LogicalKeyboardKey.keyO, meta: true),
                      onSelected: context.read<JsonProvider>().loadJsonFile,
                    ),
                    PlatformMenuItem(
                      label: 'Open from Clipboard...',
                      shortcut: const SingleActivator(LogicalKeyboardKey.keyV, meta: true, shift: true),
                      onSelected: () => _openFromClipboard(context),
                    ),
                  ],
                ),
              ],
            ),
            PlatformMenu(
              label: 'Edit',
              menus: [
                PlatformMenuItemGroup(
                  members: [
                    PlatformMenuItem(
                      label: 'Copy Selected Key',
                      onSelected: nodeSelected ? () => _handleEditContextMenu("Copy Key") : null,
                    ),
                    PlatformMenuItem(
                      label: 'Copy Selected Value',
                      onSelected: nodeSelected ? () => _handleEditContextMenu("Copy Value") : null,
                    ),
                    PlatformMenuItem(
                      label: 'Copy Selected Path',
                      onSelected: nodeSelected ? () => _handleEditContextMenu("Copy Path") : null,
                    ),
                  ],
                ),
              ],
            ),
            PlatformMenu(
              label: 'View',
              menus: [
                PlatformMenuItemGroup(
                  members: [
                    PlatformMenuItem(
                      label: 'Expand All',
                      shortcut: const SingleActivator(LogicalKeyboardKey.keyE, meta: true),
                      onSelected: () => context.read<JsonProvider>().expandAll(),
                    ),
                    PlatformMenuItem(
                      label: 'Collapse All',
                      shortcut: const SingleActivator(LogicalKeyboardKey.keyR, meta: true),
                      onSelected: () => context.read<JsonProvider>().collapseAll(),
                    ),
                  ],
                ),
                PlatformMenuItemGroup(
                  members: [
                    PlatformMenu(
                      label: 'Theme',
                      menus: [
                        PlatformMenuItem(
                          label: themeMode == ThemeMode.light ? '✓ Light' : 'Light',
                          onSelected: () => _handleToggleTheme(context, ThemeMode.light),
                        ),
                        PlatformMenuItem(
                          label: themeMode == ThemeMode.dark ? '✓ Dark' : 'Dark',
                          onSelected: () => _handleToggleTheme(context, ThemeMode.dark),
                        ),
                        PlatformMenuItem(
                          label: themeMode == ThemeMode.system ? '✓ System' : 'System',
                          onSelected: () => _handleToggleTheme(context, ThemeMode.system),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            PlatformMenu(
              label: 'Help',
              menus: [
                PlatformMenuItemGroup(
                  members: [
                    PlatformMenuItem(
                      label: 'About JSONTry',
                      onSelected: () => _showAboutDialog(context),
                    ),
                  ],
                ),
              ],
            ),
          ],
          child: widget.child,
        );
      },
    );
  }

  void _handleEditContextMenu(String action) {
    JsonNode? node = context.read<JsonProvider>().selectedNode;

    if (node == null) return;

    context.read<JsonProvider>().handleContextMenuAction(action, node);
  }

  void _handleToggleTheme(BuildContext context, ThemeMode mode) {
    context.read<AppProvider>().handleToggleThemeMode(mode);
  }

  Future<void> _openFromClipboard(BuildContext context) async {
    try {
      final clipboardData = await Clipboard.getData('text/plain');

      if (!context.mounted) return;

      if (clipboardData?.text != null && clipboardData!.text!.isNotEmpty) {
        await context.read<JsonProvider>().loadJsonFromString(clipboardData.text!);
      } else {
        _showErrorDialog(context, 'Clipboard is empty or does not contain text.');
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorDialog(context, 'Failed to read from clipboard: $e');
      }
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    final isDark = AppTheme.isDark(context);
    showDialog(
      context: context,
      builder: (context) => Theme(
        data: AppTheme.themeData(isDark),
        child: AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final textColor = AppTheme.textPrimary(isDark);
    showDialog(
      context: context,
      builder: (context) => Theme(
        data: AppTheme.themeData(isDark),
        child: AlertDialog(
          title: const Text('About JSONTry'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FutureBuilder<String?>(
                    future: _getAppVersion(),
                    builder: (context, snapshot) {
                      final style = TextStyle(color: textColor, fontWeight: FontWeight.w600);
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Text('Loading version...');
                      } else if (snapshot.hasError) {
                        return Text('Version: Error loading version', style: style);
                      } else {
                        return Text('JSONTry v${snapshot.data}', style: style);
                      }
                    }),
                const SizedBox(height: 8),
                const Text('An open source JSON viewer.'),
                const SizedBox(height: 8),
                Text('Features:', style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                const Text('• View and navigate large JSON files'),
                const Text('• Search through JSON data'),
                const Text('• Copy keys, values, and paths'),
                const Text('• Optimized performance for large files'),
                const SizedBox(height: 16),
                const Text('Made with ☕ by Riva Farabi.'),
                const Text('© 2025 Bigvaria. All rights reserved.'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                launchUrl(Uri.parse('https://github.com/rivafarabi/jsontry'));
              },
              child: const Text('GitHub'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }
}
