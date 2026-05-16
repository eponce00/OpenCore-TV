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
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:opencore_tv/gradients.dart';
import 'package:opencore_tv/opencore_tv_channel.dart';
import 'package:opencore_tv/providers/appearance_service.dart';
import 'package:opencore_tv/providers/settings_service.dart';
import 'package:path_provider/path_provider.dart';

enum WallpaperBrightness { dark, light }

class WallpaperCatalogEntry {
  final String id;
  final String? asset;
  final String? url;
  final WallpaperBrightness brightness;
  final List<String> categories;
  final bool isDefault;

  const WallpaperCatalogEntry({
    required this.id,
    this.asset,
    this.url,
    required this.brightness,
    required this.categories,
    this.isDefault = false,
  });

  bool get isRemote => url != null && url!.isNotEmpty;
  String get reference => isRemote ? "remote:$id" : asset!;

  factory WallpaperCatalogEntry.fromJson(Map<String, dynamic> json) {
    return WallpaperCatalogEntry(
      id: json["id"] as String,
      asset: json["asset"] as String?,
      url: json["url"] as String?,
      brightness: (json["brightness"] as String?) == "light"
          ? WallpaperBrightness.light
          : WallpaperBrightness.dark,
      categories:
          (json["categories"] as List<dynamic>? ?? const []).cast<String>(),
      isDefault: json["default"] == true,
    );
  }
}

class WallpaperService extends ChangeNotifier {
  static const _remoteCatalogUrl =
      "https://raw.githubusercontent.com/eponce00/OpenCore-TV/main/assets/wallpapers/remote-catalog.json";

  static const bundledWallpapers = [
    "assets/wallpapers/dark/dark_abstract_art_10.webp",
    "assets/wallpapers/dark/dark_architecture_06.webp",
    "assets/wallpapers/dark/dark_earth_07.webp",
    "assets/wallpapers/dark/dark_earth_09.webp",
    "assets/wallpapers/dark/dark_fine_art_05.webp",
    "assets/wallpapers/light/light_abstract_art_01.webp",
    "assets/wallpapers/light/light_architecture_01.webp",
    "assets/wallpapers/light/light_earth_01.webp",
    "assets/wallpapers/light/light_earth_08.webp",
    "assets/wallpapers/light/light_fine_art_01.webp",
  ];

  final OpenCoreTVChannel _OpenCoreTVChannel;
  final SettingsService _settingsService;
  final AppearanceService _appearanceService;

  late File _wallpaperFile;
  late File _wallpaperDayFile;
  late File _wallpaperNightFile;
  late File _wallpaperVideoFile;
  late File _wallpaperDayVideoFile;
  late File _wallpaperNightVideoFile;
  late Directory _remoteWallpaperDirectory;
  bool _initialized = false;
  Timer? _timer;
  Timer? _rotationTimer;
  List<WallpaperCatalogEntry> _catalog = const [];

  ImageProvider? _wallpaper;

  ImageProvider? get wallpaper => _wallpaper;
  List<WallpaperCatalogEntry> get catalog => _catalog;

  ImageProvider imageProviderFor(WallpaperCatalogEntry entry) {
    if (entry.isRemote) {
      final file = _remoteFileFor(entry);
      if (file.existsSync()) {
        return FileImage(file);
      }
      return NetworkImage(entry.url!);
    }
    return AssetImage(entry.asset!);
  }

  List<WallpaperCatalogEntry> get activeCatalog {
    if (_catalog.isEmpty) {
      return bundledWallpapers
          .map(
            (asset) => WallpaperCatalogEntry(
              id: asset.split("/").last.replaceAll(RegExp(r"\.[^.]+$"), ""),
              asset: asset,
              brightness: asset.contains("/light/")
                  ? WallpaperBrightness.light
                  : WallpaperBrightness.dark,
              categories: const ["art"],
            ),
          )
          .toList(growable: false);
    }
    final requestedBrightness = _appearanceService.activeBrightness ==
            OpenCoreAppearanceBrightness.light
        ? WallpaperBrightness.light
        : WallpaperBrightness.dark;
    final matching = _filterCatalog(brightness: requestedBrightness);
    if (matching.isNotEmpty) return matching;
    return _filterCatalog(brightness: WallpaperBrightness.dark);
  }

  File? get wallpaperVideoFile {
    final f = _resolveActiveVideoFile();
    return f != null && f.existsSync() ? f : null;
  }

  OpenCoreTVGradient get gradient => OpenCoreTVGradients.all.firstWhere(
        (gradient) => gradient.uuid == _settingsService.gradientUuid,
        orElse: () => OpenCoreTVGradients.saintPetersburg,
      );

