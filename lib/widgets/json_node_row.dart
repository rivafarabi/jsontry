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
          height: 26,
          padding: EdgeInsets.only(
            left: (widget.node.depth * 16.0),
            right: 12.0,
            top: 4.0,
            bottom: 4.0,
          ),
          decoration: BoxDecoration(color: backgroundColor),
          child: Row(
            children: [
              SizedBox(width: (isCollapsible ? 8.0 : 30) + (widget.node.depth * 8.0)),
              _buildExpansionIcon(isCollapsible),
              Expanded(
                  child: RichText(
                text: TextSpan(
                  children: <TextSpan>[
                    TextSpan(
                      text: '${widget.node.key}: ',
                      style: widget.styleCache.keyStyle.copyWith(color: widget.colorScheme.keyColor),
                    ),
                    _buildValueWidget(),
                  ],
                ),
              )),
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
    if (isSelected) return widget.colorScheme.selectedColor;
    if (isCurrentResult) return widget.colorScheme.currentResultColor;
    if (isSearchMatch) return widget.colorScheme.searchMatchColor;
    return isEven ? widget.colorScheme.evenRowColor : widget.colorScheme.oddRowColor;
  }

  Widget _buildExpansionIcon(bool isCollapsible) {
    if (!isCollapsible) return const SizedBox.shrink();

    if (widget.node.children == null || widget.node.children!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: GestureDetector(
        onTap: widget.onToggleTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 18,
          height: 18,
          child: Icon(
            widget.node.isExpanded ? Icons.expand_more : Icons.chevron_right,
            size: 18,
            color: widget.colorScheme.expansionButtonColor,
          ),
        ),
      ),
    );
  }

  TextSpan _buildValueWidget() {
    final style = widget.styleCache.baseStyle.copyWith(
      color: widget.colorScheme.getValueColor(widget.node.type),
    );

    switch (widget.node.type) {
      case JsonNodeType.object:
        final itemCount = widget.node.children?.length ?? 0;
        return TextSpan(
          text: widget.node.isExpanded ? '{' : '{ $itemCount ${itemCount == 1 ? 'item' : 'items'} }',
          style: style.copyWith(fontWeight: FontWeight.w500),
        );

      case JsonNodeType.array:
        final itemCount = widget.node.children?.length ?? 0;
        return TextSpan(
          text: widget.node.isExpanded ? '[' : '[ $itemCount ${itemCount == 1 ? 'item' : 'items'} ]',
          style: style.copyWith(fontWeight: FontWeight.w500),
        );

      case JsonNodeType.string:
        return TextSpan(
          text: '"${widget.node.value}"',
          style: style,
        );

      case JsonNodeType.number:
        return TextSpan(
          text: widget.node.value.toString(),
          style: style.copyWith(fontWeight: FontWeight.w500),
        );

      case JsonNodeType.boolean:
        return TextSpan(
          text: widget.node.value.toString(),
          style: style.copyWith(fontWeight: FontWeight.w600),
        );

      case JsonNodeType.nullValue:
        return TextSpan(
          text: 'null',
          style: style.copyWith(
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w500,
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
        color: typeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: typeColor.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Text(
        typeLabel,
        style: widget.styleCache.typeLabelStyle.copyWith(color: typeColor),
      ),
    );
  }

  String _getTypeLabel() {
    switch (widget.node.type) {
      case JsonNodeType.object:
        return 'Object (${widget.node.children?.length ?? 0})';
      case JsonNodeType.array:
        return 'Array (${widget.node.children?.length ?? 0})';
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
