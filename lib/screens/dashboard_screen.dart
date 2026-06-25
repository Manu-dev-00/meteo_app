// lib/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import '../services/app_state.dart';
import '../utils/weather_utils.dart';
import '../utils/app_theme.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/weather_alerts_widget.dart';
import '../widgets/country_modal.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final data = state.weatherData;
        final wInfo = data != null ? getWeatherInfo(data.weatherCode) : null;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: wInfo?.bgGradient ?? [const Color(0xFF1E3A8A), const Color(0xFF111827)],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Barre de recherche
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: SearchBarWidget(
                    onCitySelected: (geo) => state.fetchWeather(
                      geo.latitude, geo.longitude, geo.name, geo.countryCode,
                    ),
                  ),
                ),
                // Recherches récentes
                if (state.recent.isNotEmpty)
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: state.recent.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final r = state.recent[i];
                        return GestureDetector(
                          onTap: () => state.fetchWeather(r.lat, r.lon, r.city, r.countryCode),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: glassDecoration(radius: 10),
                            child: Text(r.city, style: const TextStyle(fontSize: 12, color: Color(0xFFD1D5DB))),
                          ),
                        );
                      },
                    ),
                  ),

                // Contenu principal scrollable
                Expanded(
                  child: state.isLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
                      : state.errorMessage != null
                          ? Center(child: Text(state.errorMessage!, style: const TextStyle(color: Colors.red)))
                          : data == null
                              ? const SizedBox()
                              : _DashboardContent(state: state, data: data),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final AppState state;
  final dynamic data;

  const _DashboardContent({required this.state, required this.data});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        // Alertes météo
        WeatherAlertsWidget(
          temp: state.convertTemp(data.temperature),
          wind: data.windSpeed,
          uv: data.daily.isNotEmpty ? data.daily[0].uvIndexMax : 0,
          maxPrecipProb: data.hourly.isNotEmpty
              ? data.hourly.take(24).map((h) => h.precipProbability).reduce((a, b) => a > b ? a : b)
              : 0,
          isMetric: state.isMetric,
        ),
        // Carte météo principale
        _MainWeatherCard(state: state),
        const SizedBox(height: 16),
        // Graphique 24h
        _HourlyChartCard(state: state),
        const SizedBox(height: 16),
        // Détails météo (grille)
        _DetailsGrid(state: state),
        const SizedBox(height: 16),
        // Prévisions 7 jours
        _ForecastCard(state: state),
        const SizedBox(height: 16),
        // Prévisions horaires
        _HourlyForecastCard(state: state),
      ],
    );
  }
}

// ─── Carte météo principale ─────────────────────────────────────────────────
class _MainWeatherCard extends StatelessWidget {
  final AppState state;
  const _MainWeatherCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final data = state.weatherData!;
    final wInfo = getWeatherInfo(data.weatherCode);
    final moon = _getMoonPhase(DateTime.now());