  WallpaperService(
    this._OpenCoreTVChannel,
    this._settingsService,
    this._appearanceService,
  ) : _wallpaper = null {
    _settingsService.addListener(_onSettingsChanged);
    _appearanceService.addListener(_onAppearanceChanged);
    _init();
  }

  bool _lastTimeBasedEnabled = false;
  bool _lastWallpaperRotationEnabled = false;
  int _lastWallpaperRotationMinutes = 30;
  String? _lastBundledWallpaperAsset;
  String _lastAppearanceMode = "";
  String _lastWallpaperCategory = "";

  void _onSettingsChanged() {
    final enabled = _settingsService.timeBasedWallpaperEnabled;
    final rotationEnabled = _settingsService.wallpaperRotationEnabled;
    final rotationMinutes = _settingsService.wallpaperRotationMinutes;
    final bundledWallpaperAsset = _settingsService.bundledWallpaperAsset;
    final wallpaperCategory = _settingsService.wallpaperCategory;
    if (enabled != _lastTimeBasedEnabled ||
        rotationEnabled != _lastWallpaperRotationEnabled ||
        rotationMinutes != _lastWallpaperRotationMinutes ||
        bundledWallpaperAsset != _lastBundledWallpaperAsset ||
        wallpaperCategory != _lastWallpaperCategory) {
      _lastTimeBasedEnabled = enabled;
      _lastWallpaperRotationEnabled = rotationEnabled;
      _lastWallpaperRotationMinutes = rotationMinutes;
      _lastBundledWallpaperAsset = bundledWallpaperAsset;
      _lastWallpaperCategory = wallpaperCategory;
      _updateTimerState();
      _updateWallpaper();
    }
  }

  void _onAppearanceChanged() {
    final mode = _appearanceService.activeBrightness.name;
    if (mode == _lastAppearanceMode) return;
    _lastAppearanceMode = mode;
    _updateWallpaper(force: true);
  }

  @override
  void dispose() {
    _settingsService.removeListener(_onSettingsChanged);
    _appearanceService.removeListener(_onAppearanceChanged);
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
    _remoteWallpaperDirectory =
        Directory("${directory.path}/remote_wallpapers");
    if (!_remoteWallpaperDirectory.existsSync()) {
      _remoteWallpaperDirectory.createSync(recursive: true);
    }
    await _loadCatalog();
    _initialized = true;

    _lastTimeBasedEnabled = _settingsService.timeBasedWallpaperEnabled;
    _lastWallpaperRotationEnabled = _settingsService.wallpaperRotationEnabled;
    _lastWallpaperRotationMinutes = _settingsService.wallpaperRotationMinutes;
    _lastBundledWallpaperAsset = _settingsService.bundledWallpaperAsset;
    _lastWallpaperCategory = _settingsService.wallpaperCategory;
    _lastAppearanceMode = _appearanceService.activeBrightness.name;
    _updateWallpaper();
    _updateTimerState();
  }

  Future<void> _loadCatalog() async {
    final localCatalog = <WallpaperCatalogEntry>[];
    try {
      final jsonString =
          await rootBundle.loadString("assets/wallpapers/catalog.json");
      final entries = jsonDecode(jsonString) as List<dynamic>;
      localCatalog.addAll(entries
          .cast<Map<String, dynamic>>()
          .map(WallpaperCatalogEntry.fromJson)
          .where((entry) => entry.asset != null || entry.url != null));
    } catch (_) {
      localCatalog.addAll(_fallbackCatalog());
    }
    _catalog = localCatalog.toList(growable: false);
    await _loadRemoteCatalog(localCatalog);
  }

  List<WallpaperCatalogEntry> _fallbackCatalog() {
    return bundledWallpapers
        .map(
          (asset) => WallpaperCatalogEntry(
            id: asset.split("/").last.replaceAll(RegExp(r"\.[^.]+$"), ""),
            asset: asset,
            brightness: WallpaperBrightness.dark,
            categories: const ["art"],
          ),
        )
        .toList(growable: false);
  }

