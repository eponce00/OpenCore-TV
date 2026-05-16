import 'package:opencore_tv/providers/apps_service.dart';
import 'package:opencore_tv/providers/settings_service.dart';
import 'package:opencore_tv/theme/opencore_theme.dart';
import 'package:opencore_tv/widgets/settings/focusable_settings_tile.dart';
import 'package:opencore_tv/widgets/settings/input_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class InputDetailPage extends StatelessWidget {
  static const String routeName = "input_detail_panel";

  final String packageName;

  const InputDetailPage({super.key, required this.packageName});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final label = settings.inputLabel(
      packageName,
      settings.defaultInputLabel(packageName),
    );
    final icon = settings.inputIcon(packageName);

    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.titleLarge),
        const Divider(),
        Expanded(
          child: ListView(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Text("Name Presets",
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              for (final preset in OpenCoreInputConfig.labelPresets)
                FocusableSettingsTile(
                  autofocus: preset == label,
                  leading: const Icon(Icons.drive_file_rename_outline),
                  title: Text(preset),
                  trailing: preset == label
                      ? Icon(Icons.check, color: context.openCoreAccentMuted)
                      : null,
                  onPressed: () async {
                    await settings.setInputLabel(packageName, preset);
                    if (context.mounted) {
                      context
                          .read<AppsService>()
                          .invalidateAppImage(packageName);
                    }
                  },
                ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                child: Text("Icon Presets",
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              for (final preset in OpenCoreInputConfig.iconPresets)
                FocusableSettingsTile(
                  leading: Icon(OpenCoreInputConfig.iconData(preset)),
                  title: Text(_iconLabel(preset)),
                  trailing: preset == icon
                      ? Icon(Icons.check, color: context.openCoreAccentMuted)
                      : null,
                  onPressed: () async {
                    await settings.setInputIcon(packageName, preset);
                    if (context.mounted) {
                      context
                          .read<AppsService>()
                          .invalidateAppImage(packageName);
                    }
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _iconLabel(String icon) {
    return switch (icon) {
      "game" => "Game Console",
      "switch" => "Nintendo Switch",
      "movie" => "Movie Player",
      "computer" => "Computer",
      "streaming" => "Streaming Box",
      "antenna" => "Antenna",
      "camera" => "Camera",
      "receiver" => "Receiver",
      _ => "TV",
    };
  }
}
