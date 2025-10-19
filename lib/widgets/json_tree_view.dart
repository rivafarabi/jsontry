import 'package:flutter/material.dart';
import 'package:jsontry/models/json_node.dart';
import 'package:jsontry/utils/app_color_scheme.dart';
import 'package:jsontry/utils/style_cache.dart';
import 'package:jsontry/widgets/json_node_row.dart';
import 'package:provider/provider.dart';
import 'package:jsontry/providers/json_provider.dart';

class JsonTreeView extends StatefulWidget {
  const JsonTreeView({super.key});

  @override
  State<JsonTreeView> createState() => _JsonTreeViewState();
}

class _JsonTreeViewState extends State<JsonTreeView> {
  String? _lastSearchQuery;

  late final AppColorScheme _colorScheme;
  late final StyleCache _styleCache;

  @override
  void initState() {
    super.initState();
    _colorScheme = AppColorScheme();
    _styleCache = StyleCache();
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
      color: _colorScheme.backgroundColor,
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
          return JsonNodeRow(
            node: provider.nodes[index],
            provider: provider,
            index: index,
            colorScheme: _colorScheme,
            styleCache: _styleCache,
            isSelected: provider.nodes[index].isSelected,
            onTap: () => _handleNodeTap(provider.nodes[index], provider),
            onToggleTap: () => _handleToggleTap(provider.nodes[index], provider),
            onContextMenu: provider.handleContextMenuAction,
          );
        },
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
          return JsonNodeRow(
            node: provider.nodes[index],
            provider: provider,
            index: index,
            colorScheme: _colorScheme,
            styleCache: _styleCache,
            isSelected: provider.nodes[index].isSelected,
            onTap: () => _handleNodeTap(provider.nodes[index], provider),
            onToggleTap: () => _handleToggleTap(provider.nodes[index], provider),
            onContextMenu: provider.handleContextMenuAction,
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
    provider.selectNode(node);
  }

  void _handleToggleTap(JsonNode node, JsonProvider provider) {
    if (node.isCollapsible) {
      provider.toggleNode(node.path);
    }
  }
}
