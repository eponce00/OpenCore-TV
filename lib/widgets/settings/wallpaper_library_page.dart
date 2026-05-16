import 'package:opencore_tv/providers/settings_service.dart';
import 'package:opencore_tv/providers/wallpaper_service.dart';
import 'package:opencore_tv/theme/opencore_theme.dart';
import 'package:opencore_tv/widgets/settings/focusable_settings_tile.dart';
import 'package:opencore_tv/widgets/settings/settings_page_layout.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class WallpaperLibraryPage extends StatelessWidget {
  static const String routeName = "wallpaper_library";

  const WallpaperLibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedAsset = context.select<SettingsService, String?>(
      (settings) => settings.bundledWallpaperAsset,
    );
    final wallpaperService = context.watch<WallpaperService>();
    final wallpapers = wallpaperService.activeCatalog;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SettingsPageHeader(
          title: "Wallpaper Library",
          subtitle: "Showing wallpapers that match the active appearance mode.",
        ),
        Expanded(
          child: ListView.builder(
            itemCount: wallpapers.length,
            itemBuilder: (context, index) {
              final wallpaper = wallpapers[index];
              final reference = wallpaper.reference;
              final isSelected = reference == selectedAsset ||
                  wallpaper.asset == selectedAsset;

              return FocusableSettingsTile(
                autofocus: index == 0,
                leading: Container(
                  width: 96,
                  height: 54,
                  padding: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? context.openCoreAccentLine
                          : Colors.transparent,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: Image(
                      image: wallpaperService.imageProviderFor(wallpaper),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                title: SettingsTileText(
                  title: "Wallpaper ${index + 1}",
                  subtitle:
                      "${wallpaper.brightness.name} / ${wallpaper.categories.join(", ")} / ${wallpaper.isRemote ? "online" : "offline"}",
                ),
                trailing: isSelected
                    ? Icon(Icons.check_circle,
                        color: context.openCoreAccentMuted)
                    : null,
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await context
                        .read<WallpaperService>()
                        .setBundledWallpaper(reference);
                  } catch (_) {
                    if (context.mounted) {
                      messenger.showSnackBar(
                        const SnackBar(
                          duration: Duration(seconds: 3),
                          content: Text("Wallpaper could not be downloaded"),
                        ),
                      );
                    }
                    return;
                  }
                  if (context.mounted) {
                    messenger.showSnackBar(
                      const SnackBar(
                        duration: Duration(seconds: 2),
                        content: Text("Wallpaper applied"),
                      ),
                    );
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
