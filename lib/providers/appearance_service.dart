import 'package:flutter/foundation.dart';
import 'package:opencore_tv/providers/ambient_light_service.dart';
import 'package:opencore_tv/providers/settings_service.dart';
import 'package:opencore_tv/providers/weather_service.dart';

enum OpenCoreAppearanceBrightness { dark, light }

class AppearanceService extends ChangeNotifier {
  final SettingsService _settings;
  final AmbientLightService _ambientLight;
  final WeatherService _weather;

  OpenCoreAppearanceBrightness _activeBrightness =
      OpenCoreAppearanceBrightness.dark;

  AppearanceService(this._settings, this._ambientLight, this._weather) {
    _settings.addListener(_recompute);
    _ambientLight.addListener(_recompute);
    _weather.addListener(_recompute);
    _recompute();
  }

  OpenCoreAppearanceBrightness get activeBrightness => _activeBrightness;
  bool get isLight => _activeBrightness == OpenCoreAppearanceBrightness.light;
  String get mode => _settings.appearanceMode;

  String get statusLabel {
    final source = switch (_settings.appearanceMode) {
      APPEARANCE_MODE_LIGHT => "Light",
      APPEARANCE_MODE_AUTO_HYBRID =>
        _ambientLight.available ? "Hybrid room light" : "Hybrid sun fallback",
      APPEARANCE_MODE_AUTO_SENSOR =>
        _ambientLight.available ? "Room light" : "Room light unavailable",
      APPEARANCE_MODE_AUTO_SUN => "Sunrise/sunset",
      _ => "Dark",
    };
    return "$source -> ${isLight ? "Light" : "Dark"}";
  }

  void _recompute() {
    final next = _resolveBrightness();
    if (next == _activeBrightness) return;
    _activeBrightness = next;
    notifyListeners();
  }

  OpenCoreAppearanceBrightness _resolveBrightness() {
    return switch (_settings.appearanceMode) {
      APPEARANCE_MODE_LIGHT => OpenCoreAppearanceBrightness.light,
      APPEARANCE_MODE_AUTO_HYBRID => _ambientLight.available
          ? (_ambientLight.recommendsLight
              ? OpenCoreAppearanceBrightness.light
              : OpenCoreAppearanceBrightness.dark)
          : _sunBrightness(),
      APPEARANCE_MODE_AUTO_SENSOR => _ambientLight.available
          ? (_ambientLight.recommendsLight
              ? OpenCoreAppearanceBrightness.light
              : OpenCoreAppearanceBrightness.dark)
          : OpenCoreAppearanceBrightness.dark,
      APPEARANCE_MODE_AUTO_SUN => _sunBrightness(),
      _ => OpenCoreAppearanceBrightness.dark,
    };
  }

  OpenCoreAppearanceBrightness _sunBrightness() {
    return _weather.isDaylight
        ? OpenCoreAppearanceBrightness.light
        : OpenCoreAppearanceBrightness.dark;
  }

  @override
  void dispose() {
    _settings.removeListener(_recompute);
    _ambientLight.removeListener(_recompute);
    _weather.removeListener(_recompute);
    super.dispose();
  }
}
