import 'package:flutter/material.dart';
import 'package:opencore_tv/providers/ambient_light_service.dart';
import 'package:opencore_tv/providers/appearance_service.dart';
import 'package:opencore_tv/providers/settings_service.dart';
import 'package:opencore_tv/providers/weather_service.dart';
import 'package:opencore_tv/theme/opencore_theme.dart';
import 'package:opencore_tv/widgets/settings/focusable_settings_tile.dart';
import 'package:opencore_tv/widgets/settings/settings_page_layout.dart';
import 'package:provider/provider.dart';

class WallpaperModePage extends StatelessWidget {
  static const String routeName = "wallpaper_mode_panel";

  const WallpaperModePage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final appearance = context.watch<AppearanceService>();
    final ambient = context.watch<AmbientLightService>();
    final weather = context.watch<WeatherService>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SettingsPageHeader(
          title: "Light / Dark",
          subtitle: "Choose how OpenCore switches the UI and wallpapers.",
        ),
        Expanded(
          child: ListView(
            children: [
              const SettingsSectionLabel("Current"),
              FocusableSettingsTile(
                leading: const Icon(Icons.contrast_outlined),
                title: SettingsTileText(
                  title: appearance.isLight ? "Light active" : "Dark active",
                  subtitle: appearance.statusLabel,
                ),
              ),
              const SettingsSectionLabel("Manual"),
              _modeTile(
                context,
                settings,
                autofocus: true,
                value: APPEARANCE_MODE_DARK,
                icon: Icons.dark_mode_outlined,
                title: "Dark",
                subtitle: "Always use dark UI and dark wallpapers.",
              ),
              _modeTile(
                context,
                settings,
                value: APPEARANCE_MODE_LIGHT,
                icon: Icons.light_mode_outlined,
                title: "Light",
                subtitle: "Always use light UI and light wallpapers.",
              ),
              const SettingsSectionLabel("Automatic"),
              _modeTile(
                context,
                settings,
                value: APPEARANCE_MODE_AUTO_HYBRID,
                icon: Icons.auto_awesome_outlined,
                title: "Hybrid",
                subtitle: ambient.available
                    ? "Uses ${ambient.sensorName}; sunrise/sunset if sensor stops."
                    : "Sensor unavailable; using sunrise/sunset.",
              ),
              _modeTile(
                context,
                settings,
                value: APPEARANCE_MODE_AUTO_SENSOR,
                icon: Icons.sensors_outlined,
                title: "Room light sensor",
                subtitle: ambient.available
                    ? "${ambient.lux?.toStringAsFixed(1) ?? "--"} lux from ${ambient.sensorName}"
                    : "No light sensor available on this TV.",
              ),
              _modeTile(
                context,
                settings,
                value: APPEARANCE_MODE_AUTO_SUN,
                icon: Icons.wb_twilight_outlined,
                title: "Sunrise / sunset",
                subtitle: _sunStatus(weather),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _modeTile(
    BuildContext context,
    SettingsService settings, {
    required String value,
    required IconData icon,
    required String title,
    required String subtitle,
    bool autofocus = false,
  }) {
    return FocusableSettingsTile(
      autofocus: autofocus,
      leading: Icon(icon),
      title: SettingsTileText(title: title, subtitle: subtitle),
      trailing: settings.appearanceMode == value
          ? Icon(Icons.check, color: context.openCoreAccentMuted)
          : null,
      onPressed: () => settings.setAppearanceMode(value),
    );
  }

  String _sunStatus(WeatherService weather) {
    final sunrise = weather.todaySunrise;
    final sunset = weather.todaySunset;
    if (sunrise == null || sunset == null) {
      return "Uses 6 AM / 6 PM until weather sunrise data is available.";
    }
    return "Sunrise ${_time(sunrise)} / sunset ${_time(sunset)}.";
  }

  String _time(DateTime time) {
    final hour =
        time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, "0");
    final suffix = time.hour >= 12 ? "PM" : "AM";
    return "$hour:$minute $suffix";
  }
}
