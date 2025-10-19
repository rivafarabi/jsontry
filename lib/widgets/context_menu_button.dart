import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:macos_ui/macos_ui.dart';
import 'package:native_context_menu/native_context_menu.dart';
import 'package:universal_platform/universal_platform.dart';

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
    late IconData iconData;
    late Color iconColor;

    if (UniversalPlatform.isMacOS) {
      bool isDark = MacosTheme.of(context).brightness == Brightness.dark;
      iconData = CupertinoIcons.ellipsis_vertical;
      iconColor = isDark ? CupertinoColors.systemGrey4 : CupertinoColors.black;
    } else if (UniversalPlatform.isWindows) {
      bool isDark = fluent.FluentTheme.of(context).brightness == Brightness.dark;
      iconData = fluent.FluentIcons.more_vertical;
      iconColor = isDark ? Colors.grey.shade800 : Colors.black;
    } else {
      bool isDark = Theme.of(context).brightness == Brightness.dark;
      iconData = Icons.more_vert;
      iconColor = isDark ? Colors.grey.shade800 : Colors.black;
    }

    Widget defaultChild = Container(
      width: 20,
      height: 20,
      color: Colors.transparent,
      child: Icon(
        iconData,
        size: 18,
        color: iconColor,
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
