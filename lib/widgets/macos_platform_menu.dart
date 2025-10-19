import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:jsontry/models/json_node.dart';
import 'package:jsontry/providers/json_provider.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:provider/provider.dart';

class MacosPlatformMenu extends StatefulWidget {
  final Widget child;

  const MacosPlatformMenu({super.key, required this.child});

  @override
  State<MacosPlatformMenu> createState() => _MacosPlatformMenuState();
}

class _MacosPlatformMenuState extends State<MacosPlatformMenu> {
  @override
  Widget build(BuildContext context) {
    return Selector<JsonProvider, bool>(
      selector: (_, provider) => provider.selectedNode != null,
      builder: (_, nodeSelected, ___) => PlatformMenuBar(
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
        ],
        child: widget.child,
      ),
    );
  }

  void _handleEditContextMenu(String action) {
    JsonNode? node = context.read<JsonProvider>().selectedNode;

    if (node == null) return;

    context.read<JsonProvider>().handleContextMenuAction(action, node);
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
    showMacosAlertDialog(
      context: context,
      builder: (context) => MacosAlertDialog(
        appIcon: const MacosIcon(CupertinoIcons.exclamationmark_triangle),
        title: const Text('Error'),
        message: Text(message),
        primaryButton: PushButton(
          controlSize: ControlSize.large,
          child: const Text('OK'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}
