/*
 * OpenCoreTV
 * Copyright (C) 2024 OpenCore TV Project
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

import 'package:flutter/material.dart';
import 'package:opencore_tv/theme/opencore_theme.dart';
import 'focusable_settings_tile.dart';
import 'brightness_settings_page.dart';
import 'date_time_format_page.dart';
import 'wifi_usage_period_page.dart';

class GeneralSettingsPage extends StatelessWidget {
  static const String routeName = "general_settings_panel";

  const GeneralSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.openCoreColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Device Tools', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          'OpenCore-owned controls for device behavior that belongs inside the launcher. Native Fire TV sections live in their own menu.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.mutedText,
                height: 1.25,
              ),
        ),
        const SizedBox(height: 12),
        const Divider(),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionLabel("Display"),
                FocusableSettingsTile(
                  autofocus: true,
                  leading: const Icon(Icons.brightness_6_outlined),
                  title: _TileText(
                    title: "Brightness Scheduler",
                    subtitle: "Optional day/night brightness automation",
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onPressed: () => Navigator.of(context)
                      .pushNamed(BrightnessSettingsPage.routeName),
                ),
                const SizedBox(height: 8),
                _SectionLabel("Date & Time"),
                FocusableSettingsTile(
                  leading: const Icon(Icons.schedule_outlined),
                  title: _TileText(
                    title: "Date & Time Format",
                    subtitle: "Choose the clock/date format OpenCore displays",
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onPressed: () => Navigator.of(context)
                      .pushNamed(DateTimeFormatPage.routeName),
                ),
                const SizedBox(height: 8),
                _SectionLabel("Network"),
                FocusableSettingsTile(
                  leading: const Icon(Icons.network_check_outlined),
                  title: _TileText(
                    title: "Network Usage Period",
                    subtitle: "Daily, weekly, or monthly usage window",
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onPressed: () => Navigator.of(context)
                      .pushNamed(WifiUsagePeriodPage.routeName),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    "Fire TV system settings are intentionally separate so this page stays limited to OpenCore controls.",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.faintText,
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final colors = context.openCoreColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.faintText,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
      ),
    );
  }
}

class _TileText extends StatelessWidget {
  final String title;
  final String subtitle;

  const _TileText({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final colors = context.openCoreColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 3),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.mutedText,
              ),
        ),
      ],
    );
  }
}
