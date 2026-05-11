import 'package:flutter/material.dart';
import 'package:opencore_tv/providers/apps_service.dart';
import 'package:opencore_tv/widgets/settings/focusable_settings_tile.dart';
import 'package:provider/provider.dart';

class NativeFireTvSettingsPage extends StatelessWidget {
  static const String routeName = "native_fire_tv_settings_panel";

  const NativeFireTvSettingsPage({super.key});

  static const List<_NativeSettingsDestination> _destinations = [
    _NativeSettingsDestination(
      title: "Device & About",
      subtitle: "Storage, restart, updates, legal, device info",
      icon: Icons.tv_outlined,
      action: "com.amazon.device.settings.action.DEVICE",
    ),
    _NativeSettingsDestination(
      title: "Network",
      subtitle: "Wi-Fi and network connection settings",
      icon: Icons.wifi_outlined,
      action: "android.settings.WIFI_SETTINGS",
    ),
    _NativeSettingsDestination(
      title: "Applications",
      subtitle: "Installed apps, permissions, app management",
      icon: Icons.apps_outlined,
      action: "com.amazon.device.settings.action.APPLICATIONS",
    ),
    _NativeSettingsDestination(
      title: "Controllers & Bluetooth",
      subtitle: "Remotes, game controllers, Bluetooth devices",
      icon: Icons.bluetooth_outlined,
      action: "com.amazon.device.settings.action.CONTROLLERS",
    ),
    _NativeSettingsDestination(
      title: "Privacy Cookies",
      subtitle: "Fire TV cookie preference screen",
      icon: Icons.privacy_tip_outlined,
      action: "com.amazon.device.settings.action.COOKIE_PREFERENCE",
    ),
    _NativeSettingsDestination(
      title: "Developer Options",
      subtitle: "ADB debugging and developer controls",
      icon: Icons.code_outlined,
      action:
          "com.amazon.device.settings.action.APPLICATION_DEVELOPMENT_SETTINGS",
    ),
    _NativeSettingsDestination(
      title: "Install Unknown Apps",
      subtitle: "Sideload permissions for app installers",
      icon: Icons.download_for_offline_outlined,
      action: "android.settings.MANAGE_UNKNOWN_APP_SOURCES",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "Native Fire TV Settings",
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          "Fire OS blocks the protected root settings hub and some sections from custom launchers, so OpenCore only shows native destinations that are callable directly.",
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white.withOpacity(0.58),
                height: 1.25,
              ),
        ),
        const SizedBox(height: 12),
        const Divider(),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                for (var i = 0; i < _destinations.length; i++)
                  FocusableSettingsTile(
                    autofocus: i == 0,
                    leading: Icon(_destinations[i].icon),
                    title: _DestinationText(destination: _destinations[i]),
                    trailing: const Icon(Icons.open_in_new, size: 18),
                    onPressed: () => _openDestination(
                      context,
                      _destinations[i].action,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openDestination(BuildContext context, String action) async {
    final appsService = context.read<AppsService>();
    Navigator.of(context, rootNavigator: true).pop();
    await Future<void>.delayed(const Duration(milliseconds: 90));
    await appsService.launchActivityFromAction(action);
  }
}

class _DestinationText extends StatelessWidget {
  final _NativeSettingsDestination destination;

  const _DestinationText({required this.destination});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          destination.title,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 3),
        Text(
          destination.subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white.withOpacity(0.52),
              ),
        ),
      ],
    );
  }
}

class _NativeSettingsDestination {
  final String title;
  final String subtitle;
  final IconData icon;
  final String action;

  const _NativeSettingsDestination({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.action,
  });
}
