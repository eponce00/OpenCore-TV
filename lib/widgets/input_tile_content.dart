import 'package:flutter/material.dart';
import 'package:opencore_tv/theme/opencore_theme.dart';

class InputTileContent extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool focused;
  final bool dense;

  const InputTileContent({
    super.key,
    required this.icon,
    required this.label,
    this.focused = false,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.openCoreColors;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final accent = _readableAccent(context);
    final contentColor = focused ? colors.focusText : colors.text;
    final iconColor = focused && !isLight ? colors.focusText : accent;
    final surfaceStart = focused ? colors.focusFill : colors.elevated;
    final surfaceEnd = focused ? colors.focusFill : colors.panel;
    final iconSize = dense ? 26.0 : 34.0;
    final iconWidth = dense ? 36.0 : 52.0;
    final gap = dense ? 7.0 : 12.0;
    final padding = dense
        ? const EdgeInsets.symmetric(horizontal: 8, vertical: 7)
        : const EdgeInsets.symmetric(horizontal: 18, vertical: 16);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [surfaceStart, surfaceEnd],
        ),
      ),
      child: Padding(
        padding: padding,
        child: Row(
          children: [
            SizedBox(
              width: iconWidth,
              child: Icon(icon, color: iconColor, size: iconSize),
            ),
            SizedBox(width: gap),
            Expanded(
              child: _FittedInputLabel(
                label: label,
                color: contentColor,
                maxFontSize: dense ? 12 : 17,
                minFontSize: dense ? 8 : 10,
                fontWeight: dense ? FontWeight.w600 : FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _readableAccent(BuildContext context) {
    final colors = context.openCoreColors;
    final accent = Theme.of(context).colorScheme.primary;
    if (Theme.of(context).brightness == Brightness.light &&
        accent.computeLuminance() > 0.72) {
      return colors.text;
    }
    return accent;
  }
}

class _FittedInputLabel extends StatelessWidget {
  final String label;
  final Color color;
  final double maxFontSize;
  final double minFontSize;
  final FontWeight fontWeight;

  const _FittedInputLabel({
    required this.label,
    required this.color,
    required this.maxFontSize,
    required this.minFontSize,
    required this.fontWeight,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          color: color,
          fontWeight: fontWeight,
          height: 1.04,
          letterSpacing: 0,
        );

    return LayoutBuilder(
      builder: (context, constraints) {
        final textStyle = (baseStyle ?? const TextStyle()).copyWith(
          fontSize: _bestFontSize(
            context: context,
            constraints: constraints,
            style: baseStyle ?? const TextStyle(),
          ),
        );

        return Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          softWrap: true,
          style: textStyle,
        );
      },
    );
  }

  double _bestFontSize({
    required BuildContext context,
    required BoxConstraints constraints,
    required TextStyle style,
  }) {
    if (!constraints.hasBoundedWidth || constraints.maxWidth <= 0) {
      return maxFontSize;
    }

    for (var size = maxFontSize; size >= minFontSize; size -= 0.5) {
      final painter = TextPainter(
        text: TextSpan(text: label, style: style.copyWith(fontSize: size)),
        maxLines: 2,
        textDirection: Directionality.of(context),
      )..layout(maxWidth: constraints.maxWidth);

      if (!painter.didExceedMaxLines &&
          painter.height <= constraints.maxHeight + 0.5) {
        return size;
      }
    }

    return minFontSize;
  }
}
