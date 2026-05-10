import 'package:opencore_tv/providers/weather_service.dart';
import 'package:opencore_tv/providers/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class WeatherWidget extends StatelessWidget {
  final bool compact;
  final bool locationBelow;

  const WeatherWidget(
      {super.key, this.compact = false, this.locationBelow = false});

  @override
  Widget build(BuildContext context) {
    final snapshot = context.select<WeatherService, WeatherSnapshot?>(
      (service) => service.snapshot,
    );
    final accent = Theme.of(context).colorScheme.primary;
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
        Icon(_iconFor(snapshot?.icon), color: accent, size: compact ? 28 : 36),
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

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(compact ? 0.42 : 0.32),
        borderRadius: BorderRadius.circular(compact ? 24 : 32),
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
                          color: Colors.white.withOpacity(0.64),
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
                                    color: Colors.white.withOpacity(0.82),
                                  ),
                        ),
                        Text(
                          location,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withOpacity(0.58),
                                  ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  IconData _iconFor(String? icon) {
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
}
