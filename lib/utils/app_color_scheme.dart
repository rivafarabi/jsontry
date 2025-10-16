import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:jsontry/models/json_node.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:universal_platform/universal_platform.dart';

class AppColorScheme {
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
    JsonNodeType.object: Color(0xFF2196F3),
    JsonNodeType.array: Color(0xFF3F51B5),
    JsonNodeType.string: Color(0xFF4CAF50),
    JsonNodeType.number: Color(0xFFFF9800),
    JsonNodeType.boolean: Color(0xFF9C27B0),
    JsonNodeType.nullValue: Color(0xFF757575),
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
