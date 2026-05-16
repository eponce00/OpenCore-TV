import 'package:flutter/material.dart';
import 'package:opencore_tv/theme/opencore_theme.dart';
import 'package:opencore_tv/models/app.dart';
import 'package:opencore_tv/providers/apps_service.dart';
import 'package:opencore_tv/providers/settings_service.dart';
import 'package:opencore_tv/widgets/settings/focusable_settings_tile.dart';
import 'package:provider/provider.dart';

class RemoteButtonsSettingsPage extends StatelessWidget {
  static const String routeName = "remote_buttons_settings_panel";

  const RemoteButtonsSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.openCoreColors;
    final settings = context.watch<SettingsService>();
    final apps = context.watch<AppsService>().applications;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text("Remote Buttons", style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          "Choose what OpenCore opens after Fire OS intercepts a branded remote button.",
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.mutedText,
                height: 1.25,
              ),
        ),
        const SizedBox(height: 12),
        const Divider(),
        for (var i = 0; i < remoteButtonOptions.length; i++)
          FocusableSettingsTile(
            autofocus: i == 0,
            leading: Icon(remoteButtonOptions[i].icon),
            title: _ButtonText(
              title: remoteButtonOptions[i].label,
              subtitle: _assignmentLabel(
                settings.remoteButtonAssignment(remoteButtonOptions[i].id),
                apps,
                settings,
              ),
            ),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onPressed: () => Navigator.of(context).pushNamed(
              RemoteButtonTargetPage.routeName,
              arguments: remoteButtonOptions[i].id,
            ),
          ),
        const Divider(),
        const FocusableSettingsTile(
          leading: Icon(Icons.menu_open_outlined),
          title: _ButtonText(
            title: "Menu button",
            subtitle: "Opens actions for the focused app or input tile.",
          ),
        ),
      ],
    );
  }
}

class RemoteButtonTargetPage extends StatelessWidget {
  static const String routeName = "remote_button_target_panel";

  final String buttonId;

  const RemoteButtonTargetPage({super.key, required this.buttonId});

  @override
  Widget build(BuildContext context) {
    final colors = context.openCoreColors;
    final settings = context.watch<SettingsService>();
    final apps = context.watch<AppsService>().applications;
    final current = settings.remoteButtonAssignment(buttonId);
    final button = remoteButtonOptions.firstWhere((b) => b.id == buttonId);
    final visibleApps = apps.where((app) => !app.hidden).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text("${button.label} Button",
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          "Pick what should open when this remote button is pressed.",
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
              children: [
                FocusableSettingsTile(
                  autofocus: current.isEmpty,
                  leading: const Icon(Icons.block_outlined),
                  title: const Text("Do nothing"),
                  trailing: current.isEmpty
                      ? Icon(Icons.check, color: context.openCoreAccentMuted)
                      : null,
                  onPressed: () => _select(context, ""),
                ),
                for (final app in visibleApps)
                  FocusableSettingsTile(
                    autofocus: current == app.packageName,
                    leading: Icon(_iconForApp(app)),
                    title: Text(_appLabel(app, settings)),
                    trailing: current == app.packageName
                        ? Icon(Icons.check, color: context.openCoreAccentMuted)
                        : null,
                    onPressed: () => _select(context, app.packageName),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _select(BuildContext context, String packageName) async {
    await context
        .read<SettingsService>()
        .setRemoteButtonAssignment(buttonId, packageName);
    if (context.mounted) Navigator.of(context).pop();
  }
}

class RemoteButtonOption {
  final String id;
  final String label;
  final IconData icon;

  const RemoteButtonOption({
    required this.id,
    required this.label,
    required this.icon,
  });
}

const remoteButtonOptions = [
  RemoteButtonOption(
    id: "netflix",
    label: "Netflix",
    icon: Icons.movie_outlined,
  ),
  RemoteButtonOption(
    id: "prime",
    label: "Prime Video",
    icon: Icons.play_circle_outline,
  ),
  RemoteButtonOption(
    id: "disney",
    label: "Disney+",
    icon: Icons.auto_awesome_outlined,
  ),
  RemoteButtonOption(
    id: "peacock",
    label: "Peacock",
    icon: Icons.live_tv_outlined,
  ),
];

class _ButtonText extends StatelessWidget {
  final String title;
  final String subtitle;

  const _ButtonText({required this.title, required this.subtitle});

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

String _assignmentLabel(
  String packageName,
  List<App> apps,
  SettingsService settings,
) {
  if (packageName.isEmpty) return "Do nothing";
  final app = apps.where((app) => app.packageName == packageName).firstOrNull;
  if (app == null) return packageName;
  return _appLabel(app, settings);
}

String _appLabel(App app, SettingsService settings) {
  if (app.packageName.startsWith("opencore.input.")) {
    return settings.inputLabel(
      app.packageName,
      settings.defaultInputLabel(app.packageName),
    );
  }
  return app.name;
}

IconData _iconForApp(App app) {
  if (!app.packageName.startsWith("opencore.input.")) {
    return Icons.apps_outlined;
  }
  return switch (app.packageName) {
    "opencore.input.hdmi1" ||
    "opencore.input.hdmi2" ||
    "opencore.input.hdmi3" ||
    "opencore.input.hdmi4" =>
      Icons.settings_input_hdmi,
    "opencore.input.antenna" => Icons.settings_input_antenna,
    "opencore.input.composite" => Icons.settings_input_component,
    _ => Icons.input_outlined,
  };
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
