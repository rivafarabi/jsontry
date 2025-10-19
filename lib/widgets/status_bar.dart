import 'package:flutter/material.dart';
import 'package:jsontry/widgets/context_menu_button.dart';
import 'package:native_context_menu/native_context_menu.dart';
import 'package:provider/provider.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import '../providers/json_provider.dart';

class StatusBar extends StatelessWidget {
  const StatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<JsonProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            if (provider.selectedNode != null)
              Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: _getBackgroundColor(context),
                  border: Border(
                    top: BorderSide(
                      color: _getBorderColor(context),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FittedBox(
                            child: Icon(
                              Icons.account_tree_outlined,
                              size: 14,
                              color: Colors.blue.withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            provider.selectedNode!.path,
                            style: TextStyle(fontSize: 12, color: Colors.blue.withOpacity(0.8), fontWeight: FontWeight.w600, height: 1),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    _buildNodePathMenu(provider)
                  ],
                ),
              ),
            Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: _getBackgroundColor(context),
                border: Border(
                  top: BorderSide(
                    color: _getBorderColor(context),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // File size
                  if (provider.fileSize > 0) ...[
                    _buildStatusItem(
                      context,
                      Icons.storage,
                      provider.fileSizeFormatted,
                      Colors.green,
                    ),
                    const SizedBox(width: 12),
                  ],

                  // Load time
                  if (provider.loadDuration != null) ...[
                    _buildStatusItem(
                      context,
                      Icons.timer,
                      'Loaded in ${_formatDuration(provider.loadDuration!)}',
                      Colors.orange,
                    ),
                    const SizedBox(width: 12),
                  ],

                  const Spacer(),

                  // Node count
                  if (provider.nodes.isNotEmpty) ...[
                    _buildStatusItem(
                      context,
                      Icons.account_tree,
                      '${provider.totalNodes} nodes',
                      Colors.indigo,
                    ),
                  ],

                  // Loading indicator
                  if (provider.isLoading) ...[
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.blue.withOpacity(0.8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Loading...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusItem(BuildContext context, IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color.withOpacity(0.8),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getBackgroundColor(BuildContext context) {
    if (UniversalPlatform.isMacOS) {
      return MacosTheme.of(context).canvasColor;
    } else if (UniversalPlatform.isWindows) {
      return fluent.FluentTheme.of(context).scaffoldBackgroundColor;
    } else {
      return Theme.of(context).scaffoldBackgroundColor;
    }
  }

  Color _getBorderColor(BuildContext context) {
    if (UniversalPlatform.isMacOS) {
      return MacosTheme.of(context).dividerColor;
    } else if (UniversalPlatform.isWindows) {
      return fluent.FluentTheme.of(context).resources.dividerStrokeColorDefault;
    } else {
      return Theme.of(context).dividerColor;
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inMilliseconds < 1000) {
      return '${duration.inMilliseconds}ms';
    } else {
      return '${(duration.inMilliseconds / 1000).toStringAsFixed(2)}s';
    }
  }

  _buildNodePathMenu(JsonProvider provider) {
    return ContextMenuButton(
      onItemSelected: (item) => provider.handleContextMenuAction(item.title, provider.selectedNode!),
      menuItems: [
        MenuItem(title: 'Copy Key'),
        MenuItem(title: 'Copy Value'),
        MenuItem(
          title: 'Copy Value As...',
          items: [
            MenuItem(title: 'Formatted Value'),
            MenuItem(title: 'Minified Value'),
          ],
        ),
        MenuItem(title: 'Copy Path'),
      ],
    );
  }
}
