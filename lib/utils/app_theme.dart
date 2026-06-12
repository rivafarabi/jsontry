import 'package:flutter/material.dart';
import 'package:jsontry/providers/app_provider.dart';
import 'package:provider/provider.dart';

/// Centralized design tokens and theming so every platform (macOS, Windows,
/// and others) renders the exact same look and feel using plain Material
/// widgets, with a desktop-first density and high-contrast text in both
/// light and dark mode.
class AppTheme {
  AppTheme._();

  // ---------------------------------------------------------------------
  // Brightness resolution
  // ---------------------------------------------------------------------

  /// Resolves whether the app should currently render in dark mode, taking
  /// the user's saved theme preference and the platform brightness into
  /// account.
  static bool isDark(BuildContext context) {
    final mode = context.watch<AppProvider>().themeMode;
    if (mode == ThemeMode.system) {
      return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    }
    return mode == ThemeMode.dark;
  }

  // ---------------------------------------------------------------------
  // Palette
  // ---------------------------------------------------------------------

  static const _lightBackground = Color(0xFFFFFFFF);
  static const _lightSurface = Color(0xFFF6F7F9);
  static const _lightSurfaceVariant = Color(0xFFEEF0F3);
  static const _lightBorder = Color(0xFFE2E5EA);
  static const _lightTextPrimary = Color(0xFF1A1D24);
  static const _lightTextSecondary = Color(0xFF676F7E);
  static const _lightTextTertiary = Color(0xFF9AA1AD);
  static const _lightAccent = Color(0xFF2563EB);
  static const _lightAccentSoft = Color(0xFFE8F0FE);
  static const _lightSelection = Color(0xFFDCE8FF);
  static const _lightMatch = Color(0xFFFDF1C7);
  static const _lightCurrentMatch = Color(0xFFFCE588);

  static const _darkBackground = Color(0xFF1A1C22);
  static const _darkSurface = Color(0xFF21232B);
  static const _darkSurfaceVariant = Color(0xFF282B34);
  static const _darkBorder = Color(0xFF383C47);
  static const _darkTextPrimary = Color(0xFFEDEEF2);
  static const _darkTextSecondary = Color(0xFFA4ABB8);
  static const _darkTextTertiary = Color(0xFF767D8A);
  static const _darkAccent = Color(0xFF6CA0FF);
  static const _darkAccentSoft = Color(0xFF293349);
  static const _darkSelection = Color(0xFF2C3C58);
  static const _darkMatch = Color(0xFF4A3C18);
  static const _darkCurrentMatch = Color(0xFF6B5520);

  static const danger = Color(0xFFE5484D);

  /// High-contrast green used for positive/info status chips.
  static Color statusSuccess(bool isDark) => isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D);

  /// High-contrast amber used for warning/timing status chips.
  static Color statusWarning(bool isDark) => isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309);

  /// Page / window background.
  static Color background(bool isDark) => isDark ? _darkBackground : _lightBackground;

  /// Panels such as the search bar and status bar.
  static Color surface(bool isDark) => isDark ? _darkSurface : _lightSurface;

  /// Subtle fill used for alternating rows, hover states, chips.
  static Color surfaceVariant(bool isDark) => isDark ? _darkSurfaceVariant : _lightSurfaceVariant;

  /// Hairline borders and dividers.
  static Color border(bool isDark) => isDark ? _darkBorder : _lightBorder;

  /// Primary, high-contrast text color.
  static Color textPrimary(bool isDark) => isDark ? _darkTextPrimary : _lightTextPrimary;

  /// Secondary text such as labels and placeholders.
  static Color textSecondary(bool isDark) => isDark ? _darkTextSecondary : _lightTextSecondary;

  /// Tertiary text/icons such as disabled or decorative glyphs.
  static Color textTertiary(bool isDark) => isDark ? _darkTextTertiary : _lightTextTertiary;

  /// Primary accent color used for links, focus rings and highlights.
  static Color accent(bool isDark) => isDark ? _darkAccent : _lightAccent;

  /// Soft accent fill, e.g. badges and hover backgrounds.
  static Color accentSoft(bool isDark) => isDark ? _darkAccentSoft : _lightAccentSoft;

  /// Background for the currently selected row.
  static Color selection(bool isDark) => isDark ? _darkSelection : _lightSelection;

  /// Background for non-active search matches.
  static Color searchMatch(bool isDark) => isDark ? _darkMatch : _lightMatch;

  /// Background for the active/current search match.
  static Color currentSearchMatch(bool isDark) => isDark ? _darkCurrentMatch : _lightCurrentMatch;

  // ---------------------------------------------------------------------
  // ThemeData
  // ---------------------------------------------------------------------

  static ThemeData themeData(bool isDark) {
    final brightness = isDark ? Brightness.dark : Brightness.light;
    final accentColor = accent(isDark);
    final backgroundColor = background(isDark);
    final surfaceColor = surface(isDark);
    final borderColor = border(isDark);
    final primaryText = textPrimary(isDark);
    final secondaryText = textSecondary(isDark);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: accentColor,
      brightness: brightness,
    ).copyWith(
      primary: accentColor,
      onPrimary: isDark ? Colors.black : Colors.white,
      surface: backgroundColor,
      onSurface: primaryText,
      surfaceContainerHighest: surfaceColor,
      outline: borderColor,
      outlineVariant: borderColor,
      error: danger,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: backgroundColor,
      canvasColor: backgroundColor,
      visualDensity: VisualDensity.compact,
      fontFamily: '.SF Pro Text',
      textTheme: ThemeData(brightness: brightness).textTheme.apply(
            bodyColor: primaryText,
            displayColor: primaryText,
          ),
      iconTheme: IconThemeData(color: secondaryText, size: 18),
      dividerTheme: DividerThemeData(color: borderColor, thickness: 1, space: 1),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? _darkSurfaceVariant : _lightTextPrimary,
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: TextStyle(
          color: isDark ? primaryText : Colors.white,
          fontSize: 12,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        titleTextStyle: TextStyle(color: primaryText, fontSize: 16, fontWeight: FontWeight.w600),
        contentTextStyle: TextStyle(color: secondaryText, fontSize: 13),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: surfaceVariant(isDark),
        hintStyle: TextStyle(color: secondaryText, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: accentColor, width: 1.5),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: secondaryText,
          minimumSize: const Size(32, 32),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: isDark ? Colors.black : Colors.white,
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryText,
          side: BorderSide(color: borderColor),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentColor,
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(secondaryText.withValues(alpha: 0.35)),
        radius: const Radius.circular(8),
        thickness: const WidgetStatePropertyAll(8),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surfaceColor,
        surfaceTintColor: Colors.transparent,
        textStyle: TextStyle(color: primaryText, fontSize: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: borderColor),
        ),
      ),
    );
  }
}

/// Wraps [child] with a [Theme] + [Material] using [AppTheme.themeData] so
/// that plain Material widgets render consistently regardless of which
/// platform shell (MacosApp, FluentApp, MaterialApp) hosts them.
class AppThemeScope extends StatelessWidget {
  final Widget child;

  const AppThemeScope({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final dark = AppTheme.isDark(context);
    return Theme(
      data: AppTheme.themeData(dark),
      child: Material(
        type: MaterialType.transparency,
        child: child,
      ),
    );
  }
}
