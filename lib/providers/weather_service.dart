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
    if (weatherCode >= 71 && weatherCode <= 77) return "snow";
    if (weatherCode >= 51 && weatherCode <= 82) return "rain";
    if (weatherCode >= 95) return "storm";
    return "cloud";
  }
}

class DailyWeatherForecast {
  final DateTime date;
  final double highTemperature;
  final double lowTemperature;
  final String unitSymbol;
  final int weatherCode;
  final DateTime? sunrise;
  final DateTime? sunset;

  const DailyWeatherForecast({
    required this.date,
    required this.highTemperature,
    required this.lowTemperature,
    required this.unitSymbol,
    required this.weatherCode,
    this.sunrise,
    this.sunset,
  });

  String get condition => WeatherSnapshot(
        temperature: highTemperature,
        unitSymbol: unitSymbol,
        weatherCode: weatherCode,
        updatedAt: date,
      ).condition;

  String get icon => WeatherSnapshot(
        temperature: highTemperature,
        unitSymbol: unitSymbol,
        weatherCode: weatherCode,
        updatedAt: date,
      ).icon;
}

class WeatherService extends ChangeNotifier {
  final SettingsService _settingsService;
  final HttpClient _client = HttpClient();
  Timer? _timer;
  WeatherSnapshot? _snapshot;
  List<DailyWeatherForecast> _forecast = const [];
  DateTime? _todaySunrise;
  DateTime? _todaySunset;
  bool _loading = false;
  String? _lastUnit;
  double? _lastLatitude;
  double? _lastLongitude;

  WeatherSnapshot? get snapshot => _snapshot;
  List<DailyWeatherForecast> get forecast => _forecast;
  DateTime? get todaySunrise => _todaySunrise;
  DateTime? get todaySunset => _todaySunset;
  bool get loading => _loading;

  bool get isDaylight {
    final sunrise = _todaySunrise;
    final sunset = _todaySunset;
    if (sunrise == null || sunset == null) {
      final hour = DateTime.now().hour;
      return hour >= 6 && hour < 18;
    }
    final now = DateTime.now();
    return now.isAfter(sunrise) && now.isBefore(sunset);
  }

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
        "&daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset"
        "&temperature_unit=$unit"
        "&timezone=auto",
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
      _forecast = _parseDailyForecast(json, _snapshot!.unitSymbol);
      _todaySunrise = _forecast.isEmpty ? null : _forecast.first.sunrise;
      _todaySunset = _forecast.isEmpty ? null : _forecast.first.sunset;
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
      if (_forecast.isEmpty) {
        _forecast = _fallbackForecast(_snapshot!);
      }
      _todaySunrise = _forecast.isEmpty ? null : _forecast.first.sunrise;
      _todaySunset = _forecast.isEmpty ? null : _forecast.first.sunset;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  List<DailyWeatherForecast> _parseDailyForecast(
    Map<String, dynamic> json,
    String unitSymbol,
  ) {
    final daily = json["daily"] as Map<String, dynamic>?;
    if (daily == null) return const [];

    final times = (daily["time"] as List<dynamic>? ?? const []);
    final highs = (daily["temperature_2m_max"] as List<dynamic>? ?? const []);
    final lows = (daily["temperature_2m_min"] as List<dynamic>? ?? const []);
    final codes = (daily["weather_code"] as List<dynamic>? ?? const []);
    final sunrises = (daily["sunrise"] as List<dynamic>? ?? const []);
    final sunsets = (daily["sunset"] as List<dynamic>? ?? const []);
    final count = [times.length, highs.length, lows.length, codes.length]
        .reduce((value, element) => value < element ? value : element);

    final forecastDays = count < 7 ? count : 7;

    return List.generate(forecastDays, (index) {
      return DailyWeatherForecast(
        date: DateTime.parse(times[index] as String),
        highTemperature: (highs[index] as num).toDouble(),
        lowTemperature: (lows[index] as num).toDouble(),
        unitSymbol: unitSymbol,
        weatherCode: (codes[index] as num).toInt(),
        sunrise: index < sunrises.length
            ? DateTime.tryParse(sunrises[index] as String)
            : null,
        sunset: index < sunsets.length
            ? DateTime.tryParse(sunsets[index] as String)
            : null,
      );
    });
  }

  List<DailyWeatherForecast> _fallbackForecast(WeatherSnapshot snapshot) {
    final base = DateTime.now();
    return List.generate(7, (index) {
      final date = base.add(Duration(days: index));
      return DailyWeatherForecast(
        date: date,
        highTemperature: snapshot.temperature,
        lowTemperature: snapshot.temperature - 8,
        unitSymbol: snapshot.unitSymbol,
        weatherCode: snapshot.weatherCode,
        sunrise: DateTime(date.year, date.month, date.day, 6),
        sunset: DateTime(date.year, date.month, date.day, 18),
      );
    });
  }

  @override
  void dispose() {
    _settingsService.removeListener(_handleSettingsChanged);
    _timer?.cancel();
    _client.close(force: true);
    super.dispose();
  }
}
