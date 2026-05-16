import 'package:opencore_tv/providers/settings_service.dart';
import 'package:opencore_tv/widgets/rounded_switch_list_tile.dart';
import 'package:opencore_tv/widgets/settings/settings_page_layout.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeDisplaySettingsPage extends StatelessWidget {
  static const String routeName = "home_display_panel";

  const HomeDisplaySettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SettingsService settingsService = Provider.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SettingsPageHeader(
          title: "Home Display",
          subtitle: "Tune what stays visible on the launcher home screen.",
        ),
        Expanded(
          child: ListView(
            children: [
              const SettingsSectionLabel("Motion"),
              RoundedSwitchListTile(
                autofocus: true,
                value: settingsService.appHighlightAnimationEnabled,
                onChanged: (value) =>
                    settingsService.setAppHighlightAnimationEnabled(value),
                title: const SettingsTileText(
                  title: "Focus animation",
                  subtitle: "Animate app cards when focus moves.",
                ),
                secondary: const Icon(Icons.filter_center_focus),
              ),
              RoundedSwitchListTile(
                value: settingsService.appKeyClickEnabled,
                onChanged: (value) =>
                    settingsService.setAppKeyClickEnabled(value),
                title: const SettingsTileText(
                  title: "Remote click sound",
                  subtitle: "Play a short sound when opening apps.",
                ),
                secondary: const Icon(Icons.volume_up_outlined),
              ),
              const SettingsSectionLabel("Rows"),
              RoundedSwitchListTile(
                value: settingsService.showCategoryTitles,
                onChanged: (value) =>
                    settingsService.setShowCategoryTitles(value),
                title: const SettingsTileText(
                  title: "Section titles",
                  subtitle: "Show labels above app rows.",
                ),
                secondary: const Icon(Icons.title_outlined),
              ),
              RoundedSwitchListTile(
                value: settingsService.showAppNamesBelowIcons,
                onChanged: (value) =>
                    settingsService.setShowAppNamesBelowIcons(value),
                title: const SettingsTileText(
                  title: "App names",
                  subtitle: "Show names below home tiles.",
                ),
                secondary: const Icon(Icons.subtitles_outlined),
              ),
              const SettingsSectionLabel("Top Controls"),
              RoundedSwitchListTile(
                value: settingsService.autoHideAppBarEnabled,
                onChanged: (value) =>
                    settingsService.setAutoHideAppBarEnabled(value),
                title: const SettingsTileText(
                  title: "Auto-hide top controls",
                  subtitle: "Hide clock, network, and weather while browsing.",
                ),
                secondary: const Icon(Icons.visibility_off_outlined),
              ),
              RoundedSwitchListTile(
                value: settingsService.showNetworkIndicatorInStatusBar,
                onChanged: (value) =>
                    settingsService.setShowNetworkIndicatorInStatusBar(value),
                title: const SettingsTileText(
                  title: "Network indicator",
                  subtitle: "Keep Wi-Fi status in the top controls.",
                ),
                secondary: const Icon(Icons.signal_wifi_statusbar_4_bar),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
