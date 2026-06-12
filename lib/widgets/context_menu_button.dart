import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:native_context_menu/native_context_menu.dart';
import '../utils/app_theme.dart';

///A custom ContextMenuRegion based on context_menu_region package that support left-click mouse event
class ContextMenuButton extends StatefulWidget {
  const ContextMenuButton({
    this.child,
    required this.menuItems,
    super.key,
    this.onItemSelected,
    this.onDismissed,
  });

  final Widget? child;
  final List<MenuItem> menuItems;
  final void Function(MenuItem item)? onItemSelected;
  final VoidCallback? onDismissed;

  @override
  ContextMenuButtonState createState() => ContextMenuButtonState();
}

class ContextMenuButtonState extends State<ContextMenuButton> {
  bool shouldReact = false;

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);

    Widget defaultChild = Container(
      width: 20,
      height: 20,
      color: Colors.transparent,
      child: Icon(
        Icons.more_vert_rounded,
        size: 18,
        color: AppTheme.textSecondary(isDark),
      ),
    );

    return Listener(
      onPointerDown: (e) {
        shouldReact = e.kind == PointerDeviceKind.mouse;
      },
      onPointerUp: (e) async {
        if (!shouldReact) return;

        shouldReact = false;

        final position = e.position;

        final selectedItem = await showContextMenu(
          ShowMenuArgs(
            MediaQuery.of(context).devicePixelRatio,
            position,
            widget.menuItems,
          ),
        );

        if (selectedItem != null) {
          widget.onItemSelected?.call(selectedItem);
        } else {
          widget.onDismissed?.call();
        }
      },
      child: widget.child ?? defaultChild,
    );
  }
}
