import 'package:flutter/material.dart';
import 'package:opencore_tv/providers/settings_service.dart';
import 'package:opencore_tv/providers/weather_service.dart';
import 'package:opencore_tv/theme/opencore_theme.dart';
import 'package:opencore_tv/widgets/date_time_widget.dart';
import 'package:provider/provider.dart';

class IdleOverlay extends StatelessWidget {
  const IdleOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final colors = context.openCoreColors;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final clockSize = switch (settings.idleClockSize) {
      "medium" => 56.0,
      "huge" => 92.0,
      _ => 74.0,
    };
    final clockFormat = settings.idleClockUse24Hour ? "HH:mm" : "h:mm a";

    return IgnorePointer(
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    colors.page.withOpacity(isLight ? 0.10 : 0.18),
                    colors.page.withOpacity(isLight ? 0.34 : 0.46),
                  ],
                  stops: const [0.42, 0.76, 1.0],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(56, 44, 56, 44),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DateTimeWidget(
                          clockFormat,
                          textStyle: _legibleTextStyle(
                            context,
                            Theme.of(context).textTheme.displayMedium,
                            fontSize: clockSize,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -2,
                          ),
                          animate: true,
                        ),
                        if (settings.idleClockShowDate) ...[
                          const SizedBox(height: 2),
                          DateTimeWidget(
                            "EEEE, MMMM d",
                            textStyle: _legibleTextStyle(
                              context,
                              Theme.of(context).textTheme.titleMedium,
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: colors.mutedText,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 32),
                  const _IdleWeather(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IdleWeather extends StatelessWidget {
  const _IdleWeather();

  @override
  Widget build(BuildContext context) {
    final snapshot = context.select<WeatherService, WeatherSnapshot?>(
      (service) => service.snapshot,
    );
    final location = context.select<SettingsService, String>(
      (settings) => settings.weatherLocationName,
    );
    final colors = context.openCoreColors;
    final accent = context.openCoreAccentMuted;
    final temp =
        snapshot == null ? "--" : snapshot.temperature.round().toString();
    final unit = snapshot?.unitSymbol ?? "";

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                _weatherIconFor(snapshot?.icon),
                color: accent,
                size: 32,
                shadows: _textShadows(context),
              ),
              const SizedBox(width: 12),
              Text(
                "$temp°$unit",
                style: _legibleTextStyle(
                  context,
                  Theme.of(context).textTheme.headlineSmall,
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            location,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _legibleTextStyle(
              context,
              Theme.of(context).textTheme.bodyMedium,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colors.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}

TextStyle _legibleTextStyle(
  BuildContext context,
  TextStyle? base, {
  double? fontSize,
  FontWeight? fontWeight,
  double? letterSpacing,
  Color? color,
}) {
  final colors = context.openCoreColors;
  return (base ?? const TextStyle()).copyWith(
    color: color ?? colors.text,
    fontSize: fontSize,
    fontWeight: fontWeight,
    letterSpacing: letterSpacing,
    shadows: _textShadows(context),
  );
}

List<Shadow> _textShadows(BuildContext context) {
  final isLight = Theme.of(context).brightness == Brightness.light;
  return isLight
      ? const [
          Shadow(color: Colors.white, offset: Offset(0, 1), blurRadius: 10),
          Shadow(color: Color(0x66000000), offset: Offset(0, 2), blurRadius: 8),
        ]
      : const [
          Shadow(
              color: Color(0xD9000000), offset: Offset(0, 2), blurRadius: 12),
          Shadow(
              color: Color(0x66000000), offset: Offset(0, 8), blurRadius: 24),
        ];
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
