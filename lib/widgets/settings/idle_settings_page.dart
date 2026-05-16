import 'package:opencore_tv/providers/settings_service.dart';
import 'package:opencore_tv/widgets/rounded_switch_list_tile.dart';
import 'package:opencore_tv/widgets/settings/opencore_clock_settings_page.dart';
import 'package:opencore_tv/widgets/settings/focusable_settings_tile.dart';
import 'package:opencore_tv/widgets/settings/idle_timeout_page.dart';
import 'package:opencore_tv/widgets/settings/settings_page_layout.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class IdleSettingsPage extends StatelessWidget {
  static const String routeName = "idle_settings_panel";

  const IdleSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SettingsPageHeader(
          title: "Idle",
          subtitle: "Control OpenCore's quiet screensaver-style home state.",
        ),
        Expanded(
          child: ListView(
            children: [
              RoundedSwitchListTile(
                autofocus: true,
                title: const SettingsTileText(
                  title: "Idle home",
                  subtitle: "Hide app rows after the TV is inactive.",
                ),
                secondary: const Icon(Icons.bedtime_outlined),
                value: settings.idleModeEnabled,
                onChanged: (value) => settings.setIdleModeEnabled(value),
              ),
              if (settings.idleModeEnabled)
                FocusableSettingsTile(
                  leading: const Icon(Icons.timer_outlined),
                  title: SettingsTileText(
                    title: "Start after ${settings.idleTimeoutMinutes} minutes",
                    subtitle: "Change the inactivity timer.",
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onPressed: () => Navigator.of(context)
                      .pushNamed(IdleTimeoutPage.routeName),
                ),
              FocusableSettingsTile(
                leading: const Icon(Icons.watch_later_outlined),
                title: const SettingsTileText(
                  title: "Clock",
                  subtitle: "Size, date, and 24-hour options.",
                ),
                trailing: const Icon(Icons.chevron_right),
                onPressed: () => Navigator.of(context)
                    .pushNamed(OpenCoreClockSettingsPage.routeName),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
