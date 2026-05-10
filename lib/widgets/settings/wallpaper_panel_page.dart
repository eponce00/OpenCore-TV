/*
 * OpenCoreTV
 * Copyright (C) 2021  Étienne Fesser
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'package:opencore_tv/providers/settings_service.dart';
import 'package:opencore_tv/widgets/settings/focusable_settings_tile.dart';
import 'package:opencore_tv/widgets/settings/gradient_panel_page.dart';
import 'package:opencore_tv/widgets/settings/wallpaper_rotation_frequency_page.dart';
import 'package:opencore_tv/widgets/settings/wallpaper_library_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:opencore_tv/widgets/rounded_switch_list_tile.dart';

class WallpaperPanelPage extends StatelessWidget {
  static const String routeName = "wallpaper_panel";

  @override
  Widget build(BuildContext context) {
    AppLocalizations localizations = AppLocalizations.of(context)!;

    return Column(
      children: [
        Text(localizations.wallpaper,
            style: Theme.of(context).textTheme.titleLarge),
        Divider(),
        Consumer<SettingsService>(builder: (_, settings, __) {
          return RoundedSwitchListTile(
            title: Text(localizations.timeBasedWallpaper),
            secondary: Icon(Icons.access_time),
            value: settings.timeBasedWallpaperEnabled,
            onChanged: (value) => settings.setTimeBasedWallpaperEnabled(value),
          );
        }),
        Consumer<SettingsService>(
          builder: (_, settings, __) {
            return Column(
              children: [
                RoundedSwitchListTile(
                  title: const Text("Rotate Wallpaper"),
                  secondary: const Icon(Icons.autorenew),
                  value: settings.wallpaperRotationEnabled,
                  onChanged: (value) =>
                      settings.setWallpaperRotationEnabled(value),
                ),
                if (settings.wallpaperRotationEnabled)
                  FocusableSettingsTile(
                    leading: const Icon(Icons.timer_outlined),
                    title: Text(
                        "Every ${settings.wallpaperRotationMinutes} minutes"),
                    trailing: const Icon(Icons.chevron_right),
                    onPressed: () => Navigator.of(context)
                        .pushNamed(WallpaperRotationFrequencyPage.routeName),
                  ),
              ],
            );
          },
        ),
        Consumer<SettingsService>(builder: (_, settings, __) {
          return Column(
            children: [
              FocusableSettingsTile(
                autofocus: true,
                leading: Icon(Icons.photo_library_outlined),
                title: Text("Wallpaper Library",
                    style: Theme.of(context).textTheme.bodyMedium),
                onPressed: () => Navigator.of(context)
                    .pushNamed(WallpaperLibraryPage.routeName),
              ),
              FocusableSettingsTile(
                leading: Icon(Icons.gradient),
                title: Text(localizations.gradient,
                    style: Theme.of(context).textTheme.bodyMedium),
                onPressed: () => Navigator.of(context)
                    .pushNamed(GradientPanelPage.routeName),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Text(
                  settings.timeBasedWallpaperEnabled
                      ? "Time-based external wallpaper picking is disabled on this Fire TV. Use the built-in Wallpaper Library for now."
                      : "Use the built-in Wallpaper Library. External gallery/file picker actions are hidden because this Fire TV does not provide a compatible picker.",
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          );
        }),
      ],
    );
  }
}
