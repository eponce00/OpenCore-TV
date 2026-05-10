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

import 'dart:io';
import 'dart:async';

import 'package:opencore_tv/opencore_tv_channel.dart';
import 'package:opencore_tv/gradients.dart';
import 'package:opencore_tv/providers/settings_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';

class WallpaperService extends ChangeNotifier {
  static const bundledWallpapers = [
    "assets/wallpapers/wallpaper_01.png",
    "assets/wallpapers/wallpaper_02.png",
    "assets/wallpapers/wallpaper_03.png",
    "assets/wallpapers/wallpaper_04.png",
    "assets/wallpapers/wallpaper_05.png",
    "assets/wallpapers/wallpaper_06.png",
    "assets/wallpapers/wallpaper_07.png",
    "assets/wallpapers/wallpaper_08.png",
    "assets/wallpapers/wallpaper_09.png",
    "assets/wallpapers/wallpaper_10.png",
    "assets/wallpapers/wallpaper_11.png",
    "assets/wallpapers/wallpaper_12.png",
    "assets/wallpapers/wallpaper_13.png",
    "assets/wallpapers/wallpaper_14.png",
    "assets/wallpapers/wallpaper_15.png",
    "assets/wallpapers/wallpaper_16.png",
    "assets/wallpapers/wallpaper_17.png",
    "assets/wallpapers/wallpaper_18.png",
  ];

  final OpenCoreTVChannel _OpenCoreTVChannel;
  final SettingsService _settingsService;

  late File _wallpaperFile;
  late File _wallpaperDayFile;
  late File _wallpaperNightFile;
  late File _wallpaperVideoFile;
  late File _wallpaperDayVideoFile;
  late File _wallpaperNightVideoFile;
  bool _initialized = false;
  Timer? _timer;
  Timer? _rotationTimer;

  ImageProvider? _wallpaper;

  ImageProvider? get wallpaper => _wallpaper;

  File? get wallpaperVideoFile {
    final f = _resolveActiveVideoFile();
    return f != null && f.existsSync() ? f : null;
  }

  OpenCoreTVGradient get gradient => OpenCoreTVGradients.all.firstWhere(
        (gradient) => gradient.uuid == _settingsService.gradientUuid,
        orElse: () => OpenCoreTVGradients.saintPetersburg,
      );

  WallpaperService(this._OpenCoreTVChannel, this._settingsService)
      : _wallpaper = null {
    _settingsService.addListener(_onSettingsChanged);
    _init();
  }

  bool _lastTimeBasedEnabled = false;
  String? _lastBundledWallpaperAsset;

  void _onSettingsChanged() {
    final enabled = _settingsService.timeBasedWallpaperEnabled;
    final bundledWallpaperAsset = _settingsService.bundledWallpaperAsset;
    if (enabled != _lastTimeBasedEnabled ||
        bundledWallpaperAsset != _lastBundledWallpaperAsset) {
      _lastTimeBasedEnabled = enabled;
      _lastBundledWallpaperAsset = bundledWallpaperAsset;
      _updateTimerState();
      _updateWallpaper();
    }
  }

  @override
  void dispose() {
    _settingsService.removeListener(_onSettingsChanged);
    _timer?.cancel();
    _rotationTimer?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    final directory = await getApplicationDocumentsDirectory();
    _wallpaperFile = File("${directory.path}/wallpaper");
    _wallpaperDayFile = File("${directory.path}/wallpaper_day");
    _wallpaperNightFile = File("${directory.path}/wallpaper_night");
    _wallpaperVideoFile = File("${directory.path}/wallpaper_video");
    _wallpaperDayVideoFile = File("${directory.path}/wallpaper_day_video");
    _wallpaperNightVideoFile = File("${directory.path}/wallpaper_night_video");
    _initialized = true;

    _lastTimeBasedEnabled = _settingsService.timeBasedWallpaperEnabled;
    _lastBundledWallpaperAsset = _settingsService.bundledWallpaperAsset;
    _updateWallpaper();
    _updateTimerState();
  }

