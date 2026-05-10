import 'package:opencore_tv/providers/settings_service.dart';
import 'package:opencore_tv/providers/wallpaper_service.dart';
import 'package:opencore_tv/widgets/settings/focusable_settings_tile.dart';
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

    return Column(
      children: [
        Text("Wallpaper Library",
            style: Theme.of(context).textTheme.titleLarge),
        const Divider(),
        Expanded(
          child: ListView.builder(
            itemCount: WallpaperService.bundledWallpapers.length,
            itemBuilder: (context, index) {
              final asset = WallpaperService.bundledWallpapers[index];
              final isSelected = asset == selectedAsset;

              return FocusableSettingsTile(
                autofocus: index == 0,
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    asset,
                    width: 96,
                    height: 54,
                    fit: BoxFit.cover,
                  ),
                ),
                title: Text("Wallpaper ${index + 1}"),
                trailing: isSelected ? const Icon(Icons.check_circle) : null,
                onPressed: () async {
                  await context
                      .read<WallpaperService>()
                      .setBundledWallpaper(asset);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
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
