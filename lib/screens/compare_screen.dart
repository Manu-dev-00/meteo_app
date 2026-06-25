// lib/screens/compare_screen.dart

import 'package:flutter/material.dart';
import '../models/weather_model.dart';
import '../services/weather_service.dart';
import '../utils/weather_utils.dart';
import '../utils/app_theme.dart';

class CompareScreen extends StatefulWidget {
  const CompareScreen({super.key});
  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  final _ctrl1 = TextEditingController();
  final _ctrl2 = TextEditingController();
  WeatherData? _data1, _data2;
  GeoResult? _place1, _place2;
  bool _loading1 = false, _loading2 = false;
  bool _isMetric = true;

  double _convertTemp(double c) => _isMetric ? c : c * 9 / 5 + 32;
  String get _unitLabel => _isMetric ? '°C' : '°F';

  Future<void> _fetchCity(int slot, String query) async {
    if (query.trim().isEmpty) return;
    setState(() => slot == 1 ? _loading1 = true : _loading2 = true);
    try {
      final results = await WeatherService.searchCity(query);
      if (results.isEmpty) {
        _showMessage('Ville introuvable');
        return;
      }
      final place = results[0];
      final data = await WeatherService.fetchWeather(place.latitude, place.longitude);
      setState(() {
        if (slot == 1) { _place1 = place; _data1 = data; }
        else { _place2 = place; _data2 = data; }
      });
    } catch (_) {
      _showMessage('Erreur lors du chargement');
    } finally {
      setState(() => slot == 1 ? _loading1 = false : _loading2 = false);
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() { _ctrl1.dispose(); _ctrl2.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Comparer la Météo',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                GestureDetector(
                  onTap: () => setState(() => _isMetric = !_isMetric),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: glassDecoration(radius: 10),
                    child: Text(_unitLabel,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF60A5FA))),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _CityColumn(
                    slot: 1, ctrl: _ctrl1, place: _place1, data: _data1,
                    loading: _loading1, isMetric: _isMetric,
                    onSearch: (q) => _fetchCity(1, q),
                    convertTemp: _convertTemp, unitLabel: _unitLabel,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _CityColumn(
                    slot: 2, ctrl: _ctrl2, place: _place2, data: _data2,
                    loading: _loading2, isMetric: _isMetric,
                    onSearch: (q) => _fetchCity(2, q),
                    convertTemp: _convertTemp, unitLabel: _unitLabel,
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CityColumn extends StatelessWidget {
  final int slot;
  final TextEditingController ctrl;
  final GeoResult? place;
  final WeatherData? data;
  final bool loading, isMetric;
  final void Function(String) onSearch;
  final double Function(double) convertTemp;
  final String unitLabel;

  const _CityColumn({
    required this.slot, required this.ctrl, required this.place,
    required this.data, required this.loading, required this.isMetric,
    required this.onSearch, required this.convertTemp, required this.unitLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Input de recherche
        TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Ville ${slot}...',
            prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF), size: 20),
          ),
          onSubmitted: onSearch,
          textInputAction: TextInputAction.search,
        ),
        const SizedBox(height: 12),
        // Résultat
        Expanded(
          child: Container(
            decoration: glassDecoration(radius: 20),
            child: loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
                : data == null || place == null
                    ? Center(
                        child: Text(
                          'Recherchez une ville\npour afficher les données',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[500], fontSize: 13),
                        ),
                      )
                    : _WeatherCompareCard(place: place!, data: data!, convertTemp: convertTemp, unitLabel: unitLabel),
          ),
        ),
      ],
    );
  }
}

class _WeatherCompareCard extends StatelessWidget {
  final GeoResult place;
  final WeatherData data;
  final double Function(double) convertTemp;
  final String unitLabel;

  const _WeatherCompareCard({required this.place, required this.data, required this.convertTemp, required this.unitLabel});

  @override
  Widget build(BuildContext context) {
    final info = getWeatherInfo(data.weatherCode);
    final daily = data.daily.isNotEmpty ? data.daily[0] : null;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(place.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          Text(place.country, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
          const SizedBox(height: 16),
          Icon(info.icon, size: 56, color: info.color),
          const SizedBox(height: 8),
          Text('${convertTemp(data.temperature).round()}$unitLabel',
              style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w700)),
          Text(info.description, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
          const SizedBox(height: 20),
          _row('Humidité', '${data.humidity}%'),
          _row('Vent', '${data.windSpeed.round()} km/h'),
          _row('Prob. Pluie', '${data.hourly.isNotEmpty ? data.hourly[0].precipProbability : '--'}%'),
          if (daily != null) _row('Indice UV', '${daily.uvIndexMax.round()}'),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    ),
  );
}
