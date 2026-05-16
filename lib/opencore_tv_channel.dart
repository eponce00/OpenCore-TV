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

import 'package:flutter/services.dart';

class OpenCoreTVChannel {
  static const _methodChannel = MethodChannel('tv.opencore.launcher/method');
  static const _appsEventChannel =
      EventChannel('tv.opencore.launcher/event_apps');
  static const _networkEventChannel =
      EventChannel('tv.opencore.launcher/event_network');
  static const _lightSensorEventChannel =
      EventChannel('tv.opencore.launcher/event_light_sensor');
  static VoidCallback? _enterIdleListener;
  static VoidCallback? _dismissPanelListener;
  static VoidCallback? _remoteMenuListener;
  static VoidCallback? _inputSelectorListener;

  static void setEnterIdleListener(VoidCallback? listener) {
    _enterIdleListener = listener;
    _installMethodHandler();
  }

  static void setDismissPanelListener(VoidCallback? listener) {
    _dismissPanelListener = listener;
    _installMethodHandler();
  }

  static void setRemoteMenuListener(VoidCallback? listener) {
    _remoteMenuListener = listener;
    _installMethodHandler();
  }

  static void setInputSelectorListener(VoidCallback? listener) {
    _inputSelectorListener = listener;
    _installMethodHandler();
  }

  static void _installMethodHandler() {
    _methodChannel.setMethodCallHandler((call) async {
      if (call.method == "enterIdle") {
        _enterIdleListener?.call();
      } else if (call.method == "dismissPanel") {
        _dismissPanelListener?.call();
      } else if (call.method == "remoteMenu") {
        _remoteMenuListener?.call();
      } else if (call.method == "showInputSelector") {
        _inputSelectorListener?.call();
      }
    });
  }

  Future<List<Map<dynamic, dynamic>>> getApplications() async {
    List<Map<dynamic, dynamic>>? applications =
        await _methodChannel.invokeListMethod("getApplications");
    return applications!;
  }

  Future<Uint8List> getApplicationBanner(String packageName) async {
    Uint8List bytes =
        await _methodChannel.invokeMethod("getApplicationBanner", packageName);
    return bytes;
  }

  Future<Uint8List> getApplicationIcon(String packageName) async {
    Uint8List bytes =
        await _methodChannel.invokeMethod("getApplicationIcon", packageName);
    return bytes;
  }

  Future<bool> applicationExists(String packageName) async =>
      await _methodChannel.invokeMethod('applicationExists', packageName);

  Future<void> launchActivityFromAction(String action) async =>
      await _methodChannel.invokeMethod('launchActivityFromAction', action);

  Future<void> launchApp(String packageName) async =>
      await _methodChannel.invokeMethod('launchApp', packageName);

  Future<void> openSettings() async =>
      await _methodChannel.invokeMethod('openSettings');

  Future<void> setPanelOpen(bool open) async =>
      await _methodChannel.invokeMethod('setPanelOpen', open);

  Future<bool> isHomeGuardEnabled() async =>
      await _methodChannel.invokeMethod('isHomeGuardEnabled');

  Future<bool> repairHomeGuard() async =>
      await _methodChannel.invokeMethod('repairHomeGuard');

  Future<bool> openAccessibilitySettings() async =>
      await _methodChannel.invokeMethod('openAccessibilitySettings');

  Future<void> openAppInfo(String packageName) async =>
      await _methodChannel.invokeMethod('openAppInfo', packageName);

  Future<void> uninstallApp(String packageName) async =>
      await _methodChannel.invokeMethod('uninstallApp', packageName);

  Future<bool> isDefaultLauncher() async =>
      await _methodChannel.invokeMethod('isDefaultLauncher');

  Future<Map<String, dynamic>> getActiveNetworkInformation() async {
    Map<dynamic, dynamic> map =
        await _methodChannel.invokeMethod("getActiveNetworkInformation");
    return map.cast<String, dynamic>();
  }

  Future<int> getDailyWifiUsage() async {
    try {
      final int usage = await _methodChannel.invokeMethod("getDailyWifiUsage");
      return usage;
    } on PlatformException catch (_) {
      return -1;
    }
  }

  Future<int> getWeeklyWifiUsage() async {
    try {
      final int usage = await _methodChannel.invokeMethod("getWeeklyWifiUsage");
      return usage;
    } on PlatformException catch (_) {
      return -1;
    }
  }

  Future<int> getMonthlyWifiUsage() async {
    try {
      final int usage =
          await _methodChannel.invokeMethod("getMonthlyWifiUsage");
      return usage;
    } on PlatformException catch (_) {
      return -1;
    }
  }

  Future<bool> checkUsageStatsPermission() async =>
      await _methodChannel.invokeMethod("checkUsageStatsPermission");

  Future<void> requestUsageStatsPermission() async =>
      await _methodChannel.invokeMethod("requestUsageStatsPermission");

  Future<void> openWifiSettings() async =>
      await _methodChannel.invokeMethod("openWifiSettings");

  Future<bool> installApk(String apkPath) async =>
      await _methodChannel.invokeMethod("installApk", apkPath);

  Future<void> requestInstallUnknownAppsPermission() async =>
      await _methodChannel.invokeMethod("requestInstallUnknownAppsPermission");

  void addAppsChangedListener(void Function(Map<String, dynamic>) listener) =>
      _appsEventChannel.receiveBroadcastStream().listen((event) {
        Map<dynamic, dynamic> eventMap = event;
        listener(eventMap.cast<String, dynamic>());
      });

  void addNetworkChangedListener(
          void Function(Map<String, dynamic>) listener) =>
      _networkEventChannel.receiveBroadcastStream().listen((event) {
        Map<dynamic, dynamic> eventMap = event;
        listener(eventMap.cast<String, dynamic>());
      });

  Stream<Map<String, dynamic>> lightSensorEvents() =>
      _lightSensorEventChannel.receiveBroadcastStream().map((event) {
        final eventMap = event as Map<dynamic, dynamic>;
        return eventMap.cast<String, dynamic>();
      });
}
