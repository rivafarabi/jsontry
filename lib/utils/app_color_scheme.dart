import 'package:flutter/material.dart';
import 'package:jsontry/models/json_node.dart';
import 'package:jsontry/utils/app_theme.dart';

/// Colors used by the JSON tree view. All values are derived from
/// [AppTheme] so the tree looks identical across platforms and remains
/// readable in both light and dark mode.
class AppColorScheme {
  late bool isDark;
  late Color backgroundColor;
  late Color dividerColor;
  late Color evenRowColor;
  late Color oddRowColor;
  late Color selectedColor;
  late Color searchMatchColor;
  late Color currentResultColor;
  late Color expansionButtonColor;
  late Color keyColor;

  void updateColors(BuildContext context) {
    isDark = AppTheme.isDark(context);

    backgroundColor = AppTheme.background(isDark);
    dividerColor = AppTheme.border(isDark);
    evenRowColor = AppTheme.surfaceVariant(isDark);
    oddRowColor = AppTheme.background(isDark);
    selectedColor = AppTheme.selection(isDark);
    searchMatchColor = AppTheme.searchMatch(isDark);
    currentResultColor = AppTheme.currentSearchMatch(isDark);
    expansionButtonColor = AppTheme.textSecondary(isDark);
    keyColor = AppTheme.accent(isDark);
  }

  Color getTypeColor(JsonNodeType type) {
    switch (type) {
      case JsonNodeType.object:
        return isDark ? const Color(0xFF7DB4FF) : const Color(0xFF1D5FC2);
      case JsonNodeType.array:
        return isDark ? const Color(0xFFB3BEFF) : const Color(0xFF4147C4);
      case JsonNodeType.string:
        return isDark ? const Color(0xFF59D88B) : const Color(0xFF1A8754);
      case JsonNodeType.number:
        return isDark ? const Color(0xFFFDBA74) : const Color(0xFFC2570C);
      case JsonNodeType.boolean:
        return isDark ? const Color(0xFFD9A8FF) : const Color(0xFF8E33C2);
      case JsonNodeType.nullValue:
        return AppTheme.textTertiary(isDark);
    }
  }

  /// Value text reuses the same semantic palette as the type badges so the
  /// tree reads as one coherent color system.
  Color getValueColor(JsonNodeType type) => getTypeColor(type);
}
