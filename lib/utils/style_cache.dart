import 'package:flutter/painting.dart';

/// Cached text styles for the JSON tree. A monospace stack with sensible
/// fallbacks keeps the tree visually identical (and legible) on macOS,
/// Windows and other platforms.
class StyleCache {
  late TextStyle baseStyle;
  late TextStyle keyStyle;
  late TextStyle colonStyle;
  late TextStyle typeLabelStyle;

  static const _monospaceFallback = [
    'Menlo',
    'Cascadia Mono',
    'Consolas',
    'Courier New',
    'monospace',
  ];

  void updateStyles() {
    baseStyle = const TextStyle(
      fontFamily: 'SF Mono',
      fontFamilyFallback: _monospaceFallback,
      fontSize: 12,
      height: 1.3,
    );

    keyStyle = baseStyle.copyWith(
      fontWeight: FontWeight.w600,
    );

    colonStyle = baseStyle;

    typeLabelStyle = const TextStyle(
      fontFamily: '.SF Pro Text',
      fontSize: 10.5,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
    );
  }
}
