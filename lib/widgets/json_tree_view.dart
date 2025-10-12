import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:provider/provider.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:jsontry/providers/json_provider.dart';

class JsonTreeView extends StatefulWidget {
  const JsonTreeView({super.key});

  @override
  State<JsonTreeView> createState() => _JsonTreeViewState();
}

class _JsonTreeViewState extends State<JsonTreeView> {
  String? _lastSearchQuery;

  @override
  void dispose() {
    context.read<JsonProvider>().scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    late Color backgroundColor;

    if (UniversalPlatform.isMacOS) {
      backgroundColor = MacosTheme.of(context).canvasColor;
    } else if (UniversalPlatform.isWindows) {
      backgroundColor = fluent.FluentTheme.of(context).scaffoldBackgroundColor;
    } else {
      backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    }

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Consumer<JsonProvider>(
        builder: (context, provider, child) {
          // Clear state when search is cleared
          if (provider.searchQuery.isEmpty) {
            _lastSearchQuery = null;
          }

          // Check if search query changed (new search performed)
          if (provider.searchQuery != _lastSearchQuery) {
            _lastSearchQuery = provider.searchQuery;
          }

          return ListView.builder(
            controller: provider.scrollController,
            itemCount: provider.nodes.length,
            itemBuilder: (context, index) {
              return _buildNodeRow(context, provider.nodes[index], provider, index);
            },
            addAutomaticKeepAlives: false,
            addRepaintBoundaries: true,
            addSemanticIndexes: false,
            cacheExtent: 100,
          );
        },
      ),
    );
  }

  Widget _buildNodeRow(BuildContext context, JsonNode node, JsonProvider provider, int globalIndex) {
    final isDark = _isDarkMode(context);
    final isEven = globalIndex % 2 == 0;
    final isSearchMatch = provider.isSearchMatch(node.path);
    final isCurrentResult = provider.isCurrentSearchResult(node.path);
    late final bool isCollapsible;

    if (node.type == JsonNodeType.object) {
      isCollapsible = node.value is Map<String, dynamic> && (node.value as Map<String, dynamic>).isNotEmpty;
    } else if (node.type == JsonNodeType.array) {
      isCollapsible = node.value is List && (node.value as List).isNotEmpty;
    } else {
      isCollapsible = false;
    }

    Color backgroundColor = isCurrentResult
        ? (isDark ? Colors.blue.shade600.withOpacity(0.8) : Colors.blue.shade200.withOpacity(0.8))
        : isSearchMatch
            ? (isDark ? Colors.blue.shade600.withOpacity(0.3) : Colors.blue.shade200.withOpacity(0.3))
            : isEven
                ? (isDark ? Colors.grey.shade800.withOpacity(0.3) : Colors.grey.shade50)
                : (isDark ? Colors.grey.shade900.withOpacity(0.2) : Colors.white);

    return GestureDetector(
      onSecondaryTapDown: (details) => _showContextMenu(context, details.globalPosition, node, provider),
      onTap: () {
        if (isCollapsible) {
          provider.toggleNode(node.path);
        }
      },
      child: Container(
        padding: EdgeInsets.only(
          left: (node.depth * 16.0),
          right: 12.0,
          top: 3.0, // Reduced vertical padding
          bottom: 3.0,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
        ),
        child: Row(
          children: [
            // Indentation
            SizedBox(
              width: (isCollapsible ? 8.0 : 30) + (node.depth * 8.0),
            ),

            // Expansion icon
            _buildExpansionIcon(node),

            // Key
            if (node.key != null) ...[
              Text(
                '${node.key}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _getKeyColor(context),
                  fontFamily: 'SF Mono',
                  fontSize: 11,
                ),
              ),
              Text(
                ' : ',
                style: TextStyle(
                  color: _getKeyColor(context),
                  fontFamily: 'SF Mono',
                  fontSize: 11, // Reduced from 13
                ),
              ),
            ],

            // Value
            Expanded(
              child: _buildValueWidget(context, node),
            ),

            const SizedBox(width: 8), // Reduced spacing

            // Type indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), // Reduced padding
              decoration: BoxDecoration(
                color: _getTypeColor(node.type).withOpacity(0.15),
                borderRadius: BorderRadius.circular(4), // Reduced radius
                border: Border.all(
                  color: _getTypeColor(node.type).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                _getTypeLabel(node),
                style: TextStyle(
                  fontSize: 10, // Reduced from 11
                  color: _getTypeColor(node.type),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpansionIcon(JsonNode node) {
    if (node.type == JsonNodeType.object || node.type == JsonNodeType.array) {
      if (node.children == null || node.children!.isEmpty) {
        return const SizedBox.shrink();
      }

      return Container(
        width: 14,
        height: 14,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey.shade400,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Icon(
          node.isExpanded ? Icons.remove : Icons.add,
          size: 10,
          color: Colors.grey.shade600,
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildValueWidget(BuildContext context, JsonNode node) {
    const baseStyle = TextStyle(
      fontFamily: 'SF Mono',
      fontSize: 11,
    );

    switch (node.type) {
      case JsonNodeType.object:
        final objectMap = node.value as Map<String, dynamic>;
        return Text(
          node.isExpanded ? '{' : '{ ${objectMap.length} ${objectMap.length == 1 ? 'item' : 'items'} }',
          style: baseStyle.copyWith(
            color: _getValueColor(context, node.type),
            fontWeight: FontWeight.w500,
          ),
        );

      case JsonNodeType.array:
        final arrayList = node.value as List;
        return Text(
          node.isExpanded ? '[' : '[ ${arrayList.length} ${arrayList.length == 1 ? 'item' : 'items'} ]',
          style: baseStyle.copyWith(
            color: _getValueColor(context, node.type),
            fontWeight: FontWeight.w500,
          ),
        );

      case JsonNodeType.string:
        return Text(
          '"${node.value}"',
          style: baseStyle.copyWith(
            color: _getValueColor(context, node.type),
          ),
          overflow: TextOverflow.ellipsis,
        );

      case JsonNodeType.number:
        return Text(
          node.value.toString(),
          style: baseStyle.copyWith(
            color: _getValueColor(context, node.type),
            fontWeight: FontWeight.w500,
          ),
        );

      case JsonNodeType.boolean:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: node.value ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            node.value.toString(),
            style: baseStyle.copyWith(
              color: _getValueColor(context, node.type),
              fontWeight: FontWeight.w600,
            ),
          ),
        );

      case JsonNodeType.nullValue:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            'null',
            style: baseStyle.copyWith(
              color: _getValueColor(context, node.type),
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
    }
  }

  void _showContextMenu(BuildContext context, Offset position, JsonNode node, JsonProvider provider) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: [
        PopupMenuItem(
          value: 'copy_key',
          enabled: node.key != null,
          child: const Row(
            children: [
              Icon(Icons.copy, size: 16),
              SizedBox(width: 8),
              Text('Copy Key'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'copy_value',
          child: Row(
            children: [
              Icon(Icons.copy, size: 16),
              SizedBox(width: 8),
              Text('Copy Value'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'copy_path',
          child: Row(
            children: [
              Icon(Icons.route, size: 16),
              SizedBox(width: 8),
              Text('Copy Path'),
            ],
          ),
        ),
        if (node.type == JsonNodeType.object || node.type == JsonNodeType.array)
          PopupMenuItem(
            value: 'toggle_expand',
            child: Row(
              children: [
                Icon(
                  node.isExpanded ? Icons.unfold_less : Icons.unfold_more,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(node.isExpanded ? 'Collapse' : 'Expand'),
              ],
            ),
          ),
      ],
    ).then((value) {
      if (value != null) {
        _handleContextMenuAction(context, value, node, provider);
      }
    });
  }

  void _handleContextMenuAction(BuildContext context, String action, JsonNode node, JsonProvider provider) {
    switch (action) {
      case 'copy_key':
        if (node.key != null) {
          Clipboard.setData(ClipboardData(text: node.key!));
          _showCopySnackBar(context, 'Key copied to clipboard');
        }
        break;
      case 'copy_value':
        String valueText;
        if (node.type == JsonNodeType.string) {
          valueText = node.value.toString();
        } else {
          valueText = node.value.toString();
        }
        Clipboard.setData(ClipboardData(text: valueText));
        _showCopySnackBar(context, 'Value copied to clipboard');
        break;
      case 'copy_path':
        Clipboard.setData(ClipboardData(text: node.path));
        _showCopySnackBar(context, 'Path copied to clipboard');
        break;
      case 'toggle_expand':
        provider.toggleNode(node.path);
        break;
    }
  }

  void _showCopySnackBar(BuildContext context, String message) {
    // For macOS, we'll show a simple dialog instead of SnackBar since
    // we don't have ScaffoldMessenger in the native UI context
    if (UniversalPlatform.isMacOS) {
      // On macOS, just print to console - in a real app you might want to
      // show a toast-like notification using native macOS APIs
      debugPrint(message);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  bool _isDarkMode(BuildContext context) {
    if (UniversalPlatform.isMacOS) {
      return MacosTheme.of(context).brightness == Brightness.dark;
    } else if (UniversalPlatform.isWindows) {
      return fluent.FluentTheme.of(context).brightness == Brightness.dark;
    } else {
      return Theme.of(context).brightness == Brightness.dark;
    }
  }

  Color _getKeyColor(BuildContext context) {
    final isDark = _isDarkMode(context);

    return isDark
        ? const Color(0xFF81D4FA) // Light blue
        : const Color(0xFF1976D2); // Dark blue
  }

  Color _getValueColor(BuildContext context, JsonNodeType type) {
    final isDark = _isDarkMode(context);

    switch (type) {
      case JsonNodeType.string:
        return isDark ? const Color(0xFF81C784) : const Color(0xFF388E3C); // Green
      case JsonNodeType.number:
        return isDark ? const Color(0xFFFFB74D) : const Color(0xFFF57C00); // Orange
      case JsonNodeType.boolean:
        return isDark ? const Color(0xFFBA68C8) : const Color(0xFF7B1FA2); // Purple
      case JsonNodeType.nullValue:
        return isDark ? Colors.grey.shade400 : Colors.grey.shade600;
      case JsonNodeType.object:
      case JsonNodeType.array:
        return isDark ? Colors.grey.shade300 : Colors.grey.shade700;
    }
  }

  Color _getTypeColor(JsonNodeType type) {
    switch (type) {
      case JsonNodeType.object:
        return const Color(0xFF2196F3); // Blue
      case JsonNodeType.array:
        return const Color(0xFF3F51B5); // Indigo
      case JsonNodeType.string:
        return const Color(0xFF4CAF50); // Green
      case JsonNodeType.number:
        return const Color(0xFFFF9800); // Orange
      case JsonNodeType.boolean:
        return const Color(0xFF9C27B0); // Purple
      case JsonNodeType.nullValue:
        return const Color(0xFF757575); // Grey
    }
  }

  String _getTypeLabel(JsonNode node) {
    switch (node.type) {
      case JsonNodeType.object:
        final objectMap = node.value as Map<String, dynamic>;
        return 'Object (${objectMap.length})';
      case JsonNodeType.array:
        final arrayList = node.value as List;
        return 'Array (${arrayList.length})';
      case JsonNodeType.string:
        return 'String';
      case JsonNodeType.number:
        return node.value is int ? 'Integer' : 'Number';
      case JsonNodeType.boolean:
        return 'Boolean';
      case JsonNodeType.nullValue:
        return 'Null';
    }
  }
}