    return Container(
      decoration: glassDecoration(radius: 24),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête ville + favori
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(state.city,
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  GestureDetector(
                    onTap: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => CountryModal(countryCode: state.countryCode),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.map_outlined, size: 14, color: Color(0xFF60A5FA)),
                        const SizedBox(width: 4),
                        Text(state.countryCode,
                            style: const TextStyle(color: Color(0xFF60A5FA), fontSize: 14)),
                      ],
                    ),
                  ),
                  Text(
                    _formatDateFr(DateTime.now()),
                    style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                  ),
                ],
              ),
              IconButton(
                onPressed: state.toggleFavorite,
                icon: Icon(
                  state.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: state.isFavorite ? const Color(0xFFFBBF24) : const Color(0xFF9CA3AF),
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Icône + température
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _AnimatedWeatherIcon(icon: wInfo.icon, color: wInfo.color),
              const SizedBox(width: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${state.convertTemp(data.temperature).round()}',
                        style: const TextStyle(fontSize: 72, fontWeight: FontWeight.w700, height: 1),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(state.unitLabel,
                            style: const TextStyle(fontSize: 28, color: Color(0xFF60A5FA), fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(wInfo.description,
                        style: const TextStyle(fontSize: 14, color: Color(0xFFE5E7EB))),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Vent / Humidité / Ressenti
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(label: 'Vent', value: '${data.windSpeed.round()}', unit: state.speedUnit, icon: Icons.air_rounded),
                _divider(),
                _StatItem(label: 'Humidité', value: '${data.humidity}', unit: '%', icon: Icons.water_drop_outlined),
                _divider(),
                _StatItem(
                  label: 'Ressenti',
                  value: '${state.convertTemp(data.apparentTemperature).round()}',
                  unit: state.unitLabel,
                  icon: Icons.thermostat_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Phase lunaire
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.nightlight_round, size: 14, color: Color(0xFF9CA3AF)),
              const SizedBox(width: 4),
              Text('${moon['phase']} — ${moon['illumination']}% illuminé',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.1));

  Map<String, dynamic> _getMoonPhase(DateTime date) {
    int y = date.year, m = date.month, d = date.day;
    if (m < 3) { y--; m += 12; }
    double jd = 365.25 * y + 30.6 * (m + 1) + d - 694039.09;
    jd /= 29.5305882;
    int b = jd.floor();
    jd -= b;
    b = (jd * 8).round() % 8;
    const phases = ["Nouvelle Lune", "Croissant Croissant", "Premier Quartier",
      "Gibbeuse Croissante", "Pleine Lune", "Gibbeuse Décroissante",
      "Dernier Quartier", "Croissant Décroissant"];
    return {'phase': phases[b], 'illumination': (jd * 100).round()};
  }

  String _formatDateFr(DateTime dt) {
    const days = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    const months = ['janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'];
    return '${days[dt.weekday - 1]} ${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

class _AnimatedWeatherIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  const _AnimatedWeatherIcon({required this.icon, required this.color});

  @override
  State<_AnimatedWeatherIcon> createState() => _AnimatedWeatherIconState();
}

class _AnimatedWeatherIconState extends State<_AnimatedWeatherIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
    _anim = Tween<double>(begin: 0, end: -12).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _anim,
    builder: (_, __) => Transform.translate(
      offset: Offset(0, _anim.value),
      child: Icon(widget.icon, size: 80, color: widget.color),
    ),
  );
}

class _StatItem extends StatelessWidget {
  final String label, value, unit;
  final IconData icon;
  const _StatItem({required this.label, required this.value, required this.unit, required this.icon});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Icon(icon, size: 18, color: const Color(0xFF9CA3AF)),
      const SizedBox(height: 4),
      RichText(
        text: TextSpan(
          children: [
            TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
            TextSpan(text: ' $unit', style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
          ],
        ),
      ),
      Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
    ],
  );
}

// ─── Graphique horaire ───────────────────────────────────────────────────────
class _HourlyChartCard extends StatelessWidget {
  final AppState state;
  const _HourlyChartCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final hourly = state.weatherData!.hourly.take(24).toList();
    final spots = hourly.asMap().entries.map((e) =>
        FlSpot(e.key.toDouble(), state.convertTemp(e.value.temperature))).toList();
    final precipSpots = hourly.asMap().entries.map((e) =>
        FlSpot(e.key.toDouble(), e.value.precipProbability.toDouble())).toList();

    return Container(
      decoration: glassDecoration(radius: 24),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Température (24h)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              Row(children: [
                _legendDot(const Color(0xFF3B82F6)), const SizedBox(width: 4),
                const Text('Temp', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                const SizedBox(width: 12),
                _legendDot(const Color(0xFFA855F7)), const SizedBox(width: 4),
                const Text('Pluie %', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
              ]),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawHorizontalLine: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(color: Colors.white.withValues(alpha: 0.05), strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: 4,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < hourly.length) {
                          return Text(formatHour(hourly[i].time),
                              style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)));
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: const Color(0xFF3B82F6),
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [const Color(0xFF3B82F6).withValues(alpha: 0.3), Colors.transparent],
                      ),
                    ),
                  ),
                  LineChartBarData(
                    spots: precipSpots,
                    isCurved: true,
                    color: const Color(0xFFA855F7),
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    dashArray: [5, 5],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color) => Container(
    width: 8, height: 8,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

// ─── Grille de détails ───────────────────────────────────────────────────────
class _DetailsGrid extends StatelessWidget {
  final AppState state;
  const _DetailsGrid({required this.state});

  @override
  Widget build(BuildContext context) {
    final data = state.weatherData!;
    final daily = data.daily.isNotEmpty ? data.daily[0] : null;
    final vis = data.hourly.isNotEmpty ? data.hourly[0].visibility / 1000 : 0.0;
    final uvVal = daily?.uvIndexMax ?? 0;
    final sunriseStr = daily != null ? formatTimeFromIso(daily.sunrise) : '--';
    final sunsetStr = daily != null ? formatTimeFromIso(daily.sunset) : '--';

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _DetailCard(
          icon: Icons.wb_sunny_outlined,
          iconColor: const Color(0xFFF59E0B),
          title: 'Indice UV',
          value: '${uvVal.round()}',
          subtitle: uvVal >= 8 ? 'Très élevé' : uvVal >= 5 ? 'Modéré' : 'Faible',
          extra: LinearProgressIndicator(
            value: (uvVal / 11).clamp(0, 1),
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            color: uvVal >= 8 ? Colors.red : uvVal >= 5 ? Colors.orange : Colors.green,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        _DetailCard(
          icon: Icons.remove_red_eye_outlined,
          iconColor: const Color(0xFF60A5FA),
          title: 'Visibilité',
          value: '${vis.toStringAsFixed(1)} km',
          subtitle: vis > 9 ? 'Excellente' : vis > 5 ? 'Légère brume' : 'Mauvaise',
        ),
        _DetailCard(
          icon: Icons.wb_twilight_rounded,
          iconColor: const Color(0xFFFCD34D),
          title: 'Lever / Coucher',
          value: sunriseStr,
          subtitle: '↓ $sunsetStr',
        ),
        _DetailCard(
          icon: Icons.speed_rounded,
          iconColor: const Color(0xFF34D399),
          title: 'Pression',
          value: data.pressure != null ? '${data.pressure!.round()} hPa' : 'N/D',
          subtitle: data.pressure != null
              ? (data.pressure! > 1013 ? 'Haute' : 'Basse')
              : '',
        ),
      ],
    );
  }
}

class _DetailCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title, value, subtitle;
  final Widget? extra;
  const _DetailCard({required this.icon, required this.iconColor, required this.title, required this.value, required this.subtitle, this.extra});

  @override
  Widget build(BuildContext context) => Container(
    decoration: glassDecoration(radius: 20),
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 6),
          Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w500)),
        ]),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
        if (extra != null) ...[const SizedBox(height: 6), extra!],
      ],
    ),
  );
}

