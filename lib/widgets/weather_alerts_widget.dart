// lib/widgets/weather_alerts_widget.dart

import 'package:flutter/material.dart';
import '../utils/weather_utils.dart';

class WeatherAlertsWidget extends StatefulWidget {
  final double temp, wind, uv;
  final int maxPrecipProb;
  final bool isMetric;

  const WeatherAlertsWidget({
    super.key,
    required this.temp,
    required this.wind,
    required this.uv,
    required this.maxPrecipProb,
    required this.isMetric,
  });

  @override
  State<WeatherAlertsWidget> createState() => _WeatherAlertsWidgetState();
}

class _WeatherAlertsWidgetState extends State<WeatherAlertsWidget> {
  late List<Map<String, dynamic>> _alerts;
  final Set<int> _dismissed = {};

  @override
  void initState() {
    super.initState();
    _buildAlerts();
  }

  @override
  void didUpdateWidget(covariant WeatherAlertsWidget old) {
    super.didUpdateWidget(old);
    _buildAlerts();
  }

  void _buildAlerts() {
    _alerts = buildWeatherAlerts(
      temp: widget.temp,
      wind: widget.wind,
      uv: widget.uv,
      maxPrecipProb: widget.maxPrecipProb,
      isMetric: widget.isMetric,
    );
  }

  @override
  Widget build(BuildContext context) {
    final visible = _alerts.asMap().entries.where((e) => !_dismissed.contains(e.key)).toList();
    if (visible.isEmpty) return const SizedBox();

    return Column(
      children: [
        ...visible.map((entry) {
          final i = entry.key;
          final a = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: (a['color'] as Color).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: (a['color'] as Color).withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  Icon(a['icon'] as IconData, color: a['color'] as Color, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a['title'] as String,
                            style: TextStyle(fontWeight: FontWeight.bold, color: a['color'] as Color, fontSize: 13)),
                        Text(a['message'] as String,
                            style: const TextStyle(fontSize: 12, color: Color(0xFFD1D5DB))),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _dismissed.add(i)),
                    icon: const Icon(Icons.close, size: 16, color: Color(0xFF9CA3AF)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 4),
      ],
    );
  }
}
