import 'package:flutter/painting.dart';

class StyleCache {
  late TextStyle baseStyle;
  late TextStyle keyStyle;
  late TextStyle colonStyle;

  void updateStyles() {
    baseStyle = const TextStyle(
      fontFamily: 'SF Mono',
      fontSize: 11,
    );

    keyStyle = baseStyle.copyWith(
      fontWeight: FontWeight.w600,
      fontSize: 11,
    );

    colonStyle = baseStyle.copyWith(
      fontSize: 11,
    );
  }
}
