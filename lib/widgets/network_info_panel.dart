import 'package:opencore_tv/providers/apps_service.dart';
import 'package:opencore_tv/providers/network_service.dart';
import 'package:opencore_tv/widgets/side_panel_dialog.dart';
import 'package:flutter/material.dart';
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
          ListTile(
            leading: Icon(_networkIcon(network.networkType)),
            title: Text(type),
            subtitle: Text(network.hasInternetAccess
                ? "Internet available"
                : "No internet detected"),
          ),
          if (network.networkType == NetworkType.Wifi)
            ListTile(
              leading: const Icon(Icons.signal_wifi_4_bar),
              title: const Text("Wi‑Fi signal"),
              subtitle: Text("${network.wirelessNetworkSignalLevel + 1} / 5"),
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text("Open Fire TV Settings"),
            subtitle: const Text("Use only when you need system Wi‑Fi setup."),
            onTap: () => context.read<AppsService>().openSettings(),
          ),
        ],
      ),
    );
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
