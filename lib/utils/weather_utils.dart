// lib/utils/weather_utils.dart

import 'package:flutter/material.dart';

class WeatherInfo {
  final String description;
  final IconData icon;
  final Color color;
  final List<Color> bgGradient;

  const WeatherInfo({
    required this.description,
    required this.icon,
    required this.color,
    required this.bgGradient,
  });
}

WeatherInfo getWeatherInfo(int code) {
  if (code == 0) {
    return WeatherInfo(
      description: 'Ciel Dégagé',
      icon: Icons.wb_sunny_rounded,
      color: const Color(0xFFFBBF24),
      bgGradient: [const Color(0xFF1E3A8A), const Color(0xFF111827)],
    );
  }
  if (code >= 1 && code <= 3) {
    return WeatherInfo(
      description: 'Partiellement Nuageux',
      icon: Icons.cloud_rounded,
      color: const Color(0xFFD1D5DB),
      bgGradient: [const Color(0xFF374151), const Color(0xFF111827)],
    );
  }
  if (code >= 45 && code <= 48) {
    return WeatherInfo(
      description: 'Brouillard',
      icon: Icons.foggy,
      color: const Color(0xFF9CA3AF),
      bgGradient: [const Color(0xFF374151), const Color(0xFF111827)],
    );
  }
  if (code >= 51 && code <= 67) {
    return WeatherInfo(
      description: 'Pluie',
      icon: Icons.grain_rounded,
      color: const Color(0xFF60A5FA),
      bgGradient: [const Color(0xFF1E40AF), const Color(0xFF0F172A)],
    );
  }
  if (code >= 71 && code <= 77) {
    return WeatherInfo(
      description: 'Neige',
      icon: Icons.ac_unit_rounded,
      color: Colors.white,
      bgGradient: [const Color(0xFF94A3B8), const Color(0xFF1E293B)],
    );
  }
  if (code >= 80 && code <= 82) {
    return WeatherInfo(
      description: 'Pluie Forte',
      icon: Icons.thunderstorm_rounded,
      color: const Color(0xFF3B82F6),
      bgGradient: [const Color(0xFF1E40AF), const Color(0xFF0F172A)],
    );
  }
  if (code >= 95) {
    return WeatherInfo(
      description: 'Orage',
      icon: Icons.bolt_rounded,
      color: const Color(0xFFF59E0B),
      bgGradient: [const Color(0xFF312E81), const Color(0xFF020617)],
    );
  }
  return WeatherInfo(
    description: 'Inconnu',
    icon: Icons.cloud_rounded,
    color: const Color(0xFF9CA3AF),
    bgGradient: [const Color(0xFF374151), const Color(0xFF111827)],
  );
}

String formatHour(String isoTime) {
  try {
    final dt = DateTime.parse(isoTime);
    return '${dt.hour.toString().padLeft(2, '0')}:00';
  } catch (_) {
    return isoTime;
  }
}

String formatDayFr(String dateStr) {
  try {
    final dt = DateTime.parse(dateStr);
    const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    const months = ['jan', 'fév', 'mar', 'avr', 'mai', 'juin', 'juil', 'août', 'sep', 'oct', 'nov', 'déc'];
    return '${days[dt.weekday - 1]} ${dt.day} ${months[dt.month - 1]}';
  } catch (_) {
    return dateStr;
  }
}

String formatTimeFromIso(String isoTime) {
  try {
    final parts = isoTime.split('T');
    if (parts.length > 1) return parts[1].substring(0, 5);
    return isoTime;
  } catch (_) {
    return isoTime;
  }
}

String comfortLabel(int level) {
  const labels = {1: '😫 Trop Froid', 2: '🥶 Froid', 3: '👌 Parfait', 4: '🥵 Chaud', 5: '😰 Trop Chaud'};
  return labels[level] ?? '';
}

// Alertes météo
List<Map<String, dynamic>> buildWeatherAlerts({
  required double temp,
  required double wind,
  required double uv,
  required int maxPrecipProb,
  required bool isMetric,
}) {
  final alerts = <Map<String, dynamic>>[];
  final unitL = isMetric ? 'C' : 'F';

  if (temp > 35) {
    alerts.add({
      'type': 'critical',
      'icon': Icons.thermostat,
      'title': 'Alerte Chaleur Extrême',
      'message': 'Température à ${temp.round()}°$unitL. Restez hydraté.',
      'color': Colors.red,
    });
  } else if (temp < 0) {
    alerts.add({
      'type': 'critical',
      'icon': Icons.ac_unit,
      'title': 'Alerte Gel',
      'message': 'Température à ${temp.round()}°$unitL. Attention au verglas.',
      'color': Colors.blue,
    });
  }
  if (wind > 50) {
    alerts.add({
      'type': 'critical',
      'icon': Icons.air,
      'title': 'Alerte Vents Violents',
      'message': 'Vent à ${wind.round()} km/h. Évitez les sorties.',
      'color': Colors.red,
    });
  } else if (wind > 30) {
    alerts.add({
      'type': 'warning',
      'icon': Icons.air,
      'title': 'Conditions Venteuses',
      'message': 'Vent modéré à ${wind.round()} km/h.',
      'color': Colors.orange,
    });
  }
  if (uv >= 8) {
    alerts.add({
      'type': 'warning',
      'icon': Icons.wb_sunny,
      'title': 'Indice UV Très Élevé',
      'message': 'UV à ${uv.round()}. Utilisez crème solaire SPF 30+.',
      'color': Colors.orange,
    });
  }
  if (maxPrecipProb > 70) {
    alerts.add({
      'type': 'info',
      'icon': Icons.grain,
      'title': 'Pluie Prévue',
      'message': '$maxPrecipProb% de risque de pluie dans les 24h.',
      'color': Colors.blue,
    });
  }
  return alerts;
}
