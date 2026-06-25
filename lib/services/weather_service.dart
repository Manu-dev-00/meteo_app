import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';

class WeatherService {
  static const _openMeteoBase = 'https://api.open-meteo.com/v1';
  static const _geoBase = 'https://geocoding-api.open-meteo.com/v1';

  /// Récupère la météo pour des coordonnées données
  static Future<WeatherData> fetchWeather(double lat, double lon) async {
    final uri = Uri.parse(
      '$_openMeteoBase/forecast'
      '?latitude=$lat&longitude=$lon'
      '&current_weather=true'
      '&hourly=temperature_2m,apparent_temperature,relativehumidity_2m,'
      'precipitation_probability,weathercode,visibility,windspeed_10m,surface_pressure'
      '&daily=weathercode,temperature_2m_max,temperature_2m_min,sunrise,sunset,uv_index_max'
      '&timezone=auto',
    );
    final res = await http.get(uri);
    if (res.statusCode != 200) throw Exception('Erreur API météo');
    return WeatherData.fromJson(jsonDecode(res.body));
  }

  /// Recherche des villes par nom
  static Future<List<GeoResult>> searchCity(String query) async {
    final uri = Uri.parse(
      '$_geoBase/search?name=${Uri.encodeComponent(query)}&count=5&language=fr&format=json',
    );
    final res = await http.get(uri);
    if (res.statusCode != 200) return [];
    final data = jsonDecode(res.body);
    final results = data['results'] as List<dynamic>?;
    if (results == null) return [];
    return results.map((r) => GeoResult.fromJson(r as Map<String, dynamic>)).toList();
  }

