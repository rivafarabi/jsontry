import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jsontry/models/json_node.dart';
import 'package:jsontry/utils/app_color_scheme.dart';
import 'package:jsontry/utils/style_cache.dart';
import 'package:jsontry/widgets/json_node_row.dart';
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
          return JsonNodeRow(
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
      case 'Formatted Value':
        String valueText;
        if (node.type == JsonNodeType.object || node.type == JsonNodeType.array) {
          try {
            valueText = const JsonEncoder.withIndent('  ').convert(node.value);
          } catch (e) {
            valueText = node.value.toString();
          }
        } else if (node.type == JsonNodeType.string) {
          valueText = node.value.toString();
        } else {
          valueText = node.value.toString();
        }
        Clipboard.setData(ClipboardData(text: valueText));
        _showCopySnackBar(context, 'Value copied to clipboard');
        break;
      case 'Minified Value':
        String minifiedValue;
        if (node.type == JsonNodeType.string) {
          minifiedValue = node.value.toString();
        } else {
          minifiedValue = node.value.toString();
        }
        Clipboard.setData(ClipboardData(text: minifiedValue));
        _showCopySnackBar(context, 'Minified value copied to clipboard');
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
