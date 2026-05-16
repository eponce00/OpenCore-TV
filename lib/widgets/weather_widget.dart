import 'package:opencore_tv/providers/weather_service.dart';
import 'package:opencore_tv/providers/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:opencore_tv/theme/opencore_theme.dart';
import 'package:provider/provider.dart';

class WeatherWidget extends StatelessWidget {
  final bool compact;
  final bool locationBelow;
  final FocusNode? focusNode;
  final VoidCallback? onFocusLeft;
  final VoidCallback? onFocusDown;

  const WeatherWidget(
      {super.key,
      this.compact = false,
      this.locationBelow = false,
      this.focusNode,
      this.onFocusLeft,
      this.onFocusDown});

  @override
  Widget build(BuildContext context) {
    final snapshot = context.select<WeatherService, WeatherSnapshot?>(
      (service) => service.snapshot,
    );
    final colors = context.openCoreColors;
    final accent = context.openCoreAccentMuted;
    final temp =
        snapshot == null ? "--" : snapshot.temperature.round().toString();
    final unit = snapshot?.unitSymbol ?? "";
    final condition = snapshot?.condition ?? "Weather loading";
    final location = context.select<SettingsService, String>(
      (settings) => settings.weatherLocationName,
    );

    final temperatureRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_weatherIconFor(snapshot?.icon),
            color: accent, size: compact ? 28 : 36),
        SizedBox(width: compact ? 10 : 14),
        Text(
          "$temp°$unit",
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -1,
              ),
        ),
      ],
    );

    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: colors.cardScrim,
        borderRadius: BorderRadius.circular(compact ? 14 : 18),
        border: Border.all(color: colors.line),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 18 : 24,
          vertical: compact ? 12 : 18,
        ),
        child: locationBelow && !compact
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  temperatureRow,
                  const SizedBox(height: 2),
                  Text(
                    location,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.mutedText,
                          fontSize: 12,
                          height: 1.0,
                        ),
                  ),
                ],
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  temperatureRow,
                  if (!compact) ...[
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          condition,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: colors.mutedText,
                                  ),
                        ),
                        Text(
                          location,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colors.faintText,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
      ),
    );

    if (focusNode == null) return card;

    return _FocusableWeatherCard(
      focusNode: focusNode!,
      onFocusLeft: onFocusLeft,
      onFocusDown: onFocusDown,
      child: card,
    );
  }
}

class _FocusableWeatherCard extends StatefulWidget {
  final FocusNode focusNode;
  final VoidCallback? onFocusLeft;
  final VoidCallback? onFocusDown;
  final Widget child;

  const _FocusableWeatherCard({
    required this.focusNode,
    required this.child,
    this.onFocusLeft,
    this.onFocusDown,
  });

  @override
  State<_FocusableWeatherCard> createState() => _FocusableWeatherCardState();
}

class _FocusableWeatherCardState extends State<_FocusableWeatherCard>
    with SingleTickerProviderStateMixin {
  bool _focused = false;
  late final AnimationController _highlightAnimation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  late final CurvedAnimation _highlightCurve =
      CurvedAnimation(parent: _highlightAnimation, curve: Curves.easeInOut);

  @override
  void dispose() {
    _highlightCurve.dispose();
    _highlightAnimation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.openCoreColors;
    final focusRing = context.openCoreFocusRing;
    final pulseEnabled = context.select<SettingsService, bool>(
      (settings) => settings.appHighlightAnimationEnabled,
    );
    _setHighlightAnimation(_focused && pulseEnabled);

    return Focus(
      focusNode: widget.focusNode,
      onFocusChange: (focused) => setState(() => _focused = focused),
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (event.logicalKey == LogicalKeyboardKey.select ||
            event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.gameButtonA) {
          showDialog(
            context: context,
            barrierColor: colors.overlay,
            builder: (_) => const _WeeklyForecastDialog(),
          );
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          widget.onFocusLeft?.call();
          return KeyEventResult.handled;
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
        onTap: () => showDialog(
          context: context,
          barrierColor: colors.overlay,
          builder: (_) => const _WeeklyForecastDialog(),
        ),
        borderRadius: BorderRadius.circular(18),
        child: AnimatedScale(
          scale: _focused ? 1.045 : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          child: AnimatedBuilder(
            animation: _highlightCurve,
            builder: (context, child) {
              final opacity = _focused
                  ? (pulseEnabled
                      ? 0.46 + (_highlightCurve.value * 0.22)
                      : 0.54)
                  : 0.0;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: focusRing.withOpacity(opacity),
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
                child: child,
              );
            },
            child: widget.child,
          ),
        ),
      ),
    );
  }

  void _setHighlightAnimation(bool active) {
    if (active && !_highlightAnimation.isAnimating) {
      _highlightAnimation.repeat(reverse: true);
    } else if (!active && _highlightAnimation.isAnimating) {
      _highlightAnimation.stop();
      _highlightAnimation.value = 0;
    }
  }
}

class _WeeklyForecastDialog extends StatefulWidget {
  const _WeeklyForecastDialog();

  @override
  State<_WeeklyForecastDialog> createState() => _WeeklyForecastDialogState();
}

class _WeeklyForecastDialogState extends State<_WeeklyForecastDialog> {
  late final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final location = context.select<SettingsService, String>(
      (settings) => settings.weatherLocationName,
    );
    final forecast = context.select<WeatherService, List<DailyWeatherForecast>>(
      (service) => service.forecast,
    );
    final colors = context.openCoreColors;

    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) Navigator.of(context).maybePop();
      },
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 96, vertical: 72),
        backgroundColor: colors.panel,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Weekly Forecast",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                location,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.mutedText,
                    ),
              ),
              const SizedBox(height: 22),
              if (forecast.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 22),
                  child: Text(
                    "Forecast loading",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                )
              else
                Row(
                  children: forecast.take(7).map((day) {
                    return Expanded(child: _ForecastDay(day: day));
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ForecastDay extends StatelessWidget {
  final DailyWeatherForecast day;

  const _ForecastDay({required this.day});

  @override
  Widget build(BuildContext context) {
    final isToday = DateUtils.isSameDay(day.date, DateTime.now());
    final dayLabel = isToday ? "Today" : DateFormat.E().format(day.date);
    final colors = context.openCoreColors;
    final accent = context.openCoreAccentMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.elevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.line),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                dayLabel,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              Icon(_weatherIconFor(day.icon), color: accent, size: 30),
              const SizedBox(height: 12),
              Text(
                "${day.highTemperature.round()}°",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                "${day.lowTemperature.round()}° ${day.unitSymbol}",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.mutedText,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _weatherIconFor(String? icon) {
  return switch (icon) {
    "sunny" => Icons.wb_sunny_outlined,
    "partly" => Icons.wb_cloudy_outlined,
    "fog" => Icons.foggy,
    "rain" => Icons.water_drop_outlined,
    "snow" => Icons.ac_unit,
    "storm" => Icons.thunderstorm_outlined,
    _ => Icons.cloud_outlined,
  };
}
