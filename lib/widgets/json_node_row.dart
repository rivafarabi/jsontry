import 'package:flutter/material.dart';
import 'package:jsontry/models/json_node.dart';
import 'package:jsontry/providers/json_provider.dart';
import 'package:jsontry/utils/app_color_scheme.dart';
import 'package:jsontry/utils/style_cache.dart';
import 'package:native_context_menu/native_context_menu.dart';

class JsonNodeRow extends StatelessWidget {
  final JsonNode node;
  final JsonProvider provider;
  final int index;
  final AppColorScheme colorScheme;
  final StyleCache styleCache;
  final VoidCallback? onTap;
  final Function(BuildContext context, String action, JsonNode node, JsonProvider provider)? onContextMenu;

  const JsonNodeRow({
    super.key,
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
        MenuItem(
          title: 'Copy Value As...',
          items: [
            MenuItem(title: 'Formatted Value'),
            MenuItem(title: 'Minified Value'),
          ],
        ),
        MenuItem(title: 'Copy Path'),
        if (isCollapsible) MenuItem(title: node.isExpanded ? 'Collapse' : 'Expand'),
      ],
      child: GestureDetector(
        onTap: isCollapsible ? onTap : null,
        child: Container(
          height: 25,
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
        color: colorScheme.expansionButtonColor,
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
