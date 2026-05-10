import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'settings_service.dart';

class WeatherSnapshot {
  final double temperature;
  final String unitSymbol;
  final int weatherCode;
  final DateTime updatedAt;

  const WeatherSnapshot({
    required this.temperature,
    required this.unitSymbol,
    required this.weatherCode,
    required this.updatedAt,
  });

  String get condition {
    if (weatherCode == 0) return "Clear";
    if ([1, 2, 3].contains(weatherCode)) return "Partly cloudy";
    if ([45, 48].contains(weatherCode)) return "Fog";
    if (weatherCode >= 51 && weatherCode <= 67) return "Rain";
    if (weatherCode >= 71 && weatherCode <= 77) return "Snow";
    if (weatherCode >= 80 && weatherCode <= 82) return "Showers";
    if (weatherCode >= 95) return "Thunder";
    return "Weather";
  }

  String get icon {
    if (weatherCode == 0) return "sunny";
    if ([1, 2, 3].contains(weatherCode)) return "partly";
    if ([45, 48].contains(weatherCode)) return "fog";
    if (weatherCode >= 51 && weatherCode <= 82) return "rain";
    if (weatherCode >= 71 && weatherCode <= 77) return "snow";
    if (weatherCode >= 95) return "storm";
    return "cloud";
  }
}

class WeatherService extends ChangeNotifier {
  final SettingsService _settingsService;
  final HttpClient _client = HttpClient();
  Timer? _timer;
  WeatherSnapshot? _snapshot;
  bool _loading = false;
  String? _lastUnit;
  double? _lastLatitude;
  double? _lastLongitude;

  WeatherSnapshot? get snapshot => _snapshot;
  bool get loading => _loading;

  WeatherService(this._settingsService) {
    _settingsService.addListener(_handleSettingsChanged);
    refresh();
    _timer = Timer.periodic(const Duration(minutes: 30), (_) => refresh());
  }

  void _handleSettingsChanged() {
    if (_lastUnit != _settingsService.weatherUnit ||
        _lastLatitude != _settingsService.weatherLatitude ||
        _lastLongitude != _settingsService.weatherLongitude) {
      refresh(force: true);
    }
  }

  Future<void> refresh({bool force = false}) async {
    if (_loading) return;
    if (force) {
      _snapshot = null;
    }
    _loading = true;
    notifyListeners();

    try {
      final unit = _settingsService.weatherUnit;
      final latitude = _settingsService.weatherLatitude;
      final longitude = _settingsService.weatherLongitude;
      final uri = Uri.parse(
        "https://api.open-meteo.com/v1/forecast"
        "?latitude=$latitude&longitude=$longitude"
        "&current=temperature_2m,weather_code"
        "&temperature_unit=$unit",
      );
      final request = await _client.getUrl(uri);
      final response =
          await request.close().timeout(const Duration(seconds: 8));
      final body = await response.transform(utf8.decoder).join();
      final json = jsonDecode(body) as Map<String, dynamic>;
      final current = json["current"] as Map<String, dynamic>;
      _snapshot = WeatherSnapshot(
        temperature: (current["temperature_2m"] as num).toDouble(),
        unitSymbol: unit == "celsius" ? "C" : "F",
        weatherCode: (current["weather_code"] as num).toInt(),
        updatedAt: DateTime.now(),
      );
      _lastUnit = unit;
      _lastLatitude = latitude;
      _lastLongitude = longitude;
    } catch (_) {
      _snapshot ??= WeatherSnapshot(
        temperature: _settingsService.weatherUnit == "celsius" ? 22 : 72,
        unitSymbol: _settingsService.weatherUnit == "celsius" ? "C" : "F",
        weatherCode: 1,
        updatedAt: DateTime.now(),
      );
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _settingsService.removeListener(_handleSettingsChanged);
    _timer?.cancel();
    _client.close(force: true);
    super.dispose();
  }
}
