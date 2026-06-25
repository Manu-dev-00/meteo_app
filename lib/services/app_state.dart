// lib/services/app_state.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weather_model.dart';
import 'weather_service.dart';

class AppState extends ChangeNotifier {
  // ── État courant ──────────────────────────────────────────────────────────
  String city = 'Lomé';
  double lat = 6.1375;
  double lon = 1.2123;
  String countryCode = 'TG';
  bool isMetric = true;
  bool isLoading = false;
  String? errorMessage;

  WeatherData? weatherData;
  List<FavoriteCity> favorites = [];
  List<FavoriteCity> recent = [];
  List<JournalEntry> journalEntries = [];

  AppState() {
    _loadPreferences();
  }

  // ── Conversion de température ─────────────────────────────────────────────
  double convertTemp(double celsius) =>
      isMetric ? celsius : celsius * 9 / 5 + 32;

  String get unitLabel => isMetric ? '°C' : '°F';
  String get speedUnit => isMetric ? 'km/h' : 'mph';

  // ── Chargement des préférences ────────────────────────────────────────────
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    isMetric = prefs.getString('unit') != 'imperial';

    final favsJson = prefs.getStringList('favorites') ?? [];
    favorites = favsJson.map((s) => FavoriteCity.fromJson(jsonDecode(s))).toList();

    final recentJson = prefs.getStringList('recent') ?? [];
    recent = recentJson.map((s) => FavoriteCity.fromJson(jsonDecode(s))).toList();

    final journalJson = prefs.getStringList('weatherJournal') ?? [];
    journalEntries = journalJson.map((s) => JournalEntry.fromJson(jsonDecode(s))).toList();

    notifyListeners();
    await fetchWeather(lat, lon, city, countryCode);
  }

  // ── Récupération météo ────────────────────────────────────────────────────
  Future<void> fetchWeather(double newLat, double newLon, String newCity, String newCountry) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final data = await WeatherService.fetchWeather(newLat, newLon);
      weatherData = data;
      lat = newLat;
      lon = newLon;
      city = newCity;
      countryCode = newCountry;
      _addToRecent(newCity, newLat, newLon, newCountry);
    } catch (e) {
      errorMessage = 'Impossible de récupérer la météo';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ── Unité ─────────────────────────────────────────────────────────────────
  Future<void> toggleUnit() async {
    isMetric = !isMetric;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('unit', isMetric ? 'metric' : 'imperial');
    notifyListeners();
  }

  // ── Favoris ───────────────────────────────────────────────────────────────
  bool get isFavorite => favorites.any((f) => f.city == city);

  Future<void> toggleFavorite() async {
    final idx = favorites.indexWhere((f) => f.city == city);
    if (idx == -1) {
      favorites.add(FavoriteCity(city: city, lat: lat, lon: lon, countryCode: countryCode));
    } else {
      favorites.removeAt(idx);
    }
    await _saveFavorites();
    notifyListeners();
  }

  Future<void> clearFavorites() async {
    favorites.clear();
    await _saveFavorites();
    notifyListeners();
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', favorites.map((f) => jsonEncode(f.toJson())).toList());
  }

  // ── Recherches récentes ───────────────────────────────────────────────────
  Future<void> _addToRecent(String c, double la, double lo, String cc) async {
    recent.removeWhere((r) => r.city == c);
    recent.insert(0, FavoriteCity(city: c, lat: la, lon: lo, countryCode: cc));
    if (recent.length > 5) recent = recent.sublist(0, 5);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('recent', recent.map((r) => jsonEncode(r.toJson())).toList());
  }

  // ── Journal ───────────────────────────────────────────────────────────────
  Future<void> saveJournalEntry(int comfort, String notes) async {
    final entry = JournalEntry(
      id: DateTime.now().millisecondsSinceEpoch,
      date: DateTime.now(),
      city: city,
      temp: weatherData?.temperature,
      weatherCode: weatherData?.weatherCode,
      comfort: comfort,
      notes: notes,
    );
    journalEntries.insert(0, entry);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'weatherJournal',
      journalEntries.map((e) => jsonEncode(e.toJson())).toList(),
    );
    notifyListeners();
  }
}
