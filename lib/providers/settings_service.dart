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

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

const _appHighlightAnimationEnabledKey = "app_highlight_animation_enabled";
const _appKeyClickEnabledKey = "app_key_click_enabled";
const _autoHideAppBar = "auto_hide_app_bar";
const _gradientUuidKey = "gradient_uuid";
const _dateFormat = "date_format";
const _showCategoryTitles = "show_category_titles";
const _showAppNamesBelowIcons = "show_app_names_below_icons";
const _showDateInStatusBar = "show_date_in_status_bar";
const _showTimeInStatusBar = "show_time_in_status_bar";
const _timeFormat = "time_format";
const _wifiUsagePeriod = "wifi_usage_period";
const _showWifiWidgetInStatusBar = "show_wifi_widget_in_status_bar";
const String _showNetworkIndicatorInStatusBar =
    "show_network_indicator_in_status_bar";
const String _accentColor = "accent_color";
const String _idleClockSize = "idle_clock_size";
const String _idleClockShowDate = "idle_clock_show_date";
const String _idleClockUse24Hour = "idle_clock_use_24_hour";
const String _homeClockSize = "home_clock_size";
const String _dockBackdropFilterDisabled = "dock_backdrop_filter_disabled";
const String _bundledWallpaperAsset = "bundled_wallpaper_asset";
const String _wallpaperRotationEnabled = "wallpaper_rotation_enabled";
const String _wallpaperRotationMinutes = "wallpaper_rotation_minutes";
const String _idleModeEnabled = "idle_mode_enabled";
const String _idleTimeoutMinutes = "idle_timeout_minutes";
const String _weatherUnit = "weather_unit";
const String _weatherLatitude = "weather_latitude";
const String _weatherLongitude = "weather_longitude";
const String _weatherLocationName = "weather_location_name";

// WiFi usage period options
const String WIFI_USAGE_DAILY = "daily";
const String WIFI_USAGE_WEEKLY = "weekly";
const String WIFI_USAGE_MONTHLY = "monthly";

// Accent color presets (hex values)
const String ACCENT_COLOR_PURPLE = "7C4DFF";
const String ACCENT_COLOR_TEAL = "00BFA5";
const String ACCENT_COLOR_BLUE = "2979FF";
const String ACCENT_COLOR_ORANGE = "FF6D00";
const String ACCENT_COLOR_PINK = "F50057";
const String ACCENT_COLOR_GREEN = "00C853";
const String ACCENT_COLOR_WHITE = "FFFFFF";
const String ACCENT_COLOR_YELLOW = "FFD600";
const String ACCENT_COLOR_RED = "D50000";
const String ACCENT_COLOR_CYAN = "00E5FF";
const String ACCENT_COLOR_INDIGO = "536DFE";
const String ACCENT_COLOR_LIME = "AEEA00";
const String ACCENT_COLOR_AMBER = "FFAB00";
const String ACCENT_COLOR_ROSE = "FF4081";
const String ACCENT_COLOR_ICE_BLUE = "80D8FF";

class SettingsService extends ChangeNotifier {
  static final defaultDateFormat = "EEEE d";
  static final defaultTimeFormat = "H:mm";
  final SharedPreferences _sharedPreferences;

  bool get appHighlightAnimationEnabled =>
      _sharedPreferences.getBool(_appHighlightAnimationEnabledKey) ?? false;

  bool get appKeyClickEnabled =>
      _sharedPreferences.getBool(_appKeyClickEnabledKey) ?? true;

  bool get autoHideAppBarEnabled =>
      _sharedPreferences.getBool(_autoHideAppBar) ?? false;

  bool get showCategoryTitles =>
      _sharedPreferences.getBool(_showCategoryTitles) ?? false;

  bool get showAppNamesBelowIcons =>
      _sharedPreferences.getBool(_showAppNamesBelowIcons) ?? false;

  bool get showDateInStatusBar =>
      _sharedPreferences.getBool(_showDateInStatusBar) ?? false;

  bool get showTimeInStatusBar =>
      _sharedPreferences.getBool(_showTimeInStatusBar) ?? true;

  String? get gradientUuid => _sharedPreferences.getString(_gradientUuidKey);

