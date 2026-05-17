import 'package:flutter_test/flutter_test.dart';
import 'package:opencore_tv/providers/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<SettingsService> buildService(
      [Map<String, Object> values = const {}]) async {
    SharedPreferences.setMockInitialValues(values);
    final preferences = await SharedPreferences.getInstance();
    return SettingsService(preferences);
  }

  test('uses current OpenCore defaults', () async {
    final service = await buildService();

    expect(service.idleModeEnabled, isTrue);
    expect(service.homeClockSize, 'large');
    expect(service.showNetworkIndicatorInStatusBar, isTrue);
    expect(service.weatherUnit, 'fahrenheit');
    expect(service.weatherLocationName, 'Los Angeles');
    expect(service.appearanceMode, APPEARANCE_MODE_DARK);
    expect(service.wallpaperCategory, WALLPAPER_CATEGORY_ALL);
    expect(service.bundledWallpaperAsset,
        'assets/wallpapers/dark/dark_earth_07.webp');
  });

  test('stores input labels and icons', () async {
    final service = await buildService();

    await service.setInputLabel('opencore.input.hdmi1', 'PlayStation');
    await service.setInputIcon('opencore.input.hdmi1', 'game');

    expect(
      service.inputLabel('opencore.input.hdmi1', 'HDMI 1'),
      'PlayStation',
    );
    expect(service.inputIcon('opencore.input.hdmi1'), 'game');
  });

  test('stores learned remote button assignments', () async {
    final service = await buildService();

    await service.upsertLearnedRemoteButton(
      const LearnedRemoteButton(
        id: 'key_123_scan_456',
        label: 'Shortcut',
        keyCode: 123,
        scanCode: 456,
        deviceId: 1,
        source: 0,
        packageName: 'org.jellyfin.androidtv',
      ),
    );

    expect(service.learnedRemoteButtons, hasLength(1));
    expect(service.learnedRemoteButtons.first.packageName,
        'org.jellyfin.androidtv');
  });

  test('stores appearance and wallpaper category settings', () async {
    final service = await buildService();

    await service.setAppearanceMode(APPEARANCE_MODE_AUTO_HYBRID);
    await service.setWallpaperCategory('art');

    expect(service.appearanceMode, APPEARANCE_MODE_AUTO_HYBRID);
    expect(service.wallpaperCategory, 'art');
  });
}
