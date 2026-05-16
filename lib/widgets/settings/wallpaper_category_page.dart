import 'package:flutter/material.dart';
import 'package:opencore_tv/providers/settings_service.dart';
import 'package:opencore_tv/providers/wallpaper_service.dart';
import 'package:opencore_tv/theme/opencore_theme.dart';
import 'package:opencore_tv/widgets/settings/focusable_settings_tile.dart';
import 'package:opencore_tv/widgets/settings/settings_page_layout.dart';
import 'package:provider/provider.dart';

class WallpaperCategoryPage extends StatelessWidget {
  static const String routeName = "wallpaper_category_panel";

  const WallpaperCategoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final wallpaperService = context.watch<WallpaperService>();
    final categories = _categories(wallpaperService);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SettingsPageHeader(
          title: "Categories",
          subtitle: "Filter bundled wallpapers by collection.",
        ),
        Expanded(
          child: ListView(
            children: [
              FocusableSettingsTile(
                autofocus: true,
                leading: const Icon(Icons.all_inclusive),
                title: SettingsTileText(
                  title: "All categories",
                  subtitle: _counts(wallpaperService.catalog),
                ),
                trailing: settings.wallpaperCategory == WALLPAPER_CATEGORY_ALL
                    ? Icon(Icons.check, color: context.openCoreAccentMuted)
                    : null,
                onPressed: () =>
                    settings.setWallpaperCategory(WALLPAPER_CATEGORY_ALL),
              ),
              const SettingsSectionLabel("Collections"),
              for (final category in categories)
                FocusableSettingsTile(
                  leading: const Icon(Icons.collections_outlined),
                  title: SettingsTileText(
                    title: _label(category),
                    subtitle: _counts(_entriesFor(wallpaperService, category)),
                  ),
                  trailing: settings.wallpaperCategory == category
                      ? Icon(Icons.check, color: context.openCoreAccentMuted)
                      : null,
                  onPressed: () => settings.setWallpaperCategory(category),
                ),
            ],
          ),
        ),
      ],
    );
  }

  List<String> _categories(WallpaperService service) {
    final categories = <String>{};
    for (final entry in service.catalog) {
      categories.addAll(entry.categories);
    }
    return categories.toList(growable: false)..sort();
  }

  List<WallpaperCatalogEntry> _entriesFor(
    WallpaperService service,
    String category,
  ) =>
      service.catalog
          .where((entry) => entry.categories.contains(category))
          .toList(growable: false);

  String _counts(List<WallpaperCatalogEntry> entries) {
    final dark =
        entries.where((entry) => entry.brightness == WallpaperBrightness.dark);
    final light =
        entries.where((entry) => entry.brightness == WallpaperBrightness.light);
    return "${dark.length} dark / ${light.length} light wallpapers";
  }

  String _label(String category) =>
      category[0].toUpperCase() + category.substring(1);
}
