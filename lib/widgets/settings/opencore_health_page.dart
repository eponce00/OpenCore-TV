import 'package:flutter/material.dart';
import 'package:opencore_tv/providers/apps_service.dart';
import 'package:provider/provider.dart';

import 'focusable_settings_tile.dart';

class OpenCoreHealthPage extends StatefulWidget {
  static const String routeName = "opencore_health";

  const OpenCoreHealthPage({super.key});

  @override
  State<OpenCoreHealthPage> createState() => _OpenCoreHealthPageState();
}

class _OpenCoreHealthPageState extends State<OpenCoreHealthPage> {
  bool? _homeGuardEnabled;
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final appsService = context.read<AppsService>();
    final enabled = await appsService.isHomeGuardEnabled();
    if (!mounted) return;
    setState(() {
      _homeGuardEnabled = enabled;
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
      _homeGuardEnabled = repaired;
      _message = repaired
          ? "Home Guard is enabled."
          : "Automatic repair was blocked by Fire OS. Use the recovery script or enable Home Guard in Accessibility settings.";
    });
  }

  @override
  Widget build(BuildContext context) {
    final healthy = _homeGuardEnabled == true;

    return Column(
      children: [
        Text("OpenCore Health", style: Theme.of(context).textTheme.titleLarge),
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
                    "Home Guard keeps the Fire TV Home button on OpenCore. Fire OS may disable it after reinstalls, so OpenCore checks it here.",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                FocusableSettingsTile(
                  autofocus: true,
                  leading: Icon(
                    healthy ? Icons.check_circle : Icons.warning_amber_rounded,
                    color: healthy ? Colors.greenAccent : Colors.orangeAccent,
                  ),
                  title: Text(
                    _homeGuardEnabled == null
                        ? "Checking Home Guard..."
                        : healthy
                            ? "Home Guard is enabled"
                            : "Home Guard is disabled",
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
                FocusableSettingsTile(
                  leading: const Icon(Icons.build_circle_outlined),
                  title: Text("Repair Home Guard",
                      style: Theme.of(context).textTheme.bodyMedium),
                  onPressed: _busy ? null : _repair,
                ),
                FocusableSettingsTile(
                  leading: const Icon(Icons.accessibility_new_outlined),
                  title: Text("Open Accessibility Settings",
                      style: Theme.of(context).textTheme.bodyMedium),
                  onPressed: () => context
                      .read<AppsService>()
                      .openAccessibilitySettings(),
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
