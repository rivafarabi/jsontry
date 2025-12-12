import 'package:flutter/material.dart' hide MenuBar;
import 'package:flutter/services.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:jsontry/models/json_node.dart';
import 'package:jsontry/providers/json_provider.dart';
import 'package:menu_bar/menu_bar.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class WindowsPlatformMenu extends StatefulWidget {
  final Widget child;

  const WindowsPlatformMenu({super.key, required this.child});

  @override
  State<WindowsPlatformMenu> createState() => _WindowsPlatformMenuState();
}

class _WindowsPlatformMenuState extends State<WindowsPlatformMenu> {
  Future<String?> _getAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  @override
  Widget build(BuildContext context) {
    return Selector<JsonProvider, bool>(
      selector: (_, provider) => provider.selectedNode != null,
      builder: (_, nodeSelected, ___) => Container(
        color: fluent.FluentTheme.of(context).menuColor,
        child: MenuBarWidget(
          barStyle: const MenuStyle(
            backgroundColor: WidgetStatePropertyAll<Color>(Colors.transparent),
            shadowColor: WidgetStatePropertyAll<Color>(Colors.transparent),
            surfaceTintColor: WidgetStatePropertyAll<Color>(Colors.transparent),
          ),
          barButtonStyle: ButtonStyle(
            alignment: Alignment.center,
            visualDensity: VisualDensity.compact,
            minimumSize: const WidgetStatePropertyAll<Size>(Size(0, 32)),
            textStyle: WidgetStatePropertyAll<TextStyle>(fluent.FluentTheme.of(context).typography.caption!),
          ),
          menuButtonStyle: ButtonStyle(
            backgroundColor: WidgetStatePropertyAll<Color>(fluent.FluentTheme.of(context).micaBackgroundColor),
            minimumSize: const WidgetStatePropertyAll<Size>(Size(250, 42)),
            visualDensity: VisualDensity.compact,
            textStyle: WidgetStatePropertyAll<TextStyle>(fluent.FluentTheme.of(context).typography.caption!),
          ),
          barButtons: [
            BarButton(
              text: const Text('File'),
              submenu: SubMenu(
                menuItems: [
                  MenuButton(
                    text: const Text('Open...'),
                    shortcutText: 'Ctrl+O',
                    onTap: context.read<JsonProvider>().loadJsonFile,
                  ),
                  MenuButton(
                    text: const Text('Open from Clipboard...'),
                    shortcutText: 'Ctrl+Shift+V',
                    onTap: () => _openFromClipboard(context),
                  ),
                  MenuDivider(
                    height: 0,
                    color: fluent.FluentTheme.of(context).resources.dividerStrokeColorDefault,
                  ),
                  MenuButton(
                    text: const Text('Exit'),
                    shortcutText: 'Alt+F4',
                    onTap: () => _exitApp(context),
                  ),
                ],
              ),
            ),
            BarButton(
              text: const Text('Edit'),
              submenu: SubMenu(
                menuItems: [
                  MenuButton(
                    text: const Text('Copy Selected Key'),
                    shortcutText: 'Ctrl+K',
                    onTap: nodeSelected ? () => _handleEditContextMenu("Copy Key") : null,
                  ),
                  MenuButton(
                    text: const Text('Copy Selected Value'),
                    shortcutText: 'Ctrl+C',
                    onTap: nodeSelected ? () => _handleEditContextMenu("Copy Value") : null,
                  ),
                  MenuButton(
                    text: const Text('Copy Selected Path'),
                    shortcutText: 'Ctrl+P',
                    onTap: nodeSelected ? () => _handleEditContextMenu("Copy Path") : null,
                  ),
                ],
              ),
            ),
            BarButton(
              text: const Text('View'),
              submenu: SubMenu(
                menuItems: [
                  MenuButton(
                    text: const Text('Expand All'),
                    shortcutText: 'Ctrl+E',
                    onTap: () => _handleViewAction("Expand All"),
                  ),
                  MenuButton(
                    text: const Text('Collapse All'),
                    shortcutText: 'Ctrl+R',
                    onTap: () => _handleViewAction("Collapse All"),
                  ),
                  MenuDivider(
                    height: 0,
                    color: fluent.FluentTheme.of(context).resources.dividerStrokeColorDefault,
                  ),
                  MenuButton(
                    text: const Text('Find...'),
                    shortcutText: 'Ctrl+F',
                    onTap: () => _handleViewAction("Find"),
                  ),
                ],
              ),
            ),
            BarButton(
              text: const Text('Help'),
              submenu: SubMenu(
                menuItems: [
                  MenuButton(
                    text: const Text('About JSONTry'),
                    onTap: () => _showAboutDialog(context),
                  ),
                ],
              ),
            ),
          ],
          child: widget.child,
        ),
      ),
    );
  }

  void _exitApp(BuildContext context) {
    // Exit the application
    // You might want to show a confirmation dialog here
    // For now, we'll just close the app
    Navigator.of(context).pop();
  }

  void _handleEditContextMenu(String action) {
    JsonNode? node = context.read<JsonProvider>().selectedNode;

    if (node == null) return;

    context.read<JsonProvider>().handleContextMenuAction(action, node);
  }

  void _handleViewAction(String action) {
    final provider = context.read<JsonProvider>();

    switch (action) {
      case "Expand All":
        provider.expandAll();
        break;
      case "Collapse All":
        provider.collapseAll();
        break;
      case "Find":
        // Focus on search bar - this would need to be implemented
        // For now, we can just show a message
        _showInfoDialog(context, 'Use Ctrl+F to search within the JSON data');
        break;
    }
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

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => fluent.ContentDialog(
        title: const Text('About JSONTry'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<String?>(
                future: _getAppVersion(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Text('Loading version...');
                  } else if (snapshot.hasError) {
                    return const Text('Version: Error loading version');
                  } else {
                    return Text('JSONTry v${snapshot.data}');
                  }
                }),
            const SizedBox(height: 8),
            const Text('An open source JSON viewer.'),
            const SizedBox(height: 8),
            const Text('Features:'),
            const Text('• View and navigate large JSON files'),
            const Text('• Search through JSON data'),
            const Text('• Copy keys, values, and paths'),
            const Text('• Optimized performance for large files'),
            const SizedBox(height: 16),
            const Text('Made with ☕ by Riva Farabi.'),
            const Text('© 2025 Bigvaria. All rights reserved.'),
          ],
        ),
        actions: [
          fluent.Button(
              child: const Text('GitHub'),
              onPressed: () {
                launchUrl(Uri.parse('https://github.com/rivafarabi/jsontry'));
              }),
          fluent.Button(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => fluent.ContentDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          fluent.Button(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => fluent.ContentDialog(
        title: const Text('Information'),
        content: Text(message),
        actions: [
          fluent.Button(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
