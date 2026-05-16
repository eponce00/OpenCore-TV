import 'package:opencore_tv/providers/network_service.dart';
import 'package:opencore_tv/providers/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:opencore_tv/theme/opencore_theme.dart';
import 'package:provider/provider.dart';

class DailyWifiUsageWidget extends StatelessWidget {
  const DailyWifiUsageWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<NetworkService, SettingsService>(
      builder: (context, networkService, settingsService, _) {
        final colors = context.openCoreColors;
        if (!networkService.hasUsageStatsPermission) {
          return TextButton.icon(
            icon: const Icon(Icons.data_usage, size: 20),
            label: const Text("Grant Usage Permission"),
            onPressed: () => networkService.requestPermission(),
          );
        }

        final period = settingsService.wifiUsagePeriod;
        String label;
        switch (period) {
          case 'weekly':
            label = 'Weekly: ';
            break;
          case 'monthly':
            label = 'Monthly: ';
            break;
          case 'daily':
          default:
            label = 'Daily: ';
            break;
        }

        return FutureBuilder<int>(
          future: networkService.getWifiUsageForPeriod(period),
          builder: (context, snapshot) {
            final usage = snapshot.data ?? networkService.dailyWifiUsage;
            final usageString = _formatBytes(usage);
            final accent = context.openCoreAccentMuted;

            return RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  color: colors.text,
                  shadows: [
                    Shadow(
                        color: colors.shadow,
                        offset: Offset(0, 2),
                        blurRadius: 4)
                  ],
                ),
                children: [
                  TextSpan(text: label),
                  TextSpan(
                    text: usageString,
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = 0;
    double d = bytes.toDouble();
    while (d >= 1024 && i < suffixes.length - 1) {
      d /= 1024;
      i++;
    }
    return "${d.toStringAsFixed(2)} ${suffixes[i]}";
  }
}
