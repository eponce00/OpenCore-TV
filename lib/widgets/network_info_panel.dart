import 'package:opencore_tv/providers/network_service.dart';
import 'package:opencore_tv/widgets/settings/focusable_settings_tile.dart';
import 'package:opencore_tv/widgets/side_panel_dialog.dart';
import 'package:flutter/material.dart';
import 'package:opencore_tv/theme/opencore_theme.dart';
import 'package:provider/provider.dart';

class NetworkInfoPanel extends StatelessWidget {
  const NetworkInfoPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final network = context.watch<NetworkService>();
    final type = _networkTypeLabel(network.networkType);

    return SidePanelDialog(
      width: 340,
      isRightSide: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text("Network", style: Theme.of(context).textTheme.titleLarge),
          const Divider(),
          FocusableSettingsTile(
            autofocus: true,
            leading: Icon(_networkIcon(network.networkType)),
            title: _PanelTileText(
              title: type,
              subtitle: network.hasInternetAccess
                  ? "Internet available"
                  : "No internet detected",
            ),
          ),
          if (network.networkType == NetworkType.Wifi)
            FocusableSettingsTile(
              leading: const Icon(Icons.signal_wifi_4_bar),
              title: _PanelTileText(
                title: "Wi-Fi signal",
                subtitle: "${network.wirelessNetworkSignalLevel + 1} / 5",
              ),
            ),
          const Divider(),
          FocusableSettingsTile(
            leading: const Icon(Icons.settings_outlined),
            title: const _PanelTileText(
              title: "Open Network Settings",
              subtitle: "Wi-Fi and network connection setup.",
            ),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onPressed: () => _openWifiSettings(context),
          ),
        ],
      ),
    );
  }

  Future<void> _openWifiSettings(BuildContext context) async {
    final networkService = context.read<NetworkService>();
    Navigator.of(context, rootNavigator: true).pop();
    await Future<void>.delayed(const Duration(milliseconds: 90));
    await networkService.openWifiSettings();
  }

  IconData _networkIcon(NetworkType type) {
    return switch (type) {
      NetworkType.Wifi => Icons.signal_wifi_4_bar,
      NetworkType.Wired => Icons.lan,
      NetworkType.Vpn => Icons.vpn_key,
      NetworkType.Cellular => Icons.cell_tower,
      NetworkType.Unknown => Icons.link_off,
    };
  }

  String _networkTypeLabel(NetworkType type) {
    return switch (type) {
      NetworkType.Wifi => "Wi‑Fi",
      NetworkType.Wired => "Ethernet",
      NetworkType.Vpn => "VPN",
      NetworkType.Cellular => "Cellular",
      NetworkType.Unknown => "Unknown network",
    };
  }
}

class _PanelTileText extends StatelessWidget {
  final String title;
  final String subtitle;

  const _PanelTileText({
    required this.title,
    required this.subtitle,
  });

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
