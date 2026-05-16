import 'package:opencore_tv/providers/settings_service.dart';
import 'package:opencore_tv/theme/opencore_theme.dart';
import 'package:opencore_tv/widgets/settings/focusable_settings_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class WallpaperRotationFrequencyPage extends StatelessWidget {
  static const String routeName = "wallpaper_rotation_frequency_panel";

  const WallpaperRotationFrequencyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    const options = [5, 15, 30, 60, 120];

    return Column(
      children: [
        Text("Wallpaper Rotation",
            style: Theme.of(context).textTheme.titleLarge),
        const Divider(),
        Expanded(
          child: ListView(
            children: [
              for (final minutes in options)
                FocusableSettingsTile(
                  autofocus: minutes == settings.wallpaperRotationMinutes,
                  leading: const Icon(Icons.timer_outlined),
                  title: Text("Every $minutes minutes"),
                  trailing: minutes == settings.wallpaperRotationMinutes
                      ? Icon(Icons.check, color: context.openCoreAccentMuted)
                      : null,
                  onPressed: () =>
                      settings.setWallpaperRotationMinutes(minutes),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
