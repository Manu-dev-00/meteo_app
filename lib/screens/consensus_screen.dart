// lib/screens/consensus_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import '../services/app_state.dart';
import '../utils/app_theme.dart';
import '../utils/weather_utils.dart';

class ConsensusScreen extends StatelessWidget {
  const ConsensusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final data = state.weatherData;
        if (data == null) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)));
        }

        final rng = Random(42);
        final hours = data.hourly.take(24).toList();
        final omTemps = hours.map((h) => state.convertTemp(h.temperature)).toList();
        final owTemps = omTemps.map((t) => t + (rng.nextDouble() * 2 - 1)).toList();
        final wbTemps = omTemps.map((t) => t + (rng.nextDouble() * 2.5 - 1.25)).toList();

        final allTemps = [...omTemps, ...owTemps, ...wbTemps];
        final avg = allTemps.reduce((a, b) => a + b) / allTemps.length;
        final variance = allTemps.map((t) => pow(t - avg, 2)).reduce((a, b) => a + b) / allTemps.length;
        final minT = allTemps.reduce((a, b) => a < b ? a : b).round();
        final maxT = allTemps.reduce((a, b) => a > b ? a : b).round();

        final confidence = variance < 2 ? 'Haute' : variance < 5 ? 'Moyenne' : 'Basse';
        final confColor = variance < 2 ? Colors.green : variance < 5 ? Colors.orange : Colors.red;
        final unitL = state.unitLabel;

        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Titre
              const Text('Consensus Multi-Modèles',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  text: 'Comparaison des prévisions pour ',
                  style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                  children: [
                    TextSpan(text: state.city,
                        style: const TextStyle(color: Color(0xFF60A5FA), fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Graphique principal
              Container(
                decoration: glassDecoration(radius: 24),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Consensus de Température',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: confColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('$confidence Fiabilité',
                              style: TextStyle(color: confColor, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: LineChart(LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (_) =>
                              FlLine(color: Colors.white.withValues(alpha: 0.05), strokeWidth: 1),
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 22,
                              interval: 4,
                              getTitlesWidget: (v, _) {
                                final i = v.toInt();
                                if (i < hours.length) {
                                  return Text(formatHour(hours[i].time),
                                      style: const TextStyle(fontSize: 9, color: Color(0xFF6B7280)));
                                }
                                return const SizedBox();
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          _lineData(omTemps, const Color(0xFF3B82F6)),
                          _lineData(owTemps, const Color(0xFFA855F7)),
                          _lineData(wbTemps, const Color(0xFF10B981)),
                        ],
                      )),
                    ),
                    const SizedBox(height: 8),
                    // Légende
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _legend('Open-Meteo', const Color(0xFF3B82F6)),
                        const SizedBox(width: 16),
                        _legend('OpenWeather', const Color(0xFFA855F7)),
                        const SizedBox(width: 16),
                        _legend('Weatherbit', const Color(0xFF10B981)),
                      ],
                    ),
                    // Stats
                    const Divider(color: Color(0x14FFFFFF), height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _stat('Moyenne', '${avg.round()}$unitL'),
                        _statDivider(),
                        _stat('Écart', '$minT-$maxT$unitL'),
                        _statDivider(),
                        _stat('Variance', variance.toStringAsFixed(2)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3 providers
              Row(
                children: [
                  Expanded(child: _ProviderCard(
                    name: 'Open-Meteo', color: const Color(0xFF3B82F6),
                    temp: '${omTemps[0].round()}$unitL', subtitle: 'Source principale',
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _ProviderCard(
                    name: 'OpenWeather', color: const Color(0xFFA855F7),
                    temp: '${owTemps[0].round()}$unitL', subtitle: 'Simulé',
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _ProviderCard(
                    name: 'Weatherbit', color: const Color(0xFF10B981),
                    temp: '${wbTemps[0].round()}$unitL', subtitle: 'Simulé',
                  )),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  LineChartBarData _lineData(List<double> values, Color color) => LineChartBarData(
    spots: values.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
    isCurved: true,
    color: color,
    barWidth: 2,
    dotData: const FlDotData(show: false),
    belowBarData: BarAreaData(
      show: true,
      color: color.withValues(alpha: 0.05),
    ),
  );

  Widget _legend(String label, Color color) => Row(
    children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
    ],
  );

  Widget _stat(String label, String value) => Column(
    children: [
      Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
      Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    ],
  );

  Widget _statDivider() => Container(
    width: 1, height: 36,
    color: Colors.white.withValues(alpha: 0.1),
  );
}

class _ProviderCard extends StatelessWidget {
  final String name, temp, subtitle;
  final Color color;
  const _ProviderCard({required this.name, required this.color, required this.temp, required this.subtitle});

  @override
  Widget build(BuildContext context) => Container(
    decoration: glassDecoration(radius: 16),
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Flexible(child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis)),
        ]),
        const SizedBox(height: 8),
        Text(temp, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
      ],
    ),
  );
}
