import 'package:flutter/material.dart';
import 'package:opencore_tv/providers/apps_service.dart';
import 'package:opencore_tv/theme/opencore_theme.dart';
import 'package:provider/provider.dart';

import 'focusable_settings_tile.dart';

class OpenCoreHealthPage extends StatefulWidget {
  static const String routeName = "opencore_health";

  const OpenCoreHealthPage({super.key});

  @override
  State<OpenCoreHealthPage> createState() => _OpenCoreHealthPageState();
}

class _OpenCoreHealthPageState extends State<OpenCoreHealthPage> {
  bool? _launcherProtected;
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final appsService = context.read<AppsService>();
    final profile = appsService.deviceProfile;
    final enabled = profile.supportsHomeGuard
        ? await appsService.isHomeGuardEnabled()
        : await appsService.isDefaultLauncher();
    if (!mounted) return;
    setState(() {
      _launcherProtected = enabled;
      _message = null;
    });
  }

  Future<void> _repair() async {
    setState(() {
      _busy = true;
      _message = null;
    });

    final appsService = context.read<AppsService>();
    final repaired = await appsService.repairHomeGuard();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _launcherProtected = repaired;
      _message = repaired
          ? "Launcher protection is enabled."
          : "Automatic repair was blocked. Use the Fire TV recovery script or enable Home Guard in Accessibility settings.";
    });
  }

  @override
  Widget build(BuildContext context) {
    final appsService = context.watch<AppsService>();
    final profile = appsService.deviceProfile;
    final healthy = _launcherProtected == true;
    final colors = context.openCoreColors;
    final statusColor = Color.lerp(
      colors.mutedText,
      healthy ? const Color(0xFF8FD8A0) : const Color(0xFFE0B36A),
      0.65,
    )!;

    return Column(
      children: [
        Text("Launcher Protection",
            style: Theme.of(context).textTheme.titleLarge),
        const Divider(),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Text(
                    profile.supportsHomeGuard
                        ? "Home Guard keeps the Fire TV Home button on OpenCore. Fire OS may disable it after reinstalls, so OpenCore checks it here."
                        : "OpenCore checks whether this ${profile.label} currently treats it as the default launcher. Some devices require changing this in system settings.",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                FocusableSettingsTile(
                  autofocus: true,
                  leading: Icon(
                    healthy ? Icons.check_circle : Icons.warning_amber_rounded,
                    color: statusColor,
                  ),
                  title: Text(
                    _launcherProtected == null
                        ? "Checking launcher protection..."
                        : healthy
                            ? profile.supportsHomeGuard
                                ? "Home Guard is enabled"
                                : "OpenCore is the default launcher"
                            : profile.supportsHomeGuard
                                ? "Home Guard is disabled"
                                : "OpenCore is not the default launcher",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  trailing: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                  onPressed: _refresh,
                ),
                if (profile.supportsHomeSelfRepair)
                  FocusableSettingsTile(
                    leading: const Icon(Icons.build_circle_outlined),
                    title: Text("Repair Home Guard",
                        style: Theme.of(context).textTheme.bodyMedium),
                    onPressed: _busy ? null : _repair,
                  ),
                if (profile.supportsHomeGuard)
                  FocusableSettingsTile(
                    leading: const Icon(Icons.accessibility_new_outlined),
                    title: Text("Open Accessibility Settings",
                        style: Theme.of(context).textTheme.bodyMedium),
                    onPressed: () =>
                        context.read<AppsService>().openAccessibilitySettings(),
                  )
                else
                  FocusableSettingsTile(
                    leading: const Icon(Icons.settings_outlined),
                    title: Text("Open System Settings",
                        style: Theme.of(context).textTheme.bodyMedium),
                    onPressed: () => context.read<AppsService>().openSettings(),
                  ),
                FocusableSettingsTile(
                  leading: const Icon(Icons.refresh),
                  title: Text("Refresh Status",
                      style: Theme.of(context).textTheme.bodyMedium),
                  onPressed: _refresh,
                ),
                if (_message != null)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _message!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