  String get dateFormat =>
      _sharedPreferences.getString(_dateFormat) ?? defaultDateFormat;

  String get timeFormat =>
      _sharedPreferences.getString(_timeFormat) ?? defaultTimeFormat;

  String get wifiUsagePeriod =>
      _sharedPreferences.getString(_wifiUsagePeriod) ?? WIFI_USAGE_DAILY;

  bool get showWifiWidgetInStatusBar =>
      _sharedPreferences.getBool(_showWifiWidgetInStatusBar) ?? false;

  bool get showNetworkIndicatorInStatusBar =>
      _sharedPreferences.getBool(_showNetworkIndicatorInStatusBar) ?? true;

  String get accentColorHex =>
      _sharedPreferences.getString(_accentColor) ?? ACCENT_COLOR_WHITE;

  String get idleClockSize =>
      _sharedPreferences.getString(_idleClockSize) ?? "large";

  bool get idleClockShowDate =>
      _sharedPreferences.getBool(_idleClockShowDate) ?? false;

  bool get idleClockUse24Hour =>
      _sharedPreferences.getBool(_idleClockUse24Hour) ?? false;

  String get homeClockSize =>
      _sharedPreferences.getString(_homeClockSize) ?? "large";

  bool get dockBackdropFilterDisabled =>
      _sharedPreferences.getBool(_dockBackdropFilterDisabled) ?? false;

  String? get bundledWallpaperAsset {
    final asset = _sharedPreferences.getString(_bundledWallpaperAsset);
    if (asset == "") return null;
    return asset ?? "assets/wallpapers/wallpaper_01.jpg";
  }

  bool get wallpaperRotationEnabled =>
      _sharedPreferences.getBool(_wallpaperRotationEnabled) ?? false;

  int get wallpaperRotationMinutes =>
      _sharedPreferences.getInt(_wallpaperRotationMinutes) ?? 30;

  bool get idleModeEnabled =>
      _sharedPreferences.getBool(_idleModeEnabled) ?? true;

  int get idleTimeoutMinutes =>
      _sharedPreferences.getInt(_idleTimeoutMinutes) ?? 5;

  String get weatherUnit =>
      _sharedPreferences.getString(_weatherUnit) ?? "fahrenheit";

  double get weatherLatitude =>
      _sharedPreferences.getDouble(_weatherLatitude) ?? 34.0522;

  double get weatherLongitude =>
      _sharedPreferences.getDouble(_weatherLongitude) ?? -118.2437;

  String get weatherLocationName =>
      _sharedPreferences.getString(_weatherLocationName) ?? "Los Angeles";

  Color get accentColor {
    final hex = accentColorHex;
    return Color(int.parse("0xFF$hex"));
  }

  SettingsService(this._sharedPreferences);

  Future<void> set(String key, bool value) async {
    await _sharedPreferences.setBool(key, value);
    notifyListeners();
  }

  Future<void> setAppHighlightAnimationEnabled(bool value) async {
    return set(_appHighlightAnimationEnabledKey, value);
  }

  Future<void> setAppKeyClickEnabled(bool value) async {
    return set(_appKeyClickEnabledKey, value);
  }

  Future<void> setAutoHideAppBarEnabled(bool value) async {
    return set(_autoHideAppBar, value);
  }

  Future<void> setGradientUuid(String value) async {
    await _sharedPreferences.setString(_gradientUuidKey, value);
    notifyListeners();
  }

  Future<void> setDateTimeFormat(
      String dateFormatString, String timeFormatString) async {
    await Future.wait([
      _sharedPreferences.setString(_dateFormat, dateFormatString),
      _sharedPreferences.setString(_timeFormat, timeFormatString)
    ]);
    notifyListeners();
  }

  Future<void> setShowCategoryTitles(bool show) async {
    return set(_showCategoryTitles, show);
  }

  Future<void> setShowAppNamesBelowIcons(bool show) async {
    return set(_showAppNamesBelowIcons, show);
  }

  Future<void> setShowDateInStatusBar(bool show) async {
    return set(_showDateInStatusBar, show);
  }

  Future<void> setShowTimeInStatusBar(bool show) async {
    return set(_showTimeInStatusBar, show);
  }

