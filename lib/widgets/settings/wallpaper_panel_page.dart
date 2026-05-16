import 'package:flutter/material.dart';
import 'package:opencore_tv/providers/appearance_service.dart';
import 'package:opencore_tv/providers/settings_service.dart';
import 'package:opencore_tv/providers/wallpaper_service.dart';
import 'package:opencore_tv/widgets/rounded_switch_list_tile.dart';
import 'package:opencore_tv/widgets/settings/focusable_settings_tile.dart';
import 'package:opencore_tv/widgets/settings/gradient_panel_page.dart';
import 'package:opencore_tv/widgets/settings/settings_page_layout.dart';
import 'package:opencore_tv/widgets/settings/wallpaper_category_page.dart';
import 'package:opencore_tv/widgets/settings/wallpaper_library_page.dart';
import 'package:opencore_tv/widgets/settings/wallpaper_mode_page.dart';
import 'package:opencore_tv/widgets/settings/wallpaper_rotation_frequency_page.dart';
import 'package:provider/provider.dart';

class WallpaperPanelPage extends StatelessWidget {
  static const String routeName = "wallpaper_panel";

  const WallpaperPanelPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final appearance = context.watch<AppearanceService>();
    final wallpaperService = context.watch<WallpaperService>();
    final categorySummary = _categorySummary(
      wallpaperService,
      settings.wallpaperCategory,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SettingsPageHeader(
          title: "Wallpaper",
          subtitle: "Appearance, library, categories, and rotation.",
        ),
        Expanded(
          child: ListView(
            children: [
              const SettingsSectionLabel("Appearance"),
              FocusableSettingsTile(
                autofocus: true,
                leading: const Icon(Icons.contrast_outlined),
                title: SettingsTileText(
                  title: "Light / Dark mode",
                  subtitle: appearance.statusLabel,
                ),
                trailing: const Icon(Icons.chevron_right),
                onPressed: () => Navigator.of(context)
                    .pushNamed(WallpaperModePage.routeName),
              ),
              const SettingsSectionLabel("Wallpapers"),
              FocusableSettingsTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: SettingsTileText(
                  title: "Library",
                  subtitle: _librarySummary(wallpaperService),
                ),
                trailing: const Icon(Icons.chevron_right),
                onPressed: () => Navigator.of(context)
                    .pushNamed(WallpaperLibraryPage.routeName),
              ),
              FocusableSettingsTile(
                leading: const Icon(Icons.category_outlined),
                title: SettingsTileText(
                  title: "Categories",
                  subtitle: categorySummary,
                ),
                trailing: const Icon(Icons.chevron_right),
                onPressed: () => Navigator.of(context)
                    .pushNamed(WallpaperCategoryPage.routeName),
              ),
              FocusableSettingsTile(
                leading: const Icon(Icons.gradient_outlined),
                title: const SettingsTileText(
                  title: "Fallback gradient",
                  subtitle: "Used only when no image wallpaper is available.",
                ),
                trailing: const Icon(Icons.chevron_right),
                onPressed: () => Navigator.of(context)
                    .pushNamed(GradientPanelPage.routeName),
              ),
              const SettingsSectionLabel("Rotation"),
              RoundedSwitchListTile(
                title: const SettingsTileText(
                  title: "Rotate wallpaper",
                  subtitle: "Cycle through the selected category.",
                ),
                secondary: const Icon(Icons.autorenew),
                value: settings.wallpaperRotationEnabled,
                onChanged: settings.setWallpaperRotationEnabled,
              ),
              if (settings.wallpaperRotationEnabled)
                FocusableSettingsTile(
                  leading: const Icon(Icons.timer_outlined),
                  title: SettingsTileText(
                    title: "Every ${settings.wallpaperRotationMinutes} minutes",
                    subtitle: "Change the wallpaper rotation interval.",
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onPressed: () => Navigator.of(context)
                      .pushNamed(WallpaperRotationFrequencyPage.routeName),
                ),
              const SettingsSectionLabel("Advanced"),
              RoundedSwitchListTile(
                title: const SettingsTileText(
                  title: "Legacy time slots",
                  subtitle: "Use old day/night custom wallpaper files.",
                ),
                secondary: const Icon(Icons.access_time),
                value: settings.timeBasedWallpaperEnabled,
                onChanged: settings.setTimeBasedWallpaperEnabled,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _librarySummary(WallpaperService service) {
    final dark = service.catalog
        .where((entry) => entry.brightness == WallpaperBrightness.dark)
        .length;
    final light = service.catalog
        .where((entry) => entry.brightness == WallpaperBrightness.light)
        .length;
    return "$dark dark / $light light wallpapers";
  }

  String _categorySummary(WallpaperService service, String category) {
    final label = category == WALLPAPER_CATEGORY_ALL
        ? "All categories"
        : _categoryLabel(category);
    final count = category == WALLPAPER_CATEGORY_ALL
        ? service.catalog.length
        : service.catalog
            .where((entry) => entry.categories.contains(category))
            .length;
    return "$label · $count wallpapers";
  }

  String _categoryLabel(String category) =>
      category[0].toUpperCase() + category.substring(1);
}
