import 'package:opencore_tv/providers/settings_service.dart';
import 'package:opencore_tv/widgets/settings/focusable_settings_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class IdleTimeoutPage extends StatelessWidget {
  static const String routeName = "idle_timeout_panel";

  const IdleTimeoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    const options = [1, 3, 5, 10, 15, 30];

    return Column(
      children: [
        Text("Idle Timeout", style: Theme.of(context).textTheme.titleLarge),
        const Divider(),
        Expanded(
          child: ListView(
            children: [
              for (final minutes in options)
                FocusableSettingsTile(
                  autofocus: minutes == settings.idleTimeoutMinutes,
                  leading: const Icon(Icons.timer_outlined),
                  title: Text("After $minutes minutes"),
                  trailing: minutes == settings.idleTimeoutMinutes
                      ? const Icon(Icons.check)
                      : null,
                  onPressed: () => settings.setIdleTimeoutMinutes(minutes),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
