// lib/models/weather_model.dart

class WeatherData {
  final double temperature;
  final double apparentTemperature;
  final int weatherCode;
  final double windSpeed;
  final int humidity;
  final double? pressure;
  final bool isDay;
  final List<HourlyData> hourly;
  final List<DailyData> daily;
  final String timezone;

  WeatherData({
    required this.temperature,
    required this.apparentTemperature,
    required this.weatherCode,
    required this.windSpeed,
    required this.humidity,
    this.pressure,
    required this.isDay,
    required this.hourly,
    required this.daily,
    required this.timezone,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final cw = json['current_weather'] ?? {};
    final hourlyRaw = json['hourly'] ?? {};
    final dailyRaw = json['daily'] ?? {};

    // Trouver l'index de l'heure courante
    final times = List<String>.from(hourlyRaw['time'] ?? []);
    final cwTime = cw['time'] as String? ?? '';
    int idx = times.indexOf(cwTime);
    if (idx < 0) idx = 0;

    double temp = (cw['temperature'] as num?)?.toDouble() ?? 0;
    double apparent = temp;
    double wind = (cw['windspeed'] as num?)?.toDouble() ?? 0;
    int humid = 0;
    double? press;

    if (times.isNotEmpty) {
      final temps = List<num>.from(hourlyRaw['temperature_2m'] ?? []);
      final apparents = List<num>.from(hourlyRaw['apparent_temperature'] ?? []);
      final humids = List<num>.from(hourlyRaw['relativehumidity_2m'] ?? hourlyRaw['relative_humidity_2m'] ?? []);
      final winds = List<num>.from(hourlyRaw['windspeed_10m'] ?? hourlyRaw['wind_speed_10m'] ?? []);
      final pressures = List<num>.from(hourlyRaw['surface_pressure'] ?? hourlyRaw['pressure_msl'] ?? []);

      if (idx < temps.length) temp = temps[idx].toDouble();
      if (idx < apparents.length) apparent = apparents[idx].toDouble();
      if (idx < humids.length) humid = humids[idx].toInt();
      if (idx < winds.length) wind = winds[idx].toDouble();
      if (idx < pressures.length) press = pressures[idx].toDouble();
    }

    // Données horaires (24h)
    final precipProb = List<num>.from(hourlyRaw['precipitation_probability'] ?? []);
    final hourlyTemps = List<num>.from(hourlyRaw['temperature_2m'] ?? []);
    final hourlyCodes = List<num>.from(hourlyRaw['weathercode'] ?? hourlyRaw['weather_code'] ?? []);
    final hourlyVis = List<num>.from(hourlyRaw['visibility'] ?? []);

    final hourlyList = <HourlyData>[];
    for (int i = 0; i < times.length && i < 48; i++) {
      hourlyList.add(HourlyData(
        time: times[i],
        temperature: i < hourlyTemps.length ? hourlyTemps[i].toDouble() : 0,
        weatherCode: i < hourlyCodes.length ? hourlyCodes[i].toInt() : 0,
        precipProbability: i < precipProb.length ? precipProb[i].toInt() : 0,
        visibility: i < hourlyVis.length ? hourlyVis[i].toDouble() : 0,
      ));
    }

    // Données journalières (7 jours)
    final dailyTimes = List<String>.from(dailyRaw['time'] ?? []);
    final dailyCodes = List<num>.from(dailyRaw['weathercode'] ?? dailyRaw['weather_code'] ?? []);
    final dailyMax = List<num>.from(dailyRaw['temperature_2m_max'] ?? []);
    final dailyMin = List<num>.from(dailyRaw['temperature_2m_min'] ?? []);
    final sunrises = List<String>.from(dailyRaw['sunrise'] ?? []);
    final sunsets = List<String>.from(dailyRaw['sunset'] ?? []);
    final uvIndex = List<num>.from(dailyRaw['uv_index_max'] ?? []);

    final dailyList = <DailyData>[];
    for (int i = 0; i < dailyTimes.length && i < 7; i++) {
      dailyList.add(DailyData(
        time: dailyTimes[i],
        weatherCode: i < dailyCodes.length ? dailyCodes[i].toInt() : 0,
        tempMax: i < dailyMax.length ? dailyMax[i].toDouble() : 0,
        tempMin: i < dailyMin.length ? dailyMin[i].toDouble() : 0,
        sunrise: i < sunrises.length ? sunrises[i] : '',
        sunset: i < sunsets.length ? sunsets[i] : '',
        uvIndexMax: i < uvIndex.length ? uvIndex[i].toDouble() : 0,
      ));
    }

    return WeatherData(
      temperature: temp,
      apparentTemperature: apparent,
      weatherCode: (cw['weathercode'] as num?)?.toInt() ?? 0,
      windSpeed: wind,
      humidity: humid,
      pressure: press,
      isDay: (cw['is_day'] as num?)?.toInt() == 1,
      hourly: hourlyList,
      daily: dailyList,
      timezone: json['timezone'] as String? ?? 'UTC',
    );
  }
}

class HourlyData {
  final String time;
  final double temperature;
  final int weatherCode;
  final int precipProbability;
  final double visibility;

  HourlyData({
    required this.time,
    required this.temperature,
    required this.weatherCode,
    required this.precipProbability,
    required this.visibility,
  });
}

class DailyData {
  final String time;
  final int weatherCode;
  final double tempMax;
  final double tempMin;
  final String sunrise;
  final String sunset;
  final double uvIndexMax;

  DailyData({
    required this.time,
    required this.weatherCode,
    required this.tempMax,
    required this.tempMin,
    required this.sunrise,
    required this.sunset,
    required this.uvIndexMax,
  });
}

class FavoriteCity {
  final String city;
  final double lat;
  final double lon;
  final String countryCode;

  FavoriteCity({
    required this.city,
    required this.lat,
    required this.lon,
    required this.countryCode,
  });

  factory FavoriteCity.fromJson(Map<String, dynamic> json) => FavoriteCity(
    city: json['city'] as String,
    lat: (json['lat'] as num).toDouble(),
    lon: (json['lon'] as num).toDouble(),
    countryCode: json['countryCode'] as String,
  );

  Map<String, dynamic> toJson() => {
    'city': city, 'lat': lat, 'lon': lon, 'countryCode': countryCode,
  };
}

class JournalEntry {
  final int id;
  final DateTime date;
  final String city;
  final double? temp;
  final int? weatherCode;
  final int comfort; // 1-5
  final String notes;

  JournalEntry({
    required this.id,
    required this.date,
    required this.city,
    this.temp,
    this.weatherCode,
    required this.comfort,
    required this.notes,
  });

  factory JournalEntry.fromJson(Map<String, dynamic> json) => JournalEntry(
    id: json['id'] as int,
    date: DateTime.parse(json['date'] as String),
    city: json['city'] as String,
    temp: (json['temp'] as num?)?.toDouble(),
    weatherCode: json['weather'] as int?,
    comfort: json['comfort'] is String
        ? int.parse(json['comfort'] as String)
        : json['comfort'] as int,
    notes: json['notes'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'city': city,
    'temp': temp,
    'weather': weatherCode,
    'comfort': comfort,
    'notes': notes,
  };
}

class GeoResult {
  final String name;
  final double latitude;
  final double longitude;
  final String countryCode;
  final String country;
  final String? admin1;

  GeoResult({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.countryCode,
    required this.country,
    this.admin1,
  });

  factory GeoResult.fromJson(Map<String, dynamic> json) => GeoResult(
    name: json['name'] as String,
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    countryCode: json['country_code'] as String,
    country: json['country'] as String,
    admin1: json['admin1'] as String?,
  );
}
