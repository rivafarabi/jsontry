import 'package:flutter/material.dart';
import 'package:jsontry/widgets/context_menu_button.dart';
import 'package:native_context_menu/native_context_menu.dart';
import 'package:provider/provider.dart';
import '../providers/json_provider.dart';
import '../utils/app_theme.dart';

class StatusBar extends StatelessWidget {
  const StatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);

    return Consumer<JsonProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            if (provider.selectedNode != null)
              _buildBar(
                isDark,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: _buildChip(
                        isDark: isDark,
                        icon: Icons.account_tree_outlined,
                        label: provider.selectedNode!.path,
                        color: AppTheme.accent(isDark),
                      ),
                    ),
                    _buildNodePathMenu(provider),
                  ],
                ),
              ),
            _buildBar(
              isDark,
              child: Row(
                children: [
                  // File size
                  if (provider.fileSize > 0) ...[
                    _buildChip(
                      isDark: isDark,
                      icon: Icons.storage_rounded,
                      label: provider.fileSizeFormatted,
                      color: AppTheme.statusSuccess(isDark),
                    ),
                    const SizedBox(width: 8),
                  ],

                  // Load time
                  if (provider.loadDuration != null) ...[
                    _buildChip(
                      isDark: isDark,
                      icon: Icons.timer_outlined,
                      label: 'Loaded in ${_formatDuration(provider.loadDuration!)}',
                      color: AppTheme.statusWarning(isDark),
                    ),
                    const SizedBox(width: 8),
                  ],

                  const Spacer(),

                  // Node count
                  if (provider.nodes.isNotEmpty) ...[
                    _buildChip(
                      isDark: isDark,
                      icon: Icons.account_tree_rounded,
                      label: '${provider.totalNodes} nodes',
                      color: AppTheme.accent(isDark),
                    ),
                  ],

                  // Loading indicator
                  if (provider.isLoading) ...[
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 13,
                      height: 13,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.accent(isDark),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Loading...',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.accent(isDark),
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

  Widget _buildBar(bool isDark, {required Widget child}) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surface(isDark),
        border: Border(
          top: BorderSide(color: AppTheme.border(isDark)),
        ),
      ),
      child: child,
    );
  }

  Widget _buildChip({required bool isDark, required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                color: color,
                fontWeight: FontWeight.w600,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inMilliseconds < 1000) {
      return '${duration.inMilliseconds}ms';
    } else {
      return '${(duration.inMilliseconds / 1000).toStringAsFixed(2)}s';
    }
  }

  Widget _buildNodePathMenu(JsonProvider provider) {
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
