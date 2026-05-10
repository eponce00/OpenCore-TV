import 'package:opencore_tv/providers/settings_service.dart';
import 'package:opencore_tv/widgets/rounded_switch_list_tile.dart';
import 'package:opencore_tv/widgets/settings/focusable_settings_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OpenCoreClockSettingsPage extends StatelessWidget {
  static const String routeName = "opencore_clock_settings_panel";

  const OpenCoreClockSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();

    return Column(
      children: [
        Text("OpenCore Clock", style: Theme.of(context).textTheme.titleLarge),
        const Divider(),
        Expanded(
          child: ListView(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Text("Home Clock",
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              _homeSizeTile(context, settings, "Small", "small"),
              _homeSizeTile(context, settings, "Medium", "medium"),
              _homeSizeTile(context, settings, "Large", "large"),
              _homeSizeTile(context, settings, "Huge", "huge"),
              RoundedSwitchListTile(
                title: const Text("Show time on Home"),
                secondary: const Icon(Icons.schedule),
                value: settings.showTimeInStatusBar,
                onChanged: settings.setShowTimeInStatusBar,
              ),
              RoundedSwitchListTile(
                title: const Text("Show date on Home"),
                secondary: const Icon(Icons.calendar_today_outlined),
                value: settings.showDateInStatusBar,
                onChanged: settings.setShowDateInStatusBar,
              ),
              const Divider(),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Text("Idle / Screensaver Clock",
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              _idleSizeTile(context, settings, "Medium", "medium"),
              _idleSizeTile(context, settings, "Large", "large"),
              _idleSizeTile(context, settings, "Huge", "huge"),
              RoundedSwitchListTile(
                title: const Text("Show date under clock"),
                secondary: const Icon(Icons.calendar_today_outlined),
                value: settings.idleClockShowDate,
                onChanged: settings.setIdleClockShowDate,
              ),
              RoundedSwitchListTile(
                title: const Text("Use 24-hour time"),
                secondary: const Icon(Icons.schedule),
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
      title: Text("$label home clock"),
      trailing: selected ? const Icon(Icons.check) : null,
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
      title: Text("$label idle clock"),
      trailing: selected ? const Icon(Icons.check) : null,
      onPressed: () => settings.setIdleClockSize(value),
    );
  }
}
