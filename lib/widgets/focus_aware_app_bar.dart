import 'package:flutter/services.dart';
import 'package:opencore_tv/widgets/network_info_panel.dart';
import 'package:opencore_tv/widgets/settings/settings_panel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:opencore_tv/theme/opencore_theme.dart';

import '../providers/settings_service.dart';
import 'daily_wifi_usage_widget.dart';
import 'date_time_widget.dart';
import 'network_widget.dart';

class FocusAwareAppBar extends StatefulWidget implements PreferredSizeWidget {
  final VoidCallback? onFocusWeather;
  final VoidCallback? onFocusDockEnd;

  const FocusAwareAppBar({
    Key? key,
    this.onFocusWeather,
    this.onFocusDockEnd,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return FocusAwareAppBarState();
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}

class FocusAwareAppBarState extends State<FocusAwareAppBar> {
  bool focused = false;
  late FocusNode _settingsFocusNode;
  late FocusNode _networkFocusNode;

  @override
  void initState() {
    super.initState();
    _settingsFocusNode = FocusNode();
    _networkFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _settingsFocusNode.dispose();
    _networkFocusNode.dispose();
    super.dispose();
  }

  void focusSettings() {
    _settingsFocusNode.requestFocus();
  }

  void focusNetwork() {
    if (_networkFocusNode.context != null) {
      _networkFocusNode.requestFocus();
    } else {
      focusSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Selector<SettingsService, bool>(
      selector: (_, settings) => settings.autoHideAppBarEnabled,
      builder: (context, autoHide, widget) {
        if (autoHide) {
          return Focus(
              canRequestFocus: false,
              child: AnimatedContainer(
                  curve: Curves.decelerate,
                  duration: Duration(milliseconds: 150),
                  height: focused ? kToolbarHeight : 0,
                  child: widget!),
              onFocusChange: (hasFocus) {
                this.setState(() {
                  focused = hasFocus;
                });
              });
        }

        return widget!;
      },
      child: RepaintBoundary(
        child: _OpenCoreAppBar(
          onFocusWeather: widget.onFocusWeather,
          onFocusDockEnd: widget.onFocusDockEnd,
        ),
      ),
    );
  }
}

class _OpenCoreAppBar extends StatelessWidget {
  final VoidCallback? onFocusWeather;
  final VoidCallback? onFocusDockEnd;

  const _OpenCoreAppBar({this.onFocusWeather, this.onFocusDockEnd});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _FocusableIconButton(
            icon: Icons.settings_outlined,
            focusNode: context
                .findAncestorStateOfType<FocusAwareAppBarState>()
                ?._settingsFocusNode,
            onFocusRight: () {
              final state =
                  context.findAncestorStateOfType<FocusAwareAppBarState>();
              if (state?._networkFocusNode.context != null) {
                state?._networkFocusNode.requestFocus();
              } else {
                onFocusWeather?.call();
              }
            },
            onFocusDown: onFocusDockEnd,
            onPressed: () => showDialog(
                context: context, builder: (_) => const SettingsPanel()),
          ),
          const SizedBox(width: 16),
          Selector<SettingsService, bool>(
            selector: (_, settings) => settings.showNetworkIndicatorInStatusBar,
            builder: (context, showNetwork, _) => showNetwork
                ? Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _FocusableNetworkWidget(
                      focusNode: context
                          .findAncestorStateOfType<FocusAwareAppBarState>()
                          ?._networkFocusNode,
                      onFocusLeft: () => context
                          .findAncestorStateOfType<FocusAwareAppBarState>()
                          ?.focusSettings(),
                      onFocusRight: onFocusWeather,
                      onFocusDown: onFocusDockEnd,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          Selector<SettingsService, bool>(
            selector: (_, settings) => settings.showWifiWidgetInStatusBar,
            builder: (context, showWifi, _) => showWifi
                ? const DailyWifiUsageWidget()
                : const SizedBox.shrink(),
          ),
        ],
      ),
      actions: const [
        Padding(
          padding: EdgeInsets.only(left: 16, right: 32),
          child: _HomeClock(),
        ),
      ],
    );
  }
}

class _HomeClock extends StatelessWidget {
  const _HomeClock();

  @override
  Widget build(BuildContext context) {
    return Selector<
        SettingsService,
        ({
          bool showDate,
          bool showTime,
          String dateFormat,
          String timeFormat,
          String size,
        })>(
      selector: (context, service) => (
        showDate: service.showDateInStatusBar,
        showTime: service.showTimeInStatusBar,
        dateFormat: service.dateFormat,
        timeFormat: service.timeFormat,
        size: service.homeClockSize,
      ),
      builder: (context, settings, _) {
        final fontSize = switch (settings.size) {
          "small" => 20.0,
          "large" => 28.0,
          "huge" => 34.0,
          _ => 24.0,
        };
        final textStyle = TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w400,
          color: context.openCoreColors.text,
        );

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (settings.showDate)
              DateTimeWidget(
                settings.dateFormat,
                key: const Key("statusbar_date"),
                updateInterval: const Duration(minutes: 1),
                textStyle: textStyle.copyWith(fontSize: fontSize * 0.72),
              ),
            if (settings.showDate && settings.showTime)
              SizedBox(width: fontSize * 0.55),
            if (settings.showTime)
              DateTimeWidget(
                settings.timeFormat,
                key: const Key("statusbar_clock"),
                updateInterval: const Duration(minutes: 1),
                textStyle: textStyle.copyWith(fontWeight: FontWeight.bold),
              ),
          ],
        );
      },
    );
  }
}

