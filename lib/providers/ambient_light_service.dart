import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:opencore_tv/opencore_tv_channel.dart';

enum AmbientLightRecommendation { dark, light }

class AmbientLightService extends ChangeNotifier {
  static const double darkThresholdLux = 10;
  static const double lightThresholdLux = 50;

  final OpenCoreTVChannel _channel;
  StreamSubscription<Map<String, dynamic>>? _subscription;
  final List<double> _samples = [];
  bool _available = false;
  String _sensorName = "";
  double? _lux;
  AmbientLightRecommendation _recommendation = AmbientLightRecommendation.dark;

  AmbientLightService(this._channel) {
    _subscription = _channel.lightSensorEvents().listen(_handleSensorEvent);
  }

  bool get available => _available;
  String get sensorName => _sensorName;
  double? get lux => _lux;
  AmbientLightRecommendation get recommendation => _recommendation;
  bool get recommendsLight =>
      _recommendation == AmbientLightRecommendation.light;

  void _handleSensorEvent(Map<String, dynamic> event) {
    _available = event["available"] == true;
    _sensorName = event["sensorName"] as String? ?? "";
    final value = event["lux"];
    if (value is num) {
      _addSample(value.toDouble());
    }
    notifyListeners();
  }

  void _addSample(double value) {
    _samples.add(value);
    if (_samples.length > 12) {
      _samples.removeAt(0);
    }
    _lux = _samples.reduce((a, b) => a + b) / _samples.length;
    if (_lux! <= darkThresholdLux) {
      _recommendation = AmbientLightRecommendation.dark;
    } else if (_lux! >= lightThresholdLux) {
      _recommendation = AmbientLightRecommendation.light;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
