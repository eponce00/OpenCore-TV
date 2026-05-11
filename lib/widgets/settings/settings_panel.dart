/*
 * OpenCoreTV
 * Copyright (C) 2021  Étienne Fesser
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'package:opencore_tv/widgets/side_panel_dialog.dart';
import 'package:opencore_tv/widgets/settings/applications_panel_page.dart';
import 'package:opencore_tv/widgets/settings/launcher_sections_panel_page.dart';
import 'package:opencore_tv/widgets/settings/gradient_panel_page.dart';
import 'package:opencore_tv/widgets/settings/launcher_section_panel_page.dart';
import 'package:opencore_tv/widgets/settings/settings_panel_page.dart';
import 'package:opencore_tv/widgets/settings/wallpaper_panel_page.dart';
import 'package:opencore_tv/widgets/settings/wallpaper_library_page.dart';
import 'package:opencore_tv/widgets/settings/wallpaper_rotation_frequency_page.dart';
import 'package:opencore_tv/widgets/settings/weather_location_search_page.dart';
import 'package:opencore_tv/widgets/settings/wifi_usage_period_page.dart';
import 'package:opencore_tv/widgets/settings/date_time_format_page.dart';
import 'package:opencore_tv/widgets/settings/app_details_page.dart';
import 'package:opencore_tv/widgets/settings/accent_color_page.dart';
import 'package:opencore_tv/widgets/settings/opencore_clock_settings_page.dart';
import 'package:opencore_tv/widgets/settings/brightness_settings_page.dart';
import 'package:opencore_tv/widgets/settings/home_display_settings_page.dart';
import 'package:opencore_tv/widgets/settings/input_detail_page.dart';
import 'package:opencore_tv/widgets/settings/input_settings_page.dart';
import 'package:opencore_tv/widgets/settings/idle_settings_page.dart';
import 'package:opencore_tv/widgets/settings/idle_timeout_page.dart';
import 'package:opencore_tv/widgets/settings/native_fire_tv_settings_page.dart';
import 'package:opencore_tv/widgets/settings/opencore_health_page.dart';
import 'package:opencore_tv/widgets/settings/weather_settings_page.dart';
import 'package:opencore_tv/widgets/settings/general_settings_page.dart';
import 'package:opencore_tv/opencore_tv_channel.dart';
import 'package:opencore_tv/models/app.dart';
import 'package:flutter/material.dart';

class SettingsPanel extends StatefulWidget {
  final String? initialRoute;

  const SettingsPanel({Key? key, this.initialRoute}) : super(key: key);

  @override
  State<SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<SettingsPanel> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final OpenCoreTVChannel _channel = OpenCoreTVChannel();

  @override
  void initState() {
    super.initState();
    _channel.setPanelOpen(true);
  }

  @override
  void dispose() {
    _channel.setPanelOpen(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final nestedNavigator = _navigatorKey.currentState;
        if (nestedNavigator != null && await nestedNavigator.maybePop()) {
          return;
        }

        if (context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black54, // Dim the background
        body: Stack(
          children: [
            // Tap outside to close
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(color: Colors.transparent),
            ),
            // The side panel
            SidePanelDialog(
              width: 500,
              isRightSide: false,
              child: Navigator(
                key: _navigatorKey,
                initialRoute:
                    widget.initialRoute ?? SettingsPanelPage.routeName,
                onGenerateRoute: (settings) {
                  switch (settings.name) {
                    case SettingsPanelPage.routeName:
                      return _FastPageRoute(
                          builder: (_) => SettingsPanelPage());
                    case GeneralSettingsPage.routeName:
                      return _FastPageRoute(
                          builder: (_) => GeneralSettingsPage());
                    case WallpaperPanelPage.routeName:
                      return _FastPageRoute(
                          builder: (_) => WallpaperPanelPage());
                    case WallpaperLibraryPage.routeName:
                      return _FastPageRoute(
                          builder: (_) => const WallpaperLibraryPage());
                    case WallpaperRotationFrequencyPage.routeName:
                      return _FastPageRoute(
                          builder: (_) =>
                              const WallpaperRotationFrequencyPage());
                    case InputSettingsPage.routeName:
                      return _FastPageRoute(
                          builder: (_) => const InputSettingsPage());
                    case InputDetailPage.routeName:
                      return _FastPageRoute(
                          builder: (_) => InputDetailPage(
                              packageName: settings.arguments as String));
                    case IdleSettingsPage.routeName:
                      return _FastPageRoute(
                          builder: (_) => const IdleSettingsPage());
                    case IdleTimeoutPage.routeName:
                      return _FastPageRoute(
                          builder: (_) => const IdleTimeoutPage());
                    case WeatherSettingsPage.routeName:
                      return _FastPageRoute(
                          builder: (_) => const WeatherSettingsPage());
                    case WeatherLocationSearchPage.routeName:
                      return _FastPageRoute(
                          builder: (_) => const WeatherLocationSearchPage());
                    case GradientPanelPage.routeName:
                      return _FastPageRoute(
                          builder: (_) => GradientPanelPage());
                    case ApplicationsPanelPage.routeName:
                      return _FastPageRoute(
                          builder: (_) => ApplicationsPanelPage());
                    case LauncherSectionsPanelPage.routeName:
                      return _FastPageRoute(
                          builder: (_) => LauncherSectionsPanelPage());
                    case LauncherSectionPanelPage.routeName:
                      return _FastPageRoute(
                          builder: (_) => LauncherSectionPanelPage(
                              sectionIndex: settings.arguments as int?));
                    case WifiUsagePeriodPage.routeName:
                      return _FastPageRoute(
                          builder: (_) => WifiUsagePeriodPage());
                    case DateTimeFormatPage.routeName:
                      return _FastPageRoute(
                          builder: (_) => DateTimeFormatPage());
                    case HomeDisplaySettingsPage.routeName:
                      return _FastPageRoute(
                          builder: (_) => const HomeDisplaySettingsPage());
                    case OpenCoreClockSettingsPage.routeName:
                      return _FastPageRoute(
                          builder: (_) => const OpenCoreClockSettingsPage());
                    case AccentColorPage.routeName:
                      return _FastPageRoute(builder: (_) => AccentColorPage());
                    case BrightnessSettingsPage.routeName:
                      return _FastPageRoute(
                          builder: (_) => BrightnessSettingsPage());
                    case OpenCoreHealthPage.routeName:
                      return _FastPageRoute(
                          builder: (_) => const OpenCoreHealthPage());
                    case NativeFireTvSettingsPage.routeName:
                      return _FastPageRoute(
                          builder: (_) => const NativeFireTvSettingsPage());
                    case AppDetailsPage.routeName:
                      return _FastPageRoute(
                          builder: (_) => AppDetailsPage(
                              application: settings.arguments as App));
                    default:
                      throw ArgumentError.value(settings.name, "settings.name",
                          "Route not supported.");
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A faster page route with a 150ms slide transition instead of
/// the default 300ms Material transition.
class _FastPageRoute<T> extends MaterialPageRoute<T> {
  _FastPageRoute({required super.builder});

  @override
  Duration get transitionDuration => const Duration(milliseconds: 150);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 120);
}
