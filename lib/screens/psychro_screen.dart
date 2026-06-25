// lib/screens/psychro_screen.dart
// Diagramme psychrométrique — converti depuis psychro.html

import 'package:flutter/material.dart';
import 'dart:math';
import '../utils/app_theme.dart';

class PsychroScreen extends StatefulWidget {
  const PsychroScreen({super.key});
  @override
  State<PsychroScreen> createState() => _PsychroScreenState();
}

class _PsychroScreenState extends State<PsychroScreen> {
  // Constantes psychrométriques (Magnus-Tetens calibrées)
  static const double _A = 0.000759;
  static const double _b = 17.269;
  static const double _c = 237.29;

  final _tdbCtrl = TextEditingController(text: '25');
  final _twbCtrl = TextEditingController(text: '18');

  Map<String, double> _results = {};

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  @override
  void dispose() {
    _tdbCtrl.dispose();
    _twbCtrl.dispose();
    super.dispose();
  }

  void _calculate() {
    final tdb = double.tryParse(_tdbCtrl.text) ?? 25.0;
    final twb = double.tryParse(_twbCtrl.text) ?? 18.0;
    setState(() { _results = _computePsychro(tdb, twb); });
  }

  Map<String, double> _computePsychro(double tdb, double twb) {
    // Pression de vapeur saturante (hPa)
    double pws(double t) => 6.1078 * exp(_b * t / (_c + t));

    final P = 1013.25; // pression atmosphérique standard (hPa)
    final pwsTdb = pws(tdb);
    final pwsTwb = pws(twb);

    // Humidité spécifique à saturation au thermomètre mouillé
    final Ws_wb = 0.6219 * pwsTwb / (P - pwsTwb);

    // Humidité spécifique de l'air
    final W = Ws_wb - _A * (tdb - twb);

    // Pression de vapeur d'eau
    final Pw = P * W / (0.6219 + W);

    // Humidité relative
    final HR = (Pw / pwsTdb) * 100;

    // Point de rosée (approximation Magnus)
    final alpha = log(Pw / 6.1078) / log(10);
    final Td = _c * alpha / (_b - alpha);

    // Enthalpie (kJ/kg air sec)
    final h = 1.006 * tdb + W * (2501 + 1.86 * tdb);

    // Volume spécifique (m³/kg)
    final v = 0.2871 * (tdb + 273.15) / (P - Pw);

    return {
      'HR': HR.clamp(0, 100),
      'W': W * 1000, // g/kg
      'Td': Td,
      'h': h,
      'v': v,
      'Pw': Pw,
      'pwsTdb': pwsTdb,
    };
  }

  Color _hrColor(double hr) {
    if (hr < 30) return const Color(0xFFEF4444);
    if (hr < 50) return const Color(0xFFF59E0B);
    if (hr <= 70) return const Color(0xFF10B981);
    return const Color(0xFF3B82F6);
  }

  String _hrLabel(double hr) {
    if (hr < 30) return 'Trop Sec';
    if (hr < 50) return 'Sec';
    if (hr <= 70) return 'Confortable';
    if (hr <= 85) return 'Humide';
    return 'Trop Humide';
  }

