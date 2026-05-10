import 'package:opencore_tv/providers/settings_service.dart';
import 'package:opencore_tv/widgets/rounded_switch_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class HomeDisplaySettingsPage extends StatelessWidget {
  static const String routeName = "home_display_panel";

  const HomeDisplaySettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    AppLocalizations localizations = AppLocalizations.of(context)!;
    SettingsService settingsService = Provider.of(context);

    return Column(
      children: [
        Text("Home Display", style: Theme.of(context).textTheme.titleLarge),
        const Divider(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              RoundedSwitchListTile(
                autofocus: true,
                value: settingsService.appHighlightAnimationEnabled,
                onChanged: (value) =>
                    settingsService.setAppHighlightAnimationEnabled(value),
                title: Text(localizations.appCardHighlightAnimation,
                    style: Theme.of(context).textTheme.bodyMedium),
                secondary: Icon(Icons.filter_center_focus),
              ),
              RoundedSwitchListTile(
                value: settingsService.appKeyClickEnabled,
                onChanged: (value) =>
                    settingsService.setAppKeyClickEnabled(value),
                title: Text(localizations.appKeyClick,
                    style: Theme.of(context).textTheme.bodyMedium),
                secondary: Icon(Icons.notifications_active),
              ),
              RoundedSwitchListTile(
                value: settingsService.showCategoryTitles,
                onChanged: (value) =>
                    settingsService.setShowCategoryTitles(value),
                title: Text(localizations.showCategoryTitles,
                    style: Theme.of(context).textTheme.bodyMedium),
                secondary: Icon(Icons.abc),
              ),
              RoundedSwitchListTile(
                value: settingsService.showAppNamesBelowIcons,
                onChanged: (value) =>
                    settingsService.setShowAppNamesBelowIcons(value),
                title: Text("Show App Names Below Icons",
                    style: Theme.of(context).textTheme.bodyMedium),
                secondary: Icon(Icons.subtitles),
              ),
              RoundedSwitchListTile(
                value: settingsService.dockBackdropFilterDisabled,
                onChanged: (value) =>
                    settingsService.setDockBackdropFilterDisabled(value),
                title: Text("Disable Dock Backdrop Blur",
                    style: Theme.of(context).textTheme.bodyMedium),
                secondary: Icon(Icons.blur_off),
              ),
              RoundedSwitchListTile(
                value: settingsService.autoHideAppBarEnabled,
                onChanged: (value) =>
                    settingsService.setAutoHideAppBarEnabled(value),
                title: Text("Auto-hide top status bar",
                    style: Theme.of(context).textTheme.bodyMedium),
                secondary: const Icon(Icons.visibility_off_outlined),
              ),
              RoundedSwitchListTile(
                value: settingsService.showNetworkIndicatorInStatusBar,
                onChanged: (value) =>
                    settingsService.setShowNetworkIndicatorInStatusBar(value),
                title: Text("Show network indicator",
                    style: Theme.of(context).textTheme.bodyMedium),
                secondary: const Icon(Icons.signal_wifi_4_bar),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
