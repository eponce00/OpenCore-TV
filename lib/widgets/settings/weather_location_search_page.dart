import 'dart:convert';
import 'dart:io';

import 'package:opencore_tv/providers/settings_service.dart';
import 'package:opencore_tv/providers/weather_service.dart';
import 'package:opencore_tv/widgets/settings/focusable_settings_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class WeatherLocationSearchPage extends StatefulWidget {
  static const String routeName = "weather_location_search_panel";

  const WeatherLocationSearchPage({super.key});

  @override
  State<WeatherLocationSearchPage> createState() =>
      _WeatherLocationSearchPageState();
}

class _WeatherLocationSearchPageState extends State<WeatherLocationSearchPage> {
  final TextEditingController _controller = TextEditingController();
  final HttpClient _client = HttpClient();
  List<_WeatherSearchResult> _results = const [];
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    _client.close(force: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text("Find Weather Location",
            style: Theme.of(context).textTheme.titleLarge),
        const Divider(),
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              labelText: "City or US ZIP",
              hintText: "Reno or 89501",
            ),
            onSubmitted: (_) => _search(),
          ),
        ),
        FocusableSettingsTile(
          autofocus: false,
          leading: const Icon(Icons.search),
          title: const Text("Search"),
          onPressed: _search,
        ),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(_error!),
          ),
        Expanded(
          child: ListView(
            children: [
              for (final result in _results)
                FocusableSettingsTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: Text(result.name),
                  onPressed: () => _select(result),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty || _loading) return;

    setState(() {
      _loading = true;
      _error = null;
      _results = const [];
    });

    try {
      final results = RegExp(r"^\d{5}$").hasMatch(query)
          ? await _searchZip(query)
          : await _searchCity(query);
      setState(() {
        _results = results;
        _error = results.isEmpty ? "No matching locations found." : null;
      });
    } catch (_) {
      setState(() {
        _error = "Could not search right now. Check the query and try again.";
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<List<_WeatherSearchResult>> _searchZip(String zip) async {
    final uri = Uri.parse("https://api.zippopotam.us/us/$zip");
    final json = await _getJson(uri);
    final places = (json["places"] as List<dynamic>? ?? const []);
    return places.map((place) {
      final data = place as Map<String, dynamic>;
      final city = data["place name"] as String? ?? zip;
      final state = data["state abbreviation"] as String? ?? "";
      return _WeatherSearchResult(
        "$city, $state $zip",
        double.parse(data["latitude"] as String),
        double.parse(data["longitude"] as String),
      );
    }).toList();
  }

  Future<List<_WeatherSearchResult>> _searchCity(String query) async {
    final uri = Uri.https("geocoding-api.open-meteo.com", "/v1/search", {
      "name": query,
      "count": "8",
      "language": "en",
      "format": "json",
    });
    final json = await _getJson(uri);
    final results = (json["results"] as List<dynamic>? ?? const []);
    return results.map((result) {
      final data = result as Map<String, dynamic>;
      final name = data["name"] as String;
      final admin1 = data["admin1"] as String?;
      final country = data["country_code"] as String? ?? "";
      final label = [
        name,
        if (admin1 != null) admin1,
        country,
      ].where((part) => part.isNotEmpty).join(", ");
      return _WeatherSearchResult(
        label,
        (data["latitude"] as num).toDouble(),
        (data["longitude"] as num).toDouble(),
      );
    }).toList();
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final request = await _client.getUrl(uri);
    final response = await request.close().timeout(const Duration(seconds: 8));
    final body = await response.transform(utf8.decoder).join();
    return jsonDecode(body) as Map<String, dynamic>;
  }

  Future<void> _select(_WeatherSearchResult result) async {
    final settings = context.read<SettingsService>();
    await settings.setWeatherLocation(
      name: result.name,
      latitude: result.latitude,
      longitude: result.longitude,
    );
    if (!mounted) return;
    await context.read<WeatherService>().refresh(force: true);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

class _WeatherSearchResult {
  final String name;
  final double latitude;
  final double longitude;

  const _WeatherSearchResult(this.name, this.latitude, this.longitude);
}