  void _updateTimerState() {
    final enabled = _settingsService.timeBasedWallpaperEnabled;
    if (enabled && (_timer == null || !_timer!.isActive)) {
      _timer =
          Timer.periodic(const Duration(minutes: 1), (_) => _updateWallpaper());
    } else if (!enabled && _timer != null) {
      _timer?.cancel();
      _timer = null;
    }

    _rotationTimer?.cancel();
    _rotationTimer = null;
    if (_settingsService.wallpaperRotationEnabled) {
      final minutes = _settingsService.wallpaperRotationMinutes.clamp(1, 1440);
      _rotationTimer = Timer.periodic(
        Duration(minutes: minutes),
        (_) => rotateBundledWallpaper(),
      );
    }
  }

  File? _resolveActiveVideoFile() {
    if (!isInitialized) return null;

    final now = DateTime.now();
    final isDay = now.hour >= 6 && now.hour < 18;
    final enabled = _settingsService.timeBasedWallpaperEnabled;

    if (enabled) {
      if (isDay && _wallpaperDayVideoFile.existsSync()) {
        return _wallpaperDayVideoFile;
      }
      if (!isDay && _wallpaperNightVideoFile.existsSync()) {
        return _wallpaperNightVideoFile;
      }
      if (_wallpaperVideoFile.existsSync()) {
        return _wallpaperVideoFile;
      }
    } else if (_wallpaperVideoFile.existsSync()) {
      return _wallpaperVideoFile;
    }
    return null;
  }

  bool get isInitialized => _initialized;

  void _updateWallpaper({bool force = false}) {
    final now = DateTime.now();
    final isDay = now.hour >= 6 && now.hour < 18;
    final enabled = _settingsService.timeBasedWallpaperEnabled;

    final videoFile = _resolveActiveVideoFile();

    ImageProvider? newWallpaper;

    if (videoFile != null) {
      newWallpaper = null;
    } else if (enabled) {
      if (isDay && _wallpaperDayFile.existsSync()) {
        newWallpaper = FileImage(_wallpaperDayFile);
      } else if (!isDay && _wallpaperNightFile.existsSync()) {
        newWallpaper = FileImage(_wallpaperNightFile);
      } else if (_wallpaperFile.existsSync()) {
        newWallpaper = FileImage(_wallpaperFile); // Fallback
      } else if (_settingsService.bundledWallpaperAsset != null) {
        newWallpaper = AssetImage(_settingsService.bundledWallpaperAsset!);
      }
    } else if (_wallpaperFile.existsSync()) {
      newWallpaper = FileImage(_wallpaperFile);
    } else if (_settingsService.bundledWallpaperAsset != null) {
      newWallpaper = AssetImage(_settingsService.bundledWallpaperAsset!);
    }

    if (_wallpaper != newWallpaper || videoFile != null || force) {
      _wallpaper = newWallpaper;
      notifyListeners();
    }
  }

  Future<void> setGradient(OpenCoreTVGradient OpenCoreTVGradient) async {
    await cleanImageWallpaperFiles();
    await cleanVideoWallpaperFiles();

    await _settingsService.setBundledWallpaperAsset(null);
    await _settingsService.setGradientUuid(OpenCoreTVGradient.uuid);
    notifyListeners();
  }

  Future<void> setBundledWallpaper(String asset) async {
    await cleanImageWallpaperFiles();
    await cleanVideoWallpaperFiles();
    await _settingsService.setBundledWallpaperAsset(asset);
    _updateWallpaper(force: true);
  }

  Future<void> rotateBundledWallpaper() async {
    final current = _settingsService.bundledWallpaperAsset;
    final currentIndex = bundledWallpapers.indexOf(current ?? "");
    final nextIndex =
        currentIndex < 0 ? 0 : (currentIndex + 1) % bundledWallpapers.length;
    await setBundledWallpaper(bundledWallpapers[nextIndex]);
  }

  // Cleaning methods

  Future<void> cleanVideoWallpaperFiles() async {
    if (await _wallpaperVideoFile.exists()) {
      await _wallpaperVideoFile.delete();
    }

    if (await _wallpaperDayVideoFile.exists()) {
      await _wallpaperDayVideoFile.delete();
    }

    if (await _wallpaperNightVideoFile.exists()) {
      await _wallpaperNightVideoFile.delete();
    }
  }

  Future<void> cleanImageWallpaperFiles() async {
    if (await _wallpaperFile.exists()) {
      await _wallpaperFile.delete();
    }

    if (await _wallpaperDayFile.exists()) {
      await _wallpaperDayFile.delete();
    }

    if (await _wallpaperNightFile.exists()) {
      await _wallpaperNightFile.delete();
    }
  }
}
