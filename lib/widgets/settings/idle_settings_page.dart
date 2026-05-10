import 'package:opencore_tv/providers/settings_service.dart';
import 'package:opencore_tv/widgets/rounded_switch_list_tile.dart';
import 'package:opencore_tv/widgets/settings/opencore_clock_settings_page.dart';
import 'package:opencore_tv/widgets/settings/focusable_settings_tile.dart';
import 'package:opencore_tv/widgets/settings/idle_timeout_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class IdleSettingsPage extends StatelessWidget {
  static const String routeName = "idle_settings_panel";

  const IdleSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();

    return Column(
      children: [
        Text("Idle Mode", style: Theme.of(context).textTheme.titleLarge),
        const Divider(),
        RoundedSwitchListTile(
          title: const Text("Enable Idle Home"),
          secondary: const Icon(Icons.nightlight_round),
          value: settings.idleModeEnabled,
          onChanged: (value) => settings.setIdleModeEnabled(value),
        ),
        if (settings.idleModeEnabled)
          FocusableSettingsTile(
            autofocus: true,
            leading: const Icon(Icons.timer_outlined),
            title: Text("Start after ${settings.idleTimeoutMinutes} minutes"),
            trailing: const Icon(Icons.chevron_right),
            onPressed: () =>
                Navigator.of(context).pushNamed(IdleTimeoutPage.routeName),
          ),
        FocusableSettingsTile(
          leading: const Icon(Icons.watch_later_outlined),
          title: const Text("Clock"),
          trailing: const Icon(Icons.chevron_right),
          onPressed: () => Navigator.of(context)
              .pushNamed(OpenCoreClockSettingsPage.routeName),
        ),
        const Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            "When idle, OpenCore hides the app rows and shows a quiet clock plus weather over the current wallpaper. Any remote key or pointer movement wakes it.",
          ),
        ),
      ],
    );
  }
}