/// Reusable focusable icon button with consistent outline focus indicator
class _FocusableIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final FocusNode? focusNode;
  final VoidCallback? onFocusRight;
  final VoidCallback? onFocusLeft;
  final VoidCallback? onFocusDown;

  const _FocusableIconButton(
      {required this.icon,
      required this.onPressed,
      this.focusNode,
      this.onFocusRight,
      this.onFocusLeft,
      this.onFocusDown});

  @override
  State<_FocusableIconButton> createState() => _FocusableIconButtonState();
}

class _FocusableIconButtonState extends State<_FocusableIconButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.openCoreColors;
    final focusRing = context.openCoreFocusRing;
    final idleIconColor = _statusIconColor(context);
    return Actions(
      actions: <Type, Action<Intent>>{
        ActivateIntent:
            CallbackAction<ActivateIntent>(onInvoke: (_) => widget.onPressed()),
        ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
            onInvoke: (_) => widget.onPressed()),
      },
      child: Focus(
        focusNode: widget.focusNode,
        onFocusChange: (hasFocus) => setState(() => _focused = hasFocus),
        onKeyEvent: (_, event) {
          if (event is! KeyDownEvent) return KeyEventResult.ignored;
          if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            widget.onFocusRight?.call();
            return widget.onFocusRight == null
                ? KeyEventResult.ignored
                : KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            widget.onFocusLeft?.call();
            return widget.onFocusLeft == null
                ? KeyEventResult.ignored
                : KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            widget.onFocusDown?.call();
            return widget.onFocusDown == null
                ? KeyEventResult.ignored
                : KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: InkWell(
          onTap: widget.onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: _focused ? colors.focusFill : Colors.transparent,
              border: _focused ? Border.all(color: focusRing, width: 1) : null,
              boxShadow: [
                if (_focused)
                  BoxShadow(
                    color: colors.shadow,
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Icon(
              widget.icon,
              color: _focused ? colors.focusText : idleIconColor,
              shadows: _statusIconShadows(context),
            ),
          ),
        ),
      ),
    );
  }
}

/// Network widget with consistent focus indicator
class _FocusableNetworkWidget extends StatefulWidget {
  final FocusNode? focusNode;
  final VoidCallback? onFocusLeft;
  final VoidCallback? onFocusRight;
  final VoidCallback? onFocusDown;

  const _FocusableNetworkWidget({
    this.focusNode,
    this.onFocusLeft,
    this.onFocusRight,
    this.onFocusDown,
  });

  @override
  State<_FocusableNetworkWidget> createState() =>
      _FocusableNetworkWidgetState();
}

class _FocusableNetworkWidgetState extends State<_FocusableNetworkWidget> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.openCoreColors;
    final focusRing = context.openCoreFocusRing;
    final idleIconColor = _statusIconColor(context);
    return Focus(
      focusNode: widget.focusNode,
      onFocusChange: (hasFocus) => setState(() => _focused = hasFocus),
      onKeyEvent: (_, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (event.logicalKey == LogicalKeyboardKey.select ||
            event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.gameButtonA) {
          _showNetworkPanel();
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          widget.onFocusRight?.call();
          return widget.onFocusRight == null
              ? KeyEventResult.ignored
              : KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          widget.onFocusLeft?.call();
          return widget.onFocusLeft == null
              ? KeyEventResult.ignored
              : KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          widget.onFocusDown?.call();
          return widget.onFocusDown == null
              ? KeyEventResult.ignored
              : KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: _focused ? colors.focusFill : Colors.transparent,
          border: _focused ? Border.all(color: focusRing, width: 1) : null,
          boxShadow: [
            if (_focused)
              BoxShadow(
                color: colors.shadow,
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: NetworkWidget(
          iconColorOverride: _focused ? colors.focusText : idleIconColor,
        ),
      ),
    );
  }

  void _showNetworkPanel() {
    showDialog(
      context: context,
      builder: (_) => const NetworkInfoPanel(),
    );
  }
}

Color _statusIconColor(BuildContext context) {
  final isLight = Theme.of(context).brightness == Brightness.light;
  return isLight ? const Color(0xE6000000) : const Color(0xF2FFFFFF);
}

List<Shadow> _statusIconShadows(BuildContext context) {
  final isLight = Theme.of(context).brightness == Brightness.light;
  return isLight
      ? const [
          Shadow(color: Color(0x66FFFFFF), offset: Offset(0, 1), blurRadius: 8),
          Shadow(color: Color(0x33000000), offset: Offset(0, 2), blurRadius: 6),
        ]
      : const [
          Shadow(color: Color(0xCC000000), offset: Offset(0, 2), blurRadius: 8),
        ];
}