  /// Récupère les infos d'un pays
  static Future<Map<String, dynamic>?> fetchCountryInfo(String countryCode) async {
    if (countryCode.isEmpty) return null;
    final code = countryCode.toUpperCase();

    // Tentative API REST Countries v3.1
    try {
      final uri = Uri.parse(
        'https://restcountries.com/v3.1/alpha/$code'
        '?fields=name,capital,population,region,subregion,area,currencies,languages,timezones,borders,flags',
      );
      final res = await http.get(uri, headers: {'Accept': 'application/json'});
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body is List && body.isNotEmpty) return body[0] as Map<String, dynamic>;
        if (body is Map<String, dynamic> && body.containsKey('name')) return body;
      }
    } catch (_) {}

    // Fallback : base locale (toujours disponible)
    final local = _countryDatabase[code];
    if (local != null) {
      return {
        'name': {'common': local['name']},
        'capital': [local['capital']],
        'population': local['population'],
        'region': local['region'],
        'subregion': local['subregion'],
        'area': local['area'],
        'currencies': {local['currency']: {'name': local['currencyName']}},
        'languages': {'lang': local['language']},
        'timezones': [local['timezone']],
        'borders': local['borders'], // int ici
        'flags': {'png': 'https://flagcdn.com/w320/${code.toLowerCase()}.png'},
      };
    }

    return null;
  }

  static const _countryDatabase = <String, Map<String, dynamic>>{
    'TG': {'name': 'Togo', 'capital': 'Lomé', 'population': 8478250, 'region': 'Afrique', 'subregion': 'Afrique de l\'Ouest', 'area': 56785.0, 'currency': 'XOF', 'currencyName': 'Franc CFA', 'language': 'Français', 'timezone': 'UTC+00:00', 'borders': 3},
    'BJ': {'name': 'Bénin', 'capital': 'Porto-Novo', 'population': 12123198, 'region': 'Afrique', 'subregion': 'Afrique de l\'Ouest', 'area': 112622.0, 'currency': 'XOF', 'currencyName': 'Franc CFA', 'language': 'Français', 'timezone': 'UTC+01:00', 'borders': 4},
    'GH': {'name': 'Ghana', 'capital': 'Accra', 'population': 31072940, 'region': 'Afrique', 'subregion': 'Afrique de l\'Ouest', 'area': 238533.0, 'currency': 'GHS', 'currencyName': 'Cedi', 'language': 'Anglais', 'timezone': 'UTC+00:00', 'borders': 3},
    'NG': {'name': 'Nigéria', 'capital': 'Abuja', 'population': 206139587, 'region': 'Afrique', 'subregion': 'Afrique de l\'Ouest', 'area': 923768.0, 'currency': 'NGN', 'currencyName': 'Naira', 'language': 'Anglais', 'timezone': 'UTC+01:00', 'borders': 4},
    'CI': {'name': 'Côte d\'Ivoire', 'capital': 'Yamoussoukro', 'population': 26378274, 'region': 'Afrique', 'subregion': 'Afrique de l\'Ouest', 'area': 322463.0, 'currency': 'XOF', 'currencyName': 'Franc CFA', 'language': 'Français', 'timezone': 'UTC+00:00', 'borders': 6},
    'SN': {'name': 'Sénégal', 'capital': 'Dakar', 'population': 16743859, 'region': 'Afrique', 'subregion': 'Afrique de l\'Ouest', 'area': 196722.0, 'currency': 'XOF', 'currencyName': 'Franc CFA', 'language': 'Français', 'timezone': 'UTC+00:00', 'borders': 5},
    'CM': {'name': 'Cameroun', 'capital': 'Yaoundé', 'population': 26545864, 'region': 'Afrique', 'subregion': 'Afrique Centrale', 'area': 475442.0, 'currency': 'XAF', 'currencyName': 'Franc CFA', 'language': 'Français', 'timezone': 'UTC+01:00', 'borders': 6},
    'ML': {'name': 'Mali', 'capital': 'Bamako', 'population': 20250834, 'region': 'Afrique', 'subregion': 'Afrique de l\'Ouest', 'area': 1240192.0, 'currency': 'XOF', 'currencyName': 'Franc CFA', 'language': 'Français', 'timezone': 'UTC+00:00', 'borders': 7},
    'BF': {'name': 'Burkina Faso', 'capital': 'Ouagadougou', 'population': 20903278, 'region': 'Afrique', 'subregion': 'Afrique de l\'Ouest', 'area': 274222.0, 'currency': 'XOF', 'currencyName': 'Franc CFA', 'language': 'Français', 'timezone': 'UTC+00:00', 'borders': 6},
    'NE': {'name': 'Niger', 'capital': 'Niamey', 'population': 24206636, 'region': 'Afrique', 'subregion': 'Afrique de l\'Ouest', 'area': 1267000.0, 'currency': 'XOF', 'currencyName': 'Franc CFA', 'language': 'Français', 'timezone': 'UTC+01:00', 'borders': 7},
    'MA': {'name': 'Maroc', 'capital': 'Rabat', 'population': 36910558, 'region': 'Afrique', 'subregion': 'Afrique du Nord', 'area': 446550.0, 'currency': 'MAD', 'currencyName': 'Dirham', 'language': 'Arabe', 'timezone': 'UTC+01:00', 'borders': 2},
    'DZ': {'name': 'Algérie', 'capital': 'Alger', 'population': 43851043, 'region': 'Afrique', 'subregion': 'Afrique du Nord', 'area': 2381741.0, 'currency': 'DZD', 'currencyName': 'Dinar', 'language': 'Arabe', 'timezone': 'UTC+01:00', 'borders': 6},
    'EG': {'name': 'Égypte', 'capital': 'Le Caire', 'population': 102334403, 'region': 'Afrique', 'subregion': 'Afrique du Nord', 'area': 1002450.0, 'currency': 'EGP', 'currencyName': 'Livre égyptienne', 'language': 'Arabe', 'timezone': 'UTC+02:00', 'borders': 4},
    'ZA': {'name': 'Afrique du Sud', 'capital': 'Pretoria', 'population': 59308690, 'region': 'Afrique', 'subregion': 'Afrique Australe', 'area': 1221037.0, 'currency': 'ZAR', 'currencyName': 'Rand', 'language': 'Zoulou', 'timezone': 'UTC+02:00', 'borders': 5},
    'KE': {'name': 'Kenya', 'capital': 'Nairobi', 'population': 53771296, 'region': 'Afrique', 'subregion': 'Afrique de l\'Est', 'area': 580367.0, 'currency': 'KES', 'currencyName': 'Shilling', 'language': 'Swahili', 'timezone': 'UTC+03:00', 'borders': 5},
    'ET': {'name': 'Éthiopie', 'capital': 'Addis-Abeba', 'population': 114963583, 'region': 'Afrique', 'subregion': 'Afrique de l\'Est', 'area': 1104300.0, 'currency': 'ETB', 'currencyName': 'Birr', 'language': 'Amharique', 'timezone': 'UTC+03:00', 'borders': 6},
    'FR': {'name': 'France', 'capital': 'Paris', 'population': 67391582, 'region': 'Europe', 'subregion': 'Europe de l\'Ouest', 'area': 551695.0, 'currency': 'EUR', 'currencyName': 'Euro', 'language': 'Français', 'timezone': 'UTC+01:00', 'borders': 8},
    'DE': {'name': 'Allemagne', 'capital': 'Berlin', 'population': 83240525, 'region': 'Europe', 'subregion': 'Europe de l\'Ouest', 'area': 357114.0, 'currency': 'EUR', 'currencyName': 'Euro', 'language': 'Allemand', 'timezone': 'UTC+01:00', 'borders': 9},
    'GB': {'name': 'Royaume-Uni', 'capital': 'Londres', 'population': 67215293, 'region': 'Europe', 'subregion': 'Europe du Nord', 'area': 242900.0, 'currency': 'GBP', 'currencyName': 'Livre sterling', 'language': 'Anglais', 'timezone': 'UTC+00:00', 'borders': 1},
    'ES': {'name': 'Espagne', 'capital': 'Madrid', 'population': 46754783, 'region': 'Europe', 'subregion': 'Europe du Sud', 'area': 505990.0, 'currency': 'EUR', 'currencyName': 'Euro', 'language': 'Espagnol', 'timezone': 'UTC+01:00', 'borders': 5},
    'IT': {'name': 'Italie', 'capital': 'Rome', 'population': 60461828, 'region': 'Europe', 'subregion': 'Europe du Sud', 'area': 301336.0, 'currency': 'EUR', 'currencyName': 'Euro', 'language': 'Italien', 'timezone': 'UTC+01:00', 'borders': 6},
    'PT': {'name': 'Portugal', 'capital': 'Lisbonne', 'population': 10196707, 'region': 'Europe', 'subregion': 'Europe du Sud', 'area': 92212.0, 'currency': 'EUR', 'currencyName': 'Euro', 'language': 'Portugais', 'timezone': 'UTC+00:00', 'borders': 1},
    'BE': {'name': 'Belgique', 'capital': 'Bruxelles', 'population': 11589616, 'region': 'Europe', 'subregion': 'Europe de l\'Ouest', 'area': 30528.0, 'currency': 'EUR', 'currencyName': 'Euro', 'language': 'Français', 'timezone': 'UTC+01:00', 'borders': 4},
    'CH': {'name': 'Suisse', 'capital': 'Berne', 'population': 8654618, 'region': 'Europe', 'subregion': 'Europe de l\'Ouest', 'area': 41285.0, 'currency': 'CHF', 'currencyName': 'Franc suisse', 'language': 'Allemand', 'timezone': 'UTC+01:00', 'borders': 5},
    'RU': {'name': 'Russie', 'capital': 'Moscou', 'population': 145934460, 'region': 'Europe', 'subregion': 'Europe de l\'Est', 'area': 17098242.0, 'currency': 'RUB', 'currencyName': 'Rouble', 'language': 'Russe', 'timezone': 'UTC+03:00', 'borders': 14},
    'US': {'name': 'États-Unis', 'capital': 'Washington D.C.', 'population': 329484123, 'region': 'Amériques', 'subregion': 'Amérique du Nord', 'area': 9372610.0, 'currency': 'USD', 'currencyName': 'Dollar américain', 'language': 'Anglais', 'timezone': 'UTC-05:00', 'borders': 2},
    'CA': {'name': 'Canada', 'capital': 'Ottawa', 'population': 38005238, 'region': 'Amériques', 'subregion': 'Amérique du Nord', 'area': 9984670.0, 'currency': 'CAD', 'currencyName': 'Dollar canadien', 'language': 'Anglais', 'timezone': 'UTC-05:00', 'borders': 1},
    'MX': {'name': 'Mexique', 'capital': 'Mexico', 'population': 128932753, 'region': 'Amériques', 'subregion': 'Amérique Centrale', 'area': 1964375.0, 'currency': 'MXN', 'currencyName': 'Peso mexicain', 'language': 'Espagnol', 'timezone': 'UTC-06:00', 'borders': 3},
    'BR': {'name': 'Brésil', 'capital': 'Brasilia', 'population': 212559409, 'region': 'Amériques', 'subregion': 'Amérique du Sud', 'area': 8515767.0, 'currency': 'BRL', 'currencyName': 'Real', 'language': 'Portugais', 'timezone': 'UTC-03:00', 'borders': 10},
    'AR': {'name': 'Argentine', 'capital': 'Buenos Aires', 'population': 45195777, 'region': 'Amériques', 'subregion': 'Amérique du Sud', 'area': 2780400.0, 'currency': 'ARS', 'currencyName': 'Peso argentin', 'language': 'Espagnol', 'timezone': 'UTC-03:00', 'borders': 5},
    'CN': {'name': 'Chine', 'capital': 'Pékin', 'population': 1402112000, 'region': 'Asie', 'subregion': 'Asie de l\'Est', 'area': 9706961.0, 'currency': 'CNY', 'currencyName': 'Yuan', 'language': 'Mandarin', 'timezone': 'UTC+08:00', 'borders': 14},
    'IN': {'name': 'Inde', 'capital': 'New Delhi', 'population': 1380004385, 'region': 'Asie', 'subregion': 'Asie du Sud', 'area': 3287590.0, 'currency': 'INR', 'currencyName': 'Roupie', 'language': 'Hindi', 'timezone': 'UTC+05:30', 'borders': 6},
    'JP': {'name': 'Japon', 'capital': 'Tokyo', 'population': 125836021, 'region': 'Asie', 'subregion': 'Asie de l\'Est', 'area': 377930.0, 'currency': 'JPY', 'currencyName': 'Yen', 'language': 'Japonais', 'timezone': 'UTC+09:00', 'borders': 0},
    'KR': {'name': 'Corée du Sud', 'capital': 'Séoul', 'population': 51780579, 'region': 'Asie', 'subregion': 'Asie de l\'Est', 'area': 100210.0, 'currency': 'KRW', 'currencyName': 'Won', 'language': 'Coréen', 'timezone': 'UTC+09:00', 'borders': 1},
    'SA': {'name': 'Arabie Saoudite', 'capital': 'Riyad', 'population': 34813867, 'region': 'Asie', 'subregion': 'Asie de l\'Ouest', 'area': 2149690.0, 'currency': 'SAR', 'currencyName': 'Riyal', 'language': 'Arabe', 'timezone': 'UTC+03:00', 'borders': 4},
    'TR': {'name': 'Turquie', 'capital': 'Ankara', 'population': 84339067, 'region': 'Asie', 'subregion': 'Asie de l\'Ouest', 'area': 783562.0, 'currency': 'TRY', 'currencyName': 'Lire turque', 'language': 'Turc', 'timezone': 'UTC+03:00', 'borders': 8},
    'AU': {'name': 'Australie', 'capital': 'Canberra', 'population': 25687041, 'region': 'Océanie', 'subregion': 'Australie et Nouvelle-Zélande', 'area': 7692024.0, 'currency': 'AUD', 'currencyName': 'Dollar australien', 'language': 'Anglais', 'timezone': 'UTC+10:00', 'borders': 0},
  };

  /// Phase lunaire
  static Map<String, dynamic> getMoonPhase(DateTime date) {
    int y = date.year, m = date.month, d = date.day;
    if (m < 3) { y--; m += 12; }
    double jd = 365.25 * y + 30.6 * (m + 1) + d - 694039.09;
    jd /= 29.5305882;
    int b = jd.floor();
    jd -= b;
    b = (jd * 8).round() % 8;
    const phases = [
      "Nouvelle Lune", "Croissant Croissant", "Premier Quartier",
      "Gibbeuse Croissante", "Pleine Lune", "Gibbeuse Décroissante",
      "Dernier Quartier", "Croissant Décroissant",
    ];
    return {
      'phase': phases[b],
      'illumination': (jd * 100).round(),
    };
  }

  /// Convertit PM2.5 en AQI
  static Map<String, dynamic> pm25ToAQI(double v) {
    if (v <= 12) return {'aqi': (v / 12 * 50).round(), 'category': 'Bonne'};
    if (v <= 35.4) return {'aqi': (51 + (v - 12) / (35.4 - 12) * 49).round(), 'category': 'Modérée'};
    if (v <= 55.4) return {'aqi': (101 + (v - 35.5) / (55.4 - 35.5) * 49).round(), 'category': 'Mauvaise pour Sensibles'};
    if (v <= 150.4) return {'aqi': (151 + (v - 55.5) / (150.4 - 55.5) * 49).round(), 'category': 'Mauvaise'};
    return {'aqi': 250, 'category': 'Très Mauvaise'};
  }
}