  @override
  Widget build(BuildContext context) {
    final hr = _results['HR'] ?? 50.0;
    final W = _results['W'] ?? 0.0;
    final Td = _results['Td'] ?? 0.0;
    final h = _results['h'] ?? 0.0;
    final v = _results['v'] ?? 0.0;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Diagramme Psychrométrique',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Calcul des propriétés de l\'air humide',
              style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
          const SizedBox(height: 20),

          // Inputs
          Container(
            decoration: glassDecoration(radius: 20),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Données d\'entrée', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _InputField(
                      ctrl: _tdbCtrl, label: 'Température sèche (°C)',
                      onChanged: (_) => _calculate(),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _InputField(
                      ctrl: _twbCtrl, label: 'Température mouillée (°C)',
                      onChanged: (_) => _calculate(),
                    )),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Humidité relative - résultat principal
          Container(
            decoration: glassDecoration(radius: 20),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text('Humidité Relative',
                    style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
                const SizedBox(height: 8),
                Text('${hr.toStringAsFixed(1)}%',
                    style: TextStyle(fontSize: 56, fontWeight: FontWeight.w700, color: _hrColor(hr))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: _hrColor(hr).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(_hrLabel(hr),
                      style: TextStyle(color: _hrColor(hr), fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),
                // Barre HR
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: hr / 100,
                    minHeight: 10,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(_hrColor(hr)),
                  ),
                ),
                const SizedBox(height: 6),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('0%', style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
                    Text('50%', style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
                    Text('100%', style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Grille de résultats
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _ResultCard(
                icon: Icons.water_drop_outlined,
                iconColor: const Color(0xFF60A5FA),
                title: 'Humidité Absolue',
                value: '${W.toStringAsFixed(2)} g/kg',
                subtitle: 'Humidité spécifique',
              ),
              _ResultCard(
                icon: Icons.thermostat_outlined,
                iconColor: const Color(0xFF34D399),
                title: 'Point de Rosée',
                value: '${Td.toStringAsFixed(1)} °C',
                subtitle: 'Température de condensation',
              ),
              _ResultCard(
                icon: Icons.bolt_rounded,
                iconColor: const Color(0xFFF59E0B),
                title: 'Enthalpie',
                value: '${h.toStringAsFixed(1)} kJ/kg',
                subtitle: 'Énergie de l\'air humide',
              ),
              _ResultCard(
                icon: Icons.compress_rounded,
                iconColor: const Color(0xFFA78BFA),
                title: 'Volume Spécifique',
                value: '${v.toStringAsFixed(4)} m³/kg',
                subtitle: 'Volume massique',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Zone de confort
          _ComfortZoneCard(hr: hr, tdb: double.tryParse(_tdbCtrl.text) ?? 25),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final void Function(String) onChanged;

  const _InputField({required this.ctrl, required this.label, required this.onChanged});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        onChanged: onChanged,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          suffixText: '°C',
          suffixStyle: const TextStyle(color: Color(0xFF60A5FA), fontWeight: FontWeight.bold),
        ),
      ),
    ],
  );
}

class _ResultCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title, value, subtitle;

  const _ResultCard({required this.icon, required this.iconColor, required this.title, required this.value, required this.subtitle});

  @override
  Widget build(BuildContext context) => Container(
    decoration: glassDecoration(radius: 16),
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 6),
          Flexible(child: Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)), overflow: TextOverflow.ellipsis)),
        ]),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(subtitle, style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
      ],
    ),
  );
}

class _ComfortZoneCard extends StatelessWidget {
  final double hr, tdb;
  const _ComfortZoneCard({required this.hr, required this.tdb});

  @override
  Widget build(BuildContext context) {
    // Zone de confort ASHRAE : 20-26°C et 30-60% HR
    final comfortable = tdb >= 20 && tdb <= 26 && hr >= 30 && hr <= 60;
    final color = comfortable ? const Color(0xFF10B981) : const Color(0xFFF59E0B);

    return Container(
      decoration: glassDecoration(radius: 20, borderColor: color.withValues(alpha: 0.3)),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(comfortable ? Icons.check_circle_rounded : Icons.warning_rounded, color: color, size: 20),
            const SizedBox(width: 8),
            Text('Zone de Confort ASHRAE',
                style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          ]),
          const SizedBox(height: 8),
          Text(
            comfortable
                ? 'Conditions confortables — Température et humidité dans la plage idéale (20-26°C / 30-60% HR)'
                : 'Hors zone de confort — Température idéale : 20-26°C, Humidité idéale : 30-60%',
            style: const TextStyle(fontSize: 13, color: Color(0xFFD1D5DB)),
          ),
        ],
      ),
    );
  }
}
