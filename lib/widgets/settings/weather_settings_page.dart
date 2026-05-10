import 'package:opencore_tv/providers/settings_service.dart';
import 'package:opencore_tv/providers/weather_service.dart';
import 'package:opencore_tv/widgets/settings/focusable_settings_tile.dart';
import 'package:opencore_tv/widgets/settings/weather_location_search_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class WeatherSettingsPage extends StatelessWidget {
  static const String routeName = "weather_settings_panel";

  const WeatherSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();

    return Column(
      children: [
        Text("Weather", style: Theme.of(context).textTheme.titleLarge),
        const Divider(),
        Expanded(
          child: ListView(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Text(
                  "Units",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              _unitTile(context, settings, "Fahrenheit", "fahrenheit"),
              _unitTile(context, settings, "Celsius", "celsius"),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                child: Text(
                  "Location: ${settings.weatherLocationName}",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              FocusableSettingsTile(
                leading: const Icon(Icons.search),
                title: const Text("Search City / ZIP"),
                trailing: const Icon(Icons.chevron_right),
                onPressed: () => Navigator.of(context)
                    .pushNamed(WeatherLocationSearchPage.routeName),
              ),
              for (final location in _locations)
                FocusableSettingsTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: Text(location.name),
                  trailing: settings.weatherLocationName == location.name
                      ? const Icon(Icons.check)
                      : null,
                  onPressed: () async {
                    await settings.setWeatherLocation(
                      name: location.name,
                      latitude: location.latitude,
                      longitude: location.longitude,
                    );
                    if (context.mounted) {
                      context.read<WeatherService>().refresh(force: true);
                    }
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _unitTile(
    BuildContext context,
    SettingsService settings,
    String label,
    String value,
  ) {
    return FocusableSettingsTile(
      leading: const Icon(Icons.thermostat_outlined),
      title: Text(label),
      trailing: settings.weatherUnit == value ? const Icon(Icons.check) : null,
      onPressed: () async {
        await settings.setWeatherUnit(value);
        if (context.mounted) {
          context.read<WeatherService>().refresh(force: true);
        }
      },
    );
  }
}

class _WeatherLocation {
  final String name;
  final double latitude;
  final double longitude;

  const _WeatherLocation(this.name, this.latitude, this.longitude);
}

const _locations = [
  _WeatherLocation("Los Angeles", 34.0522, -118.2437),
  _WeatherLocation("Reno, Nevada", 39.5296, -119.8138),
  _WeatherLocation("New York", 40.7128, -74.0060),
  _WeatherLocation("Miami", 25.7617, -80.1918),
  _WeatherLocation("Chicago", 41.8781, -87.6298),
  _WeatherLocation("London", 51.5072, -0.1276),
];
