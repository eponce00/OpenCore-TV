import 'package:opencore_tv/providers/settings_service.dart';
import 'package:opencore_tv/providers/apps_service.dart';
import 'package:opencore_tv/widgets/settings/focusable_settings_tile.dart';
import 'package:opencore_tv/widgets/settings/input_detail_page.dart';
import 'package:opencore_tv/widgets/settings/settings_page_layout.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class InputSettingsPage extends StatelessWidget {
  static const String routeName = "input_settings_panel";

  const InputSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final inputs = OpenCoreInputConfig.inputsFor(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SettingsPageHeader(
          title: "Inputs",
          subtitle: "Rename HDMI and tuner tiles, then choose their icons.",
        ),
        Expanded(
          child: ListView.builder(
            itemCount: inputs.length,
            itemBuilder: (context, index) {
              final input = inputs[index];
              final label = settings.inputLabel(
                input.packageName,
                input.fallbackLabel,
              );
              final icon = settings.inputIcon(input.packageName);

              return FocusableSettingsTile(
                autofocus: index == 0,
                leading: Icon(OpenCoreInputConfig.iconData(icon)),
                title: SettingsTileText(
                  title: label,
                  subtitle: input.fallbackLabel,
                ),
                trailing: const Icon(Icons.chevron_right),
                onPressed: () => Navigator.of(context).pushNamed(
                  InputDetailPage.routeName,
                  arguments: input.packageName,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class OpenCoreInputInfo {
  final String packageName;
  final String fallbackLabel;

  const OpenCoreInputInfo(this.packageName, this.fallbackLabel);
}

class OpenCoreInputConfig {
  static const inputs = [
    OpenCoreInputInfo("opencore.input.hdmi1", "HDMI 1"),
    OpenCoreInputInfo("opencore.input.hdmi2", "HDMI 2"),
    OpenCoreInputInfo("opencore.input.hdmi3", "HDMI 3"),
    OpenCoreInputInfo("opencore.input.hdmi4", "HDMI 4"),
    OpenCoreInputInfo("opencore.input.antenna", "Antenna"),
    OpenCoreInputInfo("opencore.input.composite", "Composite"),
  ];

  static List<OpenCoreInputInfo> inputsFor(
    BuildContext context, {
    bool listen = true,
  }) {
    try {
      final apps =
          Provider.of<AppsService>(context, listen: listen).applications;
      final discovered = apps
          .where((app) => app.packageName.startsWith("opencore.input."))
          .map((app) => OpenCoreInputInfo(app.packageName, app.name))
          .toList(growable: false);
      if (discovered.isNotEmpty) return discovered;
    } on ProviderNotFoundException {
      return inputs;
    }
    return const [];
  }

  static const labelPresets = [
    "HDMI 1",
    "HDMI 2",
    "HDMI 3",
    "HDMI 4",
    "PlayStation",
    "Xbox",
    "Nintendo Switch",
    "Gaming PC",
    "Apple TV",
    "Cable Box",
    "Blu-ray",
    "Receiver",
    "Antenna",
    "Composite",
  ];

  static const iconPresets = [
    "tv",
    "game",
    "switch",
    "movie",
    "computer",
    "streaming",
    "antenna",
    "camera",
    "receiver",
  ];

  static IconData iconData(String icon) {
    return switch (icon) {
      "game" => Icons.sports_esports_outlined,
      "switch" => Icons.videogame_asset_outlined,
      "movie" => Icons.movie_outlined,
      "computer" => Icons.computer_outlined,
      "streaming" => Icons.smart_display_outlined,
      "antenna" => Icons.settings_input_antenna,
      "camera" => Icons.videocam_outlined,
      "receiver" => Icons.speaker_group_outlined,
      _ => Icons.tv_outlined,
    };
  }
}