  Future<void> _loadRemoteCatalog(
    List<WallpaperCatalogEntry> localCatalog,
  ) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);
      final request = await client.getUrl(Uri.parse(_remoteCatalogUrl));
      final response =
          await request.close().timeout(const Duration(seconds: 8));
      if (response.statusCode != HttpStatus.ok) return;
      final body = await response.transform(utf8.decoder).join();
      final entries = (jsonDecode(body) as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(WallpaperCatalogEntry.fromJson)
          .where((entry) => entry.url != null || entry.asset != null);
      final byId = <String, WallpaperCatalogEntry>{
        for (final entry in localCatalog) entry.id: entry,
      };
      for (final entry in entries) {
        byId.putIfAbsent(entry.id, () => entry);
      }
      _catalog = byId.values.toList(growable: false);
    } catch (_) {
      _catalog = localCatalog.toList(growable: false);
    }
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
        (_) async {
          try {
            await rotateBundledWallpaper();
          } catch (_) {
            // Network-backed wallpapers are optional; keep the current image.
          }
        },
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
      } else {
        newWallpaper = _effectiveBundledWallpaperProvider();
      }
    } else if (_wallpaperFile.existsSync()) {
      newWallpaper = FileImage(_wallpaperFile);
    } else {
      newWallpaper = _effectiveBundledWallpaperProvider();
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

  Future<void> setBundledWallpaper(String reference) async {
    final entry = _entryForReference(reference);
    if (entry != null && entry.isRemote) {
      await _ensureRemoteWallpaperCached(entry);
    }
    await cleanImageWallpaperFiles();
    await cleanVideoWallpaperFiles();
    await _settingsService.setBundledWallpaperAsset(reference);
    _updateWallpaper(force: true);
  }

  Future<void> rotateBundledWallpaper() async {
    final wallpapers = activeCatalog;
    if (wallpapers.isEmpty) return;
    final current = _effectiveBundledWallpaperEntry().reference;
    final currentIndex =
        wallpapers.indexWhere((entry) => entry.reference == current);
    for (var offset = 1; offset <= wallpapers.length; offset++) {
      final nextIndex = currentIndex < 0
          ? offset - 1
          : (currentIndex + offset) % wallpapers.length;
      try {
        await setBundledWallpaper(wallpapers[nextIndex].reference);
        return;
      } catch (_) {
        // Skip unavailable remote entries while rotating.
      }
    }
  }

  ImageProvider _effectiveBundledWallpaperProvider() {
    final entry = _effectiveBundledWallpaperEntry();
    if (entry.isRemote) {
      final file = _remoteFileFor(entry);
      if (file.existsSync()) return FileImage(file);
    }
    final bundled = activeCatalog.firstWhere(
      (candidate) => candidate.asset != null && candidate.isDefault,
      orElse: () => activeCatalog.firstWhere(
        (candidate) => candidate.asset != null,
        orElse: () => entry,
      ),
    );
    return AssetImage(bundled.asset!);
  }

  WallpaperCatalogEntry _effectiveBundledWallpaperEntry() {
    final saved = _settingsService.bundledWallpaperAsset;
    final savedEntry = saved == null ? null : _entryForReference(saved);
    if (savedEntry != null) {
      if (activeCatalog
          .any((entry) => entry.reference == savedEntry.reference)) {
        if (!savedEntry.isRemote || _remoteFileFor(savedEntry).existsSync()) {
          return savedEntry;
        }
      }
    }
    final entries = activeCatalog;
    return entries.firstWhere(
      (entry) =>
          entry.isDefault &&
          (!entry.isRemote || _remoteFileFor(entry).existsSync()),
      orElse: () => entries.firstWhere(
        (entry) => entry.asset != null,
        orElse: () => entries.firstWhere(
          (entry) => !entry.isRemote || _remoteFileFor(entry).existsSync(),
          orElse: () => entries.first,
        ),
      ),
    );
  }

  WallpaperCatalogEntry? _entryForReference(String reference) {
    for (final entry in _catalog) {
      if (entry.reference == reference || entry.asset == reference) {
        return entry;
      }
    }
    return null;
  }

  File _remoteFileFor(WallpaperCatalogEntry entry) {
    final uri = Uri.parse(entry.url!);
    final extension = uri.pathSegments.isEmpty
        ? ".img"
        : ".${uri.pathSegments.last.split(".").last}";
    return File("${_remoteWallpaperDirectory.path}/${entry.id}$extension");
  }

  Future<File> _ensureRemoteWallpaperCached(
    WallpaperCatalogEntry entry,
  ) async {
    final file = _remoteFileFor(entry);
    if (file.existsSync()) return file;
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 10);
    final request = await client.getUrl(Uri.parse(entry.url!));
    final response = await request.close().timeout(const Duration(seconds: 30));
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException("Remote wallpaper download failed");
    }
    final bytes = await consolidateHttpClientResponseBytes(response);
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  List<WallpaperCatalogEntry> _filterCatalog({
    required WallpaperBrightness brightness,
  }) {
    final category = _settingsService.wallpaperCategory;
    return _catalog.where((entry) {
      if (entry.brightness != brightness) return false;
      return category == WALLPAPER_CATEGORY_ALL ||
          entry.categories.contains(category);
    }).toList(growable: false);
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
