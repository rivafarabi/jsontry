import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:native_context_menu/native_context_menu.dart';
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

  // Performance optimization: Cache color schemes to avoid repeated calculations
  late final _ColorScheme _colorScheme;
  late final _StyleCache _styleCache;

  @override
  void initState() {
    super.initState();
    _colorScheme = _ColorScheme();
    _styleCache = _StyleCache();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update color scheme when theme changes
    _colorScheme.updateColors(context);
    _styleCache.updateStyles();
  }

  @override
  void dispose() {
    context.read<JsonProvider>().scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _colorScheme.backgroundColor,
        border: Border(
          top: BorderSide(
            color: _colorScheme.dividerColor,
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

          // Use optimized ListView for large datasets
          return _buildOptimizedListView(provider);
        },
      ),
    );
  }

  Widget _buildOptimizedListView(JsonProvider provider) {
    final itemCount = provider.nodes.length;

    // For very large lists, use additional optimizations
    if (itemCount > 1000) {
      return ListView.builder(
        controller: provider.scrollController,
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return _OptimizedJsonRow(
            node: provider.nodes[index],
            provider: provider,
            index: index,
            colorScheme: _colorScheme,
            styleCache: _styleCache,
            onTap: () => _handleNodeTap(provider.nodes[index], provider),
            onContextMenu: _handleContextMenuAction,
          );
        },
        // Performance optimizations for large lists
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: true,
        addSemanticIndexes: false,
        cacheExtent: 500, // Increased cache for better scrolling
        physics: const ClampingScrollPhysics(), // Better for large lists
        itemExtent: 25, // Fixed height for better performance
      );
    } else {
      // Use standard ListView for smaller lists
      return ListView.builder(
        controller: provider.scrollController,
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return _OptimizedJsonRow(
            node: provider.nodes[index],
            provider: provider,
            index: index,
            colorScheme: _colorScheme,
            styleCache: _styleCache,
            onTap: () => _handleNodeTap(provider.nodes[index], provider),
            onContextMenu: _handleContextMenuAction,
          );
        },
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: true,
        addSemanticIndexes: false,
        cacheExtent: 100,
      );
    }
  }

  void _handleNodeTap(JsonNode node, JsonProvider provider) {
    final isCollapsible = _isNodeCollapsible(node);
    if (isCollapsible) {
      provider.toggleNode(node.path);
    }
  }

  bool _isNodeCollapsible(JsonNode node) {
    if (node.type == JsonNodeType.object) {
      return node.value is Map<String, dynamic> && (node.value as Map<String, dynamic>).isNotEmpty;
    } else if (node.type == JsonNodeType.array) {
      return node.value is List && (node.value as List).isNotEmpty;
    }
    return false;
  }

  void _handleContextMenuAction(BuildContext context, String action, JsonNode node, JsonProvider provider) {
    switch (action) {
      case 'Copy Key':
        if (node.key != null) {
          Clipboard.setData(ClipboardData(text: node.key!));
          _showCopySnackBar(context, 'Key copied to clipboard');
        }
        break;
      case 'Copy Value':
        String valueText;
        if (node.type == JsonNodeType.string) {
          valueText = node.value.toString();
        } else {
          valueText = node.value.toString();
        }
        Clipboard.setData(ClipboardData(text: valueText));
        _showCopySnackBar(context, 'Value copied to clipboard');
        break;
      case 'Copy Path':
        Clipboard.setData(ClipboardData(text: node.path));
        _showCopySnackBar(context, 'Path copied to clipboard');
        break;
      case 'Expand':
      case 'Collapse':
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
}

// Performance optimization classes
class _ColorScheme {
  late Color backgroundColor;
  late Color keyColor;
  late Color dividerColor;
  late Color evenRowColor;
  late Color oddRowColor;
  late Color searchMatchColor;
  late Color currentResultColor;
  late bool isDark;

  // Cached type colors
  static const Map<JsonNodeType, Color> _typeColors = {
    JsonNodeType.object: Color(0xFF2196F3), // Blue
    JsonNodeType.array: Color(0xFF3F51B5), // Indigo
    JsonNodeType.string: Color(0xFF4CAF50), // Green
    JsonNodeType.number: Color(0xFFFF9800), // Orange
    JsonNodeType.boolean: Color(0xFF9C27B0), // Purple
    JsonNodeType.nullValue: Color(0xFF757575), // Grey
  };

  void updateColors(BuildContext context) {
    if (UniversalPlatform.isMacOS) {
      isDark = MacosTheme.of(context).brightness == Brightness.dark;
      backgroundColor = MacosTheme.of(context).canvasColor;
    } else if (UniversalPlatform.isWindows) {
      isDark = fluent.FluentTheme.of(context).brightness == Brightness.dark;
      final fluentTheme = fluent.FluentTheme.maybeOf(context);
      backgroundColor = fluentTheme?.scaffoldBackgroundColor ?? Theme.of(context).scaffoldBackgroundColor;
    } else {
      isDark = Theme.of(context).brightness == Brightness.dark;
      backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    }

    keyColor = isDark ? Colors.blue.shade300 : Colors.blue.shade700;
    dividerColor = Theme.of(context).dividerColor;

    evenRowColor = isDark ? Colors.grey.shade800.withOpacity(0.3) : Colors.grey.shade50;
    oddRowColor = isDark ? Colors.grey.shade900.withOpacity(0.2) : Colors.white;

    searchMatchColor = isDark ? Colors.blue.shade600.withOpacity(0.3) : Colors.blue.shade200.withOpacity(0.3);
    currentResultColor = isDark ? Colors.blue.shade600.withOpacity(0.8) : Colors.blue.shade200.withOpacity(0.8);
  }

  Color getTypeColor(JsonNodeType type) => _typeColors[type]!;

  Color getValueColor(JsonNodeType type) {
    switch (type) {
      case JsonNodeType.string:
        return isDark ? Colors.green.shade300 : Colors.green.shade700;
      case JsonNodeType.number:
        return isDark ? Colors.orange.shade300 : Colors.orange.shade700;
      case JsonNodeType.boolean:
        return isDark ? Colors.purple.shade300 : Colors.purple.shade700;
      case JsonNodeType.nullValue:
        return isDark ? Colors.grey.shade400 : Colors.grey.shade600;
      default:
        return isDark ? Colors.blue.shade300 : Colors.blue.shade700;
    }
  }
}

class _StyleCache {
  late TextStyle baseStyle;
  late TextStyle keyStyle;
  late TextStyle colonStyle;

  void updateStyles() {
    baseStyle = const TextStyle(
      fontFamily: 'SF Mono',
      fontSize: 11,
    );

    keyStyle = baseStyle.copyWith(
      fontWeight: FontWeight.w600,
      fontSize: 11,
    );

    colonStyle = baseStyle.copyWith(
      fontSize: 11,
    );
  }
}

// Optimized row widget that memoizes expensive calculations
class _OptimizedJsonRow extends StatelessWidget {
  final JsonNode node;
  final JsonProvider provider;
  final int index;
  final _ColorScheme colorScheme;
  final _StyleCache styleCache;
  final VoidCallback? onTap;
  final Function(BuildContext context, String action, JsonNode node, JsonProvider provider)? onContextMenu;

  const _OptimizedJsonRow({
    required this.node,
    required this.provider,
    required this.index,
    required this.colorScheme,
    required this.styleCache,
    this.onTap,
    this.onContextMenu,
  });

  @override
  Widget build(BuildContext context) {
    // Cache expensive calculations
    final isEven = index % 2 == 0;
    final isSearchMatch = provider.isSearchMatch(node.path);
    final isCurrentResult = provider.isCurrentSearchResult(node.path);
    final isCollapsible = _isCollapsible();
    final backgroundColor = _getBackgroundColor(isEven, isSearchMatch, isCurrentResult);

    return ContextMenuRegion(
      onItemSelected: (item) => onContextMenu != null ? onContextMenu!(context, item.title, node, provider) : null,
      menuItems: [
        MenuItem(title: 'Copy Key'),
        MenuItem(title: 'Copy Value'),
        MenuItem(title: 'Copy Path'),
        if (isCollapsible) MenuItem(title: node.isExpanded ? 'Collapse' : 'Expand'),
      ],
      child: GestureDetector(
        onTap: isCollapsible ? onTap : null,
        child: Container(
          height: 25, // Fixed height for better scrolling performance
          padding: EdgeInsets.only(
            left: (node.depth * 16.0),
            right: 12.0,
            top: 3.0,
            bottom: 3.0,
          ),
          decoration: BoxDecoration(color: backgroundColor),
          child: Row(
            children: [
              SizedBox(width: (isCollapsible ? 8.0 : 30) + (node.depth * 8.0)),
              _buildExpansionIcon(isCollapsible),
              if (node.key != null) ...[
                Text(
                  '${node.key}',
                  style: styleCache.keyStyle.copyWith(color: colorScheme.keyColor),
                ),
                Text(
                  ' : ',
                  style: styleCache.colonStyle.copyWith(color: colorScheme.keyColor),
                ),
              ],
              Expanded(child: _buildValueWidget()),
              const SizedBox(width: 8),
              _buildTypeIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  bool _isCollapsible() {
    if (node.type == JsonNodeType.object) {
      return node.value is Map<String, dynamic> && (node.value as Map<String, dynamic>).isNotEmpty;
    } else if (node.type == JsonNodeType.array) {
      return node.value is List && (node.value as List).isNotEmpty;
    }
    return false;
  }

  Color _getBackgroundColor(bool isEven, bool isSearchMatch, bool isCurrentResult) {
    if (isCurrentResult) return colorScheme.currentResultColor;
    if (isSearchMatch) return colorScheme.searchMatchColor;
    return isEven ? colorScheme.evenRowColor : colorScheme.oddRowColor;
  }

  Widget _buildExpansionIcon(bool isCollapsible) {
    if (!isCollapsible) return const SizedBox.shrink();

    if (node.children == null || node.children!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: 14,
      height: 14,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400, width: 1),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Icon(
        node.isExpanded ? Icons.remove : Icons.add,
        size: 10,
        color: Colors.grey.shade600,
      ),
    );
  }

  Widget _buildValueWidget() {
    final style = styleCache.baseStyle.copyWith(
      color: colorScheme.getValueColor(node.type),
    );

    switch (node.type) {
      case JsonNodeType.object:
        final objectMap = node.value as Map<String, dynamic>;
        return Text(
          node.isExpanded ? '{' : '{ ${objectMap.length} ${objectMap.length == 1 ? 'item' : 'items'} }',
          style: style.copyWith(fontWeight: FontWeight.w500),
        );

      case JsonNodeType.array:
        final arrayList = node.value as List;
        return Text(
          node.isExpanded ? '[' : '[ ${arrayList.length} ${arrayList.length == 1 ? 'item' : 'items'} ]',
          style: style.copyWith(fontWeight: FontWeight.w500),
        );

      case JsonNodeType.string:
        return Text(
          '"${node.value}"',
          style: style,
          overflow: TextOverflow.ellipsis,
        );

      case JsonNodeType.number:
        return Text(
          node.value.toString(),
          style: style.copyWith(fontWeight: FontWeight.w500),
        );

      case JsonNodeType.boolean:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Text(
            node.value.toString(),
            style: style.copyWith(fontWeight: FontWeight.w600),
          ),
        );

      case JsonNodeType.nullValue:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Text(
            'null',
            style: style.copyWith(
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
    }
  }

  Widget _buildTypeIndicator() {
    final typeColor = colorScheme.getTypeColor(node.type);
    final typeLabel = _getTypeLabel();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: typeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: typeColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        typeLabel,
        style: TextStyle(
          fontSize: 10,
          color: typeColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _getTypeLabel() {
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