// ─── Prévisions 7 jours ──────────────────────────────────────────────────────
class _ForecastCard extends StatelessWidget {
  final AppState state;
  const _ForecastCard({required this.state});

  @override
  Widget build(BuildContext context) => Container(
    decoration: glassDecoration(radius: 24),
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Prévisions 7 Jours',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF9CA3AF), letterSpacing: 1)),
        const SizedBox(height: 12),
        ...state.weatherData!.daily.take(7).map((day) {
          final info = getWeatherInfo(day.weatherCode);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                SizedBox(width: 90, child: Text(formatDayFr(day.time),
                    style: const TextStyle(color: Color(0xFFD1D5DB), fontSize: 13))),
                Icon(info.icon, size: 22, color: info.color),
                const Spacer(),
                Text('${state.convertTemp(day.tempMax).round()}°',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(width: 6),
                Text('/ ${state.convertTemp(day.tempMin).round()}°',
                    style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
              ],
            ),
          );
        }),
      ],
    ),
  );
}

// ─── Prévisions horaires ─────────────────────────────────────────────────────
class _HourlyForecastCard extends StatelessWidget {
  final AppState state;
  const _HourlyForecastCard({required this.state});

  @override
  Widget build(BuildContext context) => Container(
    decoration: glassDecoration(radius: 24),
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Prévisions Horaires',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF9CA3AF), letterSpacing: 1)),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: state.weatherData!.hourly.length.clamp(0, 24),
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final h = state.weatherData!.hourly[i];
              final info = getWeatherInfo(h.weatherCode);
              return Container(
                width: 72,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                decoration: glassDecoration(radius: 14),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(i == 0 ? 'Maint.' : formatHour(h.time),
                        style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
                    const SizedBox(height: 6),
                    Icon(info.icon, size: 22, color: info.color),
                    const SizedBox(height: 6),
                    Text('${state.convertTemp(h.temperature).round()}°',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}
