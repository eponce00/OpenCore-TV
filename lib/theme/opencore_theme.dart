import 'package:flutter/material.dart';

@immutable
class OpenCoreThemeColors extends ThemeExtension<OpenCoreThemeColors> {
  final Color page;
  final Color panel;
  final Color elevated;
  final Color text;
  final Color mutedText;
  final Color faintText;
  final Color line;
  final Color focusFill;
  final Color focusText;
  final Color focusMutedText;
  final Color overlay;
  final Color cardScrim;
  final Color shadow;

  const OpenCoreThemeColors({
    required this.page,
    required this.panel,
    required this.elevated,
    required this.text,
    required this.mutedText,
    required this.faintText,
    required this.line,
    required this.focusFill,
    required this.focusText,
    required this.focusMutedText,
    required this.overlay,
    required this.cardScrim,
    required this.shadow,
  });

  static const dark = OpenCoreThemeColors(
    page: Color(0xFF000000),
    panel: Color(0xFF050505),
    elevated: Color(0xFF101114),
    text: Color(0xFFFFFFFF),
    mutedText: Color(0xB8FFFFFF),
    faintText: Color(0x80FFFFFF),
    line: Color(0x29FFFFFF),
    focusFill: Color(0xFFF4F4F4),
    focusText: Color(0xFF050505),
    focusMutedText: Color(0x99000000),
    overlay: Color(0xCC000000),
    cardScrim: Color(0x99000000),
    shadow: Color(0x99000000),
  );

  static const light = OpenCoreThemeColors(
    page: Color(0xFFF6F3EC),
    panel: Color(0xFFFFFCF6),
    elevated: Color(0xFFFFFFFF),
    text: Color(0xFF141414),
    mutedText: Color(0xB8000000),
    faintText: Color(0x80000000),
    line: Color(0x26000000),
    focusFill: Color(0xFFFFFFFF),
    focusText: Color(0xFF111111),
    focusMutedText: Color(0xB8000000),
    overlay: Color(0xDDF6F3EC),
    cardScrim: Color(0xDFFFFFFF),
    shadow: Color(0x26000000),
  );

  @override
  OpenCoreThemeColors copyWith({
    Color? page,
    Color? panel,
    Color? elevated,
    Color? text,
    Color? mutedText,
    Color? faintText,
    Color? line,
    Color? focusFill,
    Color? focusText,
    Color? focusMutedText,
    Color? overlay,
    Color? cardScrim,
    Color? shadow,
  }) {
    return OpenCoreThemeColors(
      page: page ?? this.page,
      panel: panel ?? this.panel,
      elevated: elevated ?? this.elevated,
      text: text ?? this.text,
      mutedText: mutedText ?? this.mutedText,
      faintText: faintText ?? this.faintText,
      line: line ?? this.line,
      focusFill: focusFill ?? this.focusFill,
      focusText: focusText ?? this.focusText,
      focusMutedText: focusMutedText ?? this.focusMutedText,
      overlay: overlay ?? this.overlay,
      cardScrim: cardScrim ?? this.cardScrim,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  OpenCoreThemeColors lerp(
      ThemeExtension<OpenCoreThemeColors>? other, double t) {
    if (other is! OpenCoreThemeColors) return this;
    return OpenCoreThemeColors(
      page: Color.lerp(page, other.page, t)!,
      panel: Color.lerp(panel, other.panel, t)!,
      elevated: Color.lerp(elevated, other.elevated, t)!,
      text: Color.lerp(text, other.text, t)!,
      mutedText: Color.lerp(mutedText, other.mutedText, t)!,
      faintText: Color.lerp(faintText, other.faintText, t)!,
      line: Color.lerp(line, other.line, t)!,
      focusFill: Color.lerp(focusFill, other.focusFill, t)!,
      focusText: Color.lerp(focusText, other.focusText, t)!,
      focusMutedText: Color.lerp(focusMutedText, other.focusMutedText, t)!,
      overlay: Color.lerp(overlay, other.overlay, t)!,
      cardScrim: Color.lerp(cardScrim, other.cardScrim, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}

extension OpenCoreThemeLookup on BuildContext {
  OpenCoreThemeColors get openCoreColors =>
      Theme.of(this).extension<OpenCoreThemeColors>() ??
      OpenCoreThemeColors.dark;
}
