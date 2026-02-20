import 'package:flutter/material.dart';
import 'package:jsontry/models/json_node.dart';
import 'package:jsontry/providers/json_provider.dart';
import 'package:jsontry/utils/app_color_scheme.dart';
import 'package:jsontry/utils/style_cache.dart';
import 'package:native_context_menu/native_context_menu.dart';

class JsonNodeRow extends StatefulWidget {
  final JsonNode node;
  final JsonProvider provider;
  final int index;
  final AppColorScheme colorScheme;
  final StyleCache styleCache;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onToggleTap;
  final Function(String action, JsonNode node)? onContextMenu;

  const JsonNodeRow({
    super.key,
    required this.node,
    required this.provider,
    required this.index,
    required this.colorScheme,
    required this.styleCache,
    required this.isSelected,
    this.onTap,
    this.onToggleTap,
    this.onContextMenu,
  });

  @override
  State<JsonNodeRow> createState() => _JsonNodeRowState();
}

class _JsonNodeRowState extends State<JsonNodeRow> {
  DateTime? _lastTap;
  static const doubleTapDelay = Duration(milliseconds: 250);

  @override
  Widget build(BuildContext context) {
    final isEven = widget.index % 2 == 0;
    final isSearchMatch = widget.provider.isSearchMatch(widget.node.path);
    final isCurrentResult = widget.provider.isCurrentSearchResult(widget.node.path);
    final isCollapsible = widget.node.isCollapsible;
    final backgroundColor = _getBackgroundColor(isEven, widget.isSelected, isSearchMatch, isCurrentResult);

    return ContextMenuRegion(
      onItemSelected: (item) => widget.onContextMenu != null ? widget.onContextMenu!(item.title, widget.node) : null,
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
        if (isCollapsible) MenuItem(title: widget.node.isExpanded ? 'Collapse' : 'Expand'),
      ],
      child: Listener(
        onPointerDown: _handlePointerDown,
        child: Container(
          height: 25,
          padding: EdgeInsets.only(
            left: (widget.node.depth * 16.0),
            right: 12.0,
            top: 3.0,
            bottom: 3.0,
          ),
          decoration: BoxDecoration(color: backgroundColor),
          child: Row(
            children: [
              SizedBox(width: (isCollapsible ? 8.0 : 30) + (widget.node.depth * 8.0)),
              _buildExpansionIcon(isCollapsible),
              if (widget.node.key != null) ...[
                Text(
                  '${widget.node.key}',
                  style: widget.styleCache.keyStyle.copyWith(color: widget.colorScheme.keyColor),
                ),
                Text(
                  ' : ',
                  style: widget.styleCache.colonStyle.copyWith(color: widget.colorScheme.keyColor),
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

  void _handlePointerDown(PointerDownEvent event) {
    final now = DateTime.now();

    if (_lastTap != null && now.difference(_lastTap!) < doubleTapDelay) {
      _lastTap = null;
      widget.onToggleTap!();
    } else {
      _lastTap = now;
      widget.onTap!();
    }
  }

  Color _getBackgroundColor(bool isEven, bool isSelected, bool isSearchMatch, bool isCurrentResult) {
    if (isSelected) return widget.colorScheme.currentResultColor;
    if (isCurrentResult) return widget.colorScheme.currentResultColor;
    if (isSearchMatch) return widget.colorScheme.searchMatchColor;
    return isEven ? widget.colorScheme.evenRowColor : widget.colorScheme.oddRowColor;
  }

  Widget _buildExpansionIcon(bool isCollapsible) {
    if (!isCollapsible) return const SizedBox.shrink();

    if (widget.node.children == null || widget.node.children!.isEmpty) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: widget.onToggleTap,
      child: Container(
        width: 14,
        height: 14,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400, width: 1),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Icon(
          widget.node.isExpanded ? Icons.remove : Icons.add,
          size: 10,
          color: widget.colorScheme.expansionButtonColor,
        ),
      ),
    );
  }

  Widget _buildValueWidget() {
    final style = widget.styleCache.baseStyle.copyWith(
      color: widget.colorScheme.getValueColor(widget.node.type),
    );

    switch (widget.node.type) {
      case JsonNodeType.object:
        final objectMap = widget.node.value as Map<String, dynamic>;
        return Text(
          widget.node.isExpanded ? '{' : '{ ${objectMap.length} ${objectMap.length == 1 ? 'item' : 'items'} }',
          style: style.copyWith(fontWeight: FontWeight.w500),
        );

      case JsonNodeType.array:
        final arrayList = widget.node.value as List;
        return Text(
          widget.node.isExpanded ? '[' : '[ ${arrayList.length} ${arrayList.length == 1 ? 'item' : 'items'} ]',
          style: style.copyWith(fontWeight: FontWeight.w500),
        );

      case JsonNodeType.string:
        return Text(
          '"${widget.node.value}"',
          style: style,
          overflow: TextOverflow.ellipsis,
        );

      case JsonNodeType.number:
        return Text(
          widget.node.value.toString(),
          style: style.copyWith(fontWeight: FontWeight.w500),
        );

      case JsonNodeType.boolean:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Text(
            widget.node.value.toString(),
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
    final typeColor = widget.colorScheme.getTypeColor(widget.node.type);
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
    switch (widget.node.type) {
      case JsonNodeType.object:
        final objectMap = widget.node.value as Map<String, dynamic>;
        return 'Object (${objectMap.length})';
      case JsonNodeType.array:
        final arrayList = widget.node.value as List;
        return 'Array (${arrayList.length})';
      case JsonNodeType.string:
        return 'String';
      case JsonNodeType.number:
        return widget.node.value is int ? 'Integer' : 'Number';
      case JsonNodeType.boolean:
        return 'Boolean';
      case JsonNodeType.nullValue:
        return 'Null';
    }
  }
}
