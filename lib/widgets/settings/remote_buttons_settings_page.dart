import 'dart:async';

import 'package:flutter/material.dart';
import 'package:opencore_tv/theme/opencore_theme.dart';
import 'package:opencore_tv/models/app.dart';
import 'package:opencore_tv/opencore_tv_channel.dart';
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
    final appsService = context.watch<AppsService>();
    final apps = appsService.applications;
    final learnedButtons = settings.learnedRemoteButtons;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text("Remote Buttons", style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          "Learn buttons Android exposes to OpenCore, then choose what each one opens.",
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.mutedText,
                height: 1.25,
              ),
        ),
        const SizedBox(height: 12),
        const Divider(),
        FocusableSettingsTile(
          autofocus: true,
          leading: const Icon(Icons.add_circle_outline),
          title: const _ButtonText(
            title: "Add Learned Button",
            subtitle: "Press a remote button, then choose what it opens.",
          ),
          trailing: const Icon(Icons.chevron_right, size: 18),
          onPressed: () => Navigator.of(context).pushNamed(
            LearnRemoteButtonPage.routeName,
          ),
        ),
        for (final button in learnedButtons)
          FocusableSettingsTile(
            leading: const Icon(Icons.radio_button_checked),
            title: _ButtonText(
              title: button.label,
              subtitle: _assignmentLabel(button.packageName, apps, settings),
            ),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onPressed: () => Navigator.of(context).pushNamed(
              LearnedRemoteButtonTargetPage.routeName,
              arguments: button.id,
            ),
          ),
        if (learnedButtons.isNotEmpty) const Divider(),
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

class LearnRemoteButtonPage extends StatefulWidget {
  static const String routeName = "learn_remote_button_panel";

  const LearnRemoteButtonPage({super.key});

  @override
  State<LearnRemoteButtonPage> createState() => _LearnRemoteButtonPageState();
}

class _LearnRemoteButtonPageState extends State<LearnRemoteButtonPage> {
  Map<String, dynamic>? _capture;
  Timer? _timeout;
  Timer? _armTimer;
  bool _armed = false;

