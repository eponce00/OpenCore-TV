import 'package:opencore_tv/providers/settings_service.dart';
import 'package:opencore_tv/theme/opencore_theme.dart';
import 'package:opencore_tv/widgets/rounded_switch_list_tile.dart';
import 'package:opencore_tv/widgets/settings/focusable_settings_tile.dart';
import 'package:opencore_tv/widgets/settings/settings_page_layout.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OpenCoreClockSettingsPage extends StatelessWidget {
  static const String routeName = "opencore_clock_settings_panel";

  const OpenCoreClockSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SettingsPageHeader(
          title: "Clock",
          subtitle: "Use one clock system for Home and Idle.",
        ),
        Expanded(
          child: ListView(
            children: [
              const SettingsSectionLabel("Home"),
              _homeSizeTile(context, settings, "Small", "small"),
              _homeSizeTile(context, settings, "Medium", "medium"),
              _homeSizeTile(context, settings, "Large", "large"),
              _homeSizeTile(context, settings, "Huge", "huge"),
              RoundedSwitchListTile(
                title: const SettingsTileText(
                  title: "Show time",
                  subtitle: "Keep the clock in the top controls.",
                ),
                secondary: const Icon(Icons.schedule_outlined),
                value: settings.showTimeInStatusBar,
                onChanged: settings.setShowTimeInStatusBar,
              ),
              RoundedSwitchListTile(
                title: const SettingsTileText(
                  title: "Show date",
                  subtitle: "Show the date near the Home clock.",
                ),
                secondary: const Icon(Icons.calendar_today_outlined),
                value: settings.showDateInStatusBar,
                onChanged: settings.setShowDateInStatusBar,
              ),
              const SettingsSectionLabel("Idle"),
              _idleSizeTile(context, settings, "Medium", "medium"),
              _idleSizeTile(context, settings, "Large", "large"),
              _idleSizeTile(context, settings, "Huge", "huge"),
              RoundedSwitchListTile(
                title: const SettingsTileText(
                  title: "Show date",
                  subtitle: "Show the date under the idle clock.",
                ),
                secondary: const Icon(Icons.calendar_today_outlined),
                value: settings.idleClockShowDate,
                onChanged: settings.setIdleClockShowDate,
              ),
              RoundedSwitchListTile(
                title: const SettingsTileText(
                  title: "24-hour time",
                  subtitle: "Use 18:30 instead of 6:30 PM.",
                ),
                secondary: const Icon(Icons.schedule_outlined),
                value: settings.idleClockUse24Hour,
                onChanged: settings.setIdleClockUse24Hour,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _homeSizeTile(
    BuildContext context,
    SettingsService settings,
    String label,
    String value,
  ) {
    final selected = settings.homeClockSize == value;
    return FocusableSettingsTile(
      autofocus: selected,
      leading: const Icon(Icons.home_outlined),
      title: SettingsTileText(
        title: "$label size",
        subtitle: "Home clock",
      ),
      trailing: selected
          ? Icon(Icons.check, color: context.openCoreAccentMuted)
          : null,
      onPressed: () => settings.setHomeClockSize(value),
    );
  }

  Widget _idleSizeTile(
    BuildContext context,
    SettingsService settings,
    String label,
    String value,
  ) {
    final selected = settings.idleClockSize == value;
    return FocusableSettingsTile(
      leading: const Icon(Icons.nightlight_round),
      title: SettingsTileText(
        title: "$label size",
        subtitle: "Idle clock",
      ),
      trailing: selected
          ? Icon(Icons.check, color: context.openCoreAccentMuted)
          : null,
      onPressed: () => settings.setIdleClockSize(value),
    );
  }
}