  Future<void> setWifiUsagePeriod(String period) async {
    await _sharedPreferences.setString(_wifiUsagePeriod, period);
    notifyListeners();
  }

  Future<void> setShowWifiWidgetInStatusBar(bool show) async {
    return set(_showWifiWidgetInStatusBar, show);
  }

  Future<void> setShowNetworkIndicatorInStatusBar(bool show) async {
    return set(_showNetworkIndicatorInStatusBar, show);
  }

  Future<void> setAccentColor(String colorHex) async {
    await _sharedPreferences.setString(_accentColor, colorHex);
    notifyListeners();
  }

  Future<void> setIdleClockSize(String size) async {
    await _sharedPreferences.setString(_idleClockSize, size);
    notifyListeners();
  }

  Future<void> setIdleClockShowDate(bool show) async {
    await _sharedPreferences.setBool(_idleClockShowDate, show);
    notifyListeners();
  }

  Future<void> setIdleClockUse24Hour(bool enabled) async {
    await _sharedPreferences.setBool(_idleClockUse24Hour, enabled);
    notifyListeners();
  }

  Future<void> setHomeClockSize(String size) async {
    await _sharedPreferences.setString(_homeClockSize, size);
    notifyListeners();
  }

  Future<void> setDockBackdropFilterDisabled(bool value) async {
    return set(_dockBackdropFilterDisabled, value);
  }

  Future<void> setBundledWallpaperAsset(String? asset) async {
    await _sharedPreferences.setString(_bundledWallpaperAsset, asset ?? "");
    notifyListeners();
  }

  Future<void> setWallpaperRotationEnabled(bool enabled) async {
    await _sharedPreferences.setBool(_wallpaperRotationEnabled, enabled);
    notifyListeners();
  }

  Future<void> setWallpaperRotationMinutes(int minutes) async {
    await _sharedPreferences.setInt(_wallpaperRotationMinutes, minutes);
    notifyListeners();
  }

  Future<void> setIdleModeEnabled(bool enabled) async {
    await _sharedPreferences.setBool(_idleModeEnabled, enabled);
    notifyListeners();
  }

  Future<void> setIdleTimeoutMinutes(int minutes) async {
    await _sharedPreferences.setInt(_idleTimeoutMinutes, minutes);
    notifyListeners();
  }

  Future<void> setWeatherUnit(String unit) async {
    await _sharedPreferences.setString(_weatherUnit, unit);
    notifyListeners();
  }

  Future<void> setWeatherLocation({
    required String name,
    required double latitude,
    required double longitude,
  }) async {
    await Future.wait([
      _sharedPreferences.setString(_weatherLocationName, name),
      _sharedPreferences.setDouble(_weatherLatitude, latitude),
      _sharedPreferences.setDouble(_weatherLongitude, longitude),
    ]);
    notifyListeners();
  }

  String inputLabel(String packageName, String fallback) =>
      _sharedPreferences.getString("input_label_$packageName") ?? fallback;

  String inputIcon(String packageName) =>
      _sharedPreferences.getString("input_icon_$packageName") ?? "tv";

  Future<void> setInputLabel(String packageName, String label) async {
    await _sharedPreferences.setString("input_label_$packageName",
        label.trim().isEmpty ? defaultInputLabel(packageName) : label.trim());
    notifyListeners();
  }

  Future<void> setInputIcon(String packageName, String icon) async {
    await _sharedPreferences.setString("input_icon_$packageName", icon);
    notifyListeners();
  }

  String defaultInputLabel(String packageName) {
    return switch (packageName) {
      "opencore.input.hdmi1" => "HDMI 1",
      "opencore.input.hdmi2" => "HDMI 2",
      "opencore.input.hdmi3" => "HDMI 3",
      "opencore.input.hdmi4" => "HDMI 4",
      "opencore.input.antenna" => "Antenna",
      "opencore.input.composite" => "Composite",
      _ => "Input",
    };
  }

  bool get timeBasedWallpaperEnabled =>
      _sharedPreferences.getBool("time_based_wallpaper_enabled") ?? false;

  Future<void> setTimeBasedWallpaperEnabled(bool enabled) async {
    await _sharedPreferences.setBool("time_based_wallpaper_enabled", enabled);
    notifyListeners();
  }
}