  @override
  void initState() {
    super.initState();
    OpenCoreTVChannel.setRemoteButtonCaptureListener(_onCaptured);
    OpenCoreTVChannel().stopRemoteButtonLearning();
    _armTimer = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() => _armed = true);
      OpenCoreTVChannel().startRemoteButtonLearning();
    });
    _timeout = Timer(const Duration(seconds: 20), () {
      if (mounted && _capture == null) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _armTimer?.cancel();
    _timeout?.cancel();
    OpenCoreTVChannel.setRemoteButtonCaptureListener(null);
    OpenCoreTVChannel().stopRemoteButtonLearning();
    super.dispose();
  }

  void _onCaptured(Map<String, dynamic> capture) {
    if (!mounted) return;
    setState(() => _capture = capture);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.openCoreColors;
    final capture = _capture;

    if (capture == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text("Learn Remote Button",
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            "Press the remote button you want OpenCore to remap. If the TV opens the original app, OpenCore will try to pull you back and learn that launch.",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.mutedText,
                  height: 1.25,
                ),
          ),
          const SizedBox(height: 12),
          const Divider(),
          const FocusableSettingsTile(
            autofocus: true,
            leading: Icon(Icons.settings_remote_outlined),
            title: _ButtonText(
              title: "Waiting for a shortcut button...",
              subtitle:
                  "Select, arrows, Back, and Home are reserved for navigation.",
            ),
          ),
          if (!_armed)
            Padding(
              padding: const EdgeInsets.fromLTRB(13, 8, 13, 0),
              child: Text(
                "Arming capture...",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.mutedText,
                    ),
              ),
            ),
        ],
      );
    }

    final apps = context.watch<AppsService>().applications;
    final settings = context.watch<SettingsService>();
    final visibleApps = apps.where((app) => !app.hidden).toList();
    final label = _captureLabel(capture);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text("Choose Target", style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          "Captured $label. Choose what OpenCore should open when this button is pressed.",
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
                for (final app in visibleApps)
                  FocusableSettingsTile(
                    autofocus: app == visibleApps.firstOrNull,
                    leading: Icon(_iconForApp(app)),
                    title: Text(_appLabel(app, settings)),
                    onPressed: () => _save(context, capture, app.packageName),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _save(
    BuildContext context,
    Map<String, dynamic> capture,
    String packageName,
  ) async {
    final keyCode = capture['keyCode'] as int? ?? 0;
    final scanCode = capture['scanCode'] as int? ?? 0;
    final triggerPackage = capture['triggerPackage'] as String? ?? "";
    final triggerClass = capture['triggerClass'] as String? ?? "";
    final id = triggerPackage.isEmpty
        ? "key_${keyCode}_scan_$scanCode"
        : "launch_${triggerPackage}_${triggerClass}".replaceAll(
            RegExp(r'[^A-Za-z0-9_]+'),
            "_",
          );
    await context.read<SettingsService>().upsertLearnedRemoteButton(
          LearnedRemoteButton(
            id: id,
            label: _captureLabel(capture),
            keyCode: keyCode,
            scanCode: scanCode,
            deviceId: capture['deviceId'] as int? ?? 0,
            source: capture['source'] as int? ?? 0,
            triggerPackage: triggerPackage,
            triggerClass: triggerClass,
            packageName: packageName,
          ),
        );
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  String _captureLabel(Map<String, dynamic> capture) {
    final triggerPackage = capture['triggerPackage'] as String? ?? "";
    if (triggerPackage.isNotEmpty) {
      final shortName = triggerPackage.split(".").last;
      return "Launch ${shortName.isEmpty ? triggerPackage : shortName}";
    }
    final displayLabel = capture['displayLabel'] as String? ?? "Remote Button";
    final keyCode = capture['keyCode'] as int? ?? 0;
    if (displayLabel.startsWith("KEYCODE_")) {
      return displayLabel.substring("KEYCODE_".length).replaceAll("_", " ");
    }
    return "$displayLabel ($keyCode)";
  }
}

class LearnedRemoteButtonTargetPage extends StatelessWidget {
  static const String routeName = "learned_remote_button_target_panel";

  final String buttonId;

  const LearnedRemoteButtonTargetPage({super.key, required this.buttonId});

  @override
  Widget build(BuildContext context) {
    final colors = context.openCoreColors;
    final settings = context.watch<SettingsService>();
    final apps = context.watch<AppsService>().applications;
    final button = settings.learnedRemoteButtons
        .where((button) => button.id == buttonId)
        .firstOrNull;
    if (button == null) {
      return const SizedBox.shrink();
    }
    final visibleApps = apps.where((app) => !app.hidden).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(button.label, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          "Choose what this learned button should open.",
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.mutedText,
                height: 1.25,
              ),
        ),
        const SizedBox(height: 12),
        const Divider(),
        FocusableSettingsTile(
          autofocus: true,
          leading: const Icon(Icons.delete_outline),
          title: const Text("Forget this button"),
          onPressed: () async {
            await context
                .read<SettingsService>()
                .deleteLearnedRemoteButton(button.id);
            if (context.mounted) Navigator.of(context).pop();
          },
        ),
        const Divider(),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                for (final app in visibleApps)
                  FocusableSettingsTile(
                    leading: Icon(_iconForApp(app)),
                    title: Text(_appLabel(app, settings)),
                    trailing: button.packageName == app.packageName
                        ? Icon(Icons.check, color: context.openCoreAccentMuted)
                        : null,
                    onPressed: () async {
                      await context
                          .read<SettingsService>()
                          .upsertLearnedRemoteButton(
                            button.copyWith(packageName: app.packageName),
                          );
                      if (context.mounted) Navigator.of(context).pop();
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

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
      app.name,
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
