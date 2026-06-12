import 'package:flutter/material.dart' hide MenuBar;
import 'package:flutter/services.dart';
import 'package:jsontry/models/json_node.dart';
import 'package:jsontry/providers/app_provider.dart';
import 'package:jsontry/providers/json_provider.dart';
import 'package:jsontry/utils/app_theme.dart';
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
    final isDark = AppTheme.isDark(context);
    final textColor = AppTheme.textPrimary(isDark);
    final dividerColor = AppTheme.border(isDark);
    final accentColor = AppTheme.accent(isDark);

    return Selector2<AppProvider, JsonProvider, List<dynamic>>(
      selector: (_, appProvider, jsonProvider) => [appProvider.themeMode, jsonProvider.selectedNode != null],
      builder: (_, selector, ___) {
        final [themeMode as ThemeMode, nodeSelected as bool] = selector;

        return Container(
          decoration: BoxDecoration(
            color: AppTheme.surface(isDark),
            border: Border(bottom: BorderSide(color: dividerColor)),
          ),
          child: MenuBarWidget(
            barStyle: const MenuStyle(
              backgroundColor: WidgetStatePropertyAll<Color>(Colors.transparent),
              shadowColor: WidgetStatePropertyAll<Color>(Colors.transparent),
              surfaceTintColor: WidgetStatePropertyAll<Color>(Colors.transparent),
            ),
            barButtonStyle: ButtonStyle(
              alignment: Alignment.center,
              visualDensity: VisualDensity.compact,
              minimumSize: const WidgetStatePropertyAll<Size>(Size(0, 34)),
              foregroundColor: WidgetStatePropertyAll<Color>(textColor),
              overlayColor: WidgetStatePropertyAll<Color>(AppTheme.surfaceVariant(isDark)),
              textStyle: const WidgetStatePropertyAll<TextStyle>(TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500)),
            ),
            menuButtonStyle: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll<Color>(AppTheme.surface(isDark)),
              foregroundColor: WidgetStatePropertyAll<Color>(textColor),
              minimumSize: const WidgetStatePropertyAll<Size>(Size(240, 38)),
              visualDensity: VisualDensity.compact,
              textStyle: const WidgetStatePropertyAll<TextStyle>(TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500)),
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
                      color: dividerColor,
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
                      onTap: () => _handleViewAction(context, "Expand All"),
                    ),
                    MenuButton(
                      text: const Text('Collapse All'),
                      shortcutText: 'Ctrl+R',
                      onTap: () => _handleViewAction(context, "Collapse All"),
                    ),
                    MenuDivider(
                      height: 0,
                      color: dividerColor,
                    ),
                    MenuButton(
                      text: const Text('Theme'),
                      submenu: SubMenu(
                        menuItems: [
                          MenuButton(
                            text: const Text('Light'),
                            icon: themeMode == ThemeMode.light ? _buildCheckmark(accentColor) : const SizedBox(width: 16),
                            onTap: () => _handleToggleTheme(context, ThemeMode.light),
                          ),
                          MenuButton(
                            text: const Text('Dark'),
                            icon: themeMode == ThemeMode.dark ? _buildCheckmark(accentColor) : const SizedBox(width: 16),
                            onTap: () => _handleToggleTheme(context, ThemeMode.dark),
                          ),
                          MenuButton(
                            text: const Text('System'),
                            icon: themeMode == ThemeMode.system ? _buildCheckmark(accentColor) : const SizedBox(width: 16),
                            onTap: () => _handleToggleTheme(context, ThemeMode.system),
                          ),
                        ],
                      ),
                    ),
                    MenuDivider(
                      height: 0,
                      color: dividerColor,
                    ),
                    MenuButton(
                      text: const Text('Find...'),
                      shortcutText: 'Ctrl+F',
                      onTap: () => _handleViewAction(context, "Find"),
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
                      onTap: () => _showAboutDialog(context, isDark, textColor),
                    ),
                  ],
                ),
              ),
            ],
            child: widget.child,
          ),
        );
      },
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

  void _handleViewAction(BuildContext context, String action) {
    final provider = context.read<JsonProvider>();
    final isDark = AppTheme.isDark(context);

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
        _showInfoDialog(context, isDark, 'Use Ctrl+F to search within the JSON data');
        break;
    }
  }

  void _handleToggleTheme(BuildContext context, ThemeMode mode) {
    context.read<AppProvider>().handleToggleThemeMode(mode);
  }

  Future<void> _openFromClipboard(BuildContext context) async {
    final isDark = AppTheme.isDark(context);

    try {
      final clipboardData = await Clipboard.getData('text/plain');

      if (!context.mounted) return;

      if (clipboardData?.text != null && clipboardData!.text!.isNotEmpty) {
        await context.read<JsonProvider>().loadJsonFromString(clipboardData.text!);
      } else {
        _showErrorDialog(context, isDark, 'Clipboard is empty or does not contain text.');
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorDialog(context, isDark, 'Failed to read from clipboard: $e');
      }
    }
  }

  void _showAboutDialog(BuildContext context, bool isDark, Color textColor) {
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

  void _showErrorDialog(BuildContext context, bool isDark, String message) {
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

  void _showInfoDialog(BuildContext context, bool isDark, String message) {
    showDialog(
      context: context,
      builder: (context) => Theme(
        data: AppTheme.themeData(isDark),
        child: AlertDialog(
          title: const Text('Information'),
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

  Widget _buildCheckmark(Color color) {
    return SizedBox(
      width: 16,
      child: Icon(
        Icons.check_rounded,
        size: 16,
        color: color,
      ),
    );
  }
}
