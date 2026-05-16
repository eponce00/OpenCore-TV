import 'package:flutter/material.dart';
import 'package:opencore_tv/theme/opencore_theme.dart';

class FocusableSettingsTile extends StatefulWidget {
  final Widget title;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onPressed;
  final bool autofocus;

  const FocusableSettingsTile({
    Key? key,
    required this.title,
    this.leading,
    this.trailing,
    this.onPressed,
    this.autofocus = false,
  }) : super(key: key);

  @override
  State<FocusableSettingsTile> createState() => _FocusableSettingsTileState();
}

class _FocusableSettingsTileState extends State<FocusableSettingsTile> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.openCoreColors;
    final themedContext = Theme.of(context);
    final isLight = themedContext.brightness == Brightness.light;
    final contentColor = _focused ? colors.focusText : colors.text;
    final secondaryColor = _focused
        ? (isLight ? colors.mutedText : colors.focusMutedText)
        : colors.mutedText;
    final focusRing = context.openCoreFocusRing;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 0),
      child: RepaintBoundary(
        child: Actions(
          actions: <Type, Action<Intent>>{
            ActivateIntent: CallbackAction<ActivateIntent>(
                onInvoke: (_) => widget.onPressed?.call()),
            ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
                onInvoke: (_) => widget.onPressed?.call()),
          },
          child: Focus(
            autofocus: widget.autofocus,
            onFocusChange: (hasFocus) => setState(() => _focused = hasFocus),
            child: InkWell(
              onTap: widget.onPressed,
              borderRadius: BorderRadius.circular(18),
              focusColor: Colors.transparent,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                decoration: BoxDecoration(
                  // Shared settings rows invert on focus so every submenu matches the main control center.
                  color: _focused ? colors.focusFill : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _focused ? focusRing : Colors.transparent,
                    width: 1,
                  ),
                  boxShadow: [
                    if (_focused)
                      BoxShadow(
                        color: colors.shadow,
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                  ],
                ),
                child: Theme(
                  data: themedContext.copyWith(
                    iconTheme: IconThemeData(size: 18, color: secondaryColor),
                    textTheme: themedContext.textTheme.apply(
                      bodyColor: contentColor,
                      displayColor: contentColor,
                    ),
                    switchTheme: themedContext.switchTheme.copyWith(
                      thumbColor: WidgetStateProperty.resolveWith((states) =>
                          states.contains(WidgetState.selected)
                              ? contentColor
                              : secondaryColor),
                      trackColor: WidgetStateProperty.resolveWith((states) =>
                          states.contains(WidgetState.selected)
                              ? contentColor.withOpacity(0.28)
                              : secondaryColor.withOpacity(0.22)),
                    ),
                  ),
                  child: DefaultTextStyle.merge(
                    style: TextStyle(color: contentColor),
                    child: IconTheme(
                      data: IconThemeData(size: 18, color: secondaryColor),
                      child: Row(
                        children: [
                          if (widget.leading != null) ...[
                            widget.leading!,
                            const SizedBox(width: 10),
                          ],
                          Expanded(child: widget.title),
                          if (widget.trailing != null) ...[
                            const SizedBox(width: 10),
                            widget.trailing!,
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
