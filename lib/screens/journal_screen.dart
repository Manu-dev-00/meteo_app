// lib/screens/journal_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/app_state.dart';
import '../utils/weather_utils.dart';
import '../utils/app_theme.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});
  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  bool _showForm = false;
  int? _selectedComfort;
  final _notesCtrl = TextEditingController();

  static const _comfortOptions = [
    (1, '😫 Trop Froid'),
    (2, '🥶 Froid'),
    (3, '👌 Parfait'),
    (4, '🥵 Chaud'),
    (5, '😰 Trop Chaud'),
  ];

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save(AppState state) async {
    if (_selectedComfort == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez choisir un niveau de confort')),
      );
      return;
    }
    await state.saveJournalEntry(_selectedComfort!, _notesCtrl.text.trim());
    setState(() {
      _showForm = false;
      _selectedComfort = null;
      _notesCtrl.clear();
    });
    if (mounted)
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Entrée sauvegardée !')));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final perfect = state.journalEntries
            .where((e) => e.comfort == 3 && e.temp != null)
            .toList();

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Journal Météo',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    ElevatedButton.icon(
                      onPressed: () => setState(() => _showForm = !_showForm),
                      icon: Icon(_showForm ? Icons.close : Icons.add, size: 18),
                      label: Text(_showForm ? 'Annuler' : 'Aujourd\'hui'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Expanded(
                  child: ListView(
                    children: [
                      // Formulaire
                      if (_showForm) ...[
                        Container(
                          decoration: glassDecoration(radius: 20),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                  'Comment avez-vous ressenti la météo aujourd\'hui ?',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15)),
                              const SizedBox(height: 12),
                              const Text('Niveau de Confort',
                                  style: TextStyle(
                                      color: Color(0xFF9CA3AF), fontSize: 12)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _comfortOptions.map((opt) {
                                  final selected = _selectedComfort == opt.$1;
                                  return GestureDetector(
                                    onTap: () => setState(
                                        () => _selectedComfort = opt.$1),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? const Color(0xFF3B82F6)
                                                .withValues(alpha: 0.3)
                                            : Colors.white
                                                .withValues(alpha: 0.05),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: selected
                                              ? const Color(0xFF3B82F6)
                                              : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                      child: Text(opt.$2,
                                          style: const TextStyle(fontSize: 13)),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 12),
                              const Text('Notes (facultatif)',
                                  style: TextStyle(
                                      color: Color(0xFF9CA3AF), fontSize: 12)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _notesCtrl,
                                maxLines: 3,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 14),
                                decoration: InputDecoration(
                                  hintText:
                                      'Comment l\'avez-vous vraiment ressenti ?...',
                                  filled: true,
                                  fillColor:
                                      Colors.white.withValues(alpha: 0.05),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        color: Colors.white
                                            .withValues(alpha: 0.1)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        color: Colors.white
                                            .withValues(alpha: 0.1)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () => _save(state),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF10B981),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                  child: const Text('Sauvegarder',
                                      style: TextStyle(color: Colors.white)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Insights
                      if (perfect.length >= 2) ...[
                        _InsightsCard(
                            entries: perfect,
                            isMetric: state.isMetric,
                            convertTemp: state.convertTemp,
                            unitLabel: state.unitLabel),
                        const SizedBox(height: 16),
                      ],

                      // Entrées
                      if (state.journalEntries.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 40),
                            child: Column(
                              children: [
                                Icon(Icons.menu_book_rounded,
                                    size: 64, color: Colors.grey[700]),
                                const SizedBox(height: 16),
                                Text('Aucune entrée dans le journal.',
                                    style: TextStyle(color: Colors.grey[500])),
                                Text('Commencez à noter vos ressentis météo !',
                                    style: TextStyle(
                                        color: Colors.grey[600], fontSize: 12)),
                              ],
                            ),
                          ),
                        )
                      else
                        ...state.journalEntries.map((e) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _JournalCard(
                                  entry: e,
                                  isMetric: state.isMetric,
                                  convertTemp: state.convertTemp,
                                  unitLabel: state.unitLabel),
                            )),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InsightsCard extends StatelessWidget {
  final List<dynamic> entries;
  final bool isMetric;
  final double Function(double) convertTemp;
  final String unitLabel;

  const _InsightsCard(
      {required this.entries,
      required this.isMetric,
      required this.convertTemp,
      required this.unitLabel});

  @override
  Widget build(BuildContext context) {
    final temps = entries.map((e) => convertTemp(e.temp as double)).toList();
    final avg = temps.reduce((a, b) => a + b) / temps.length;
    final minT = temps.reduce((a, b) => a < b ? a : b).round();
    final maxT = temps.reduce((a, b) => a > b ? a : b).round();

    return Container(
      decoration: glassDecoration(radius: 16),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📊 Vos Habitudes Météo',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('Sur ${entries.length} entrées, vous êtes à l\'aise entre ',
              style: const TextStyle(fontSize: 13, color: Color(0xFFD1D5DB))),
          Text('$minT$unitLabel — $maxT$unitLabel',
              style: const TextStyle(
                  color: Color(0xFF60A5FA),
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
          Text('Moyenne : ${avg.round()}$unitLabel',
              style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
        ],
      ),
    );
  }
}

class _JournalCard extends StatelessWidget {
  final dynamic entry;
  final bool isMetric;
  final double Function(double) convertTemp;
  final String unitLabel;

  const _JournalCard(
      {required this.entry,
      required this.isMetric,
      required this.convertTemp,
      required this.unitLabel});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy HH:mm', 'fr');
    final dateStr = fmt.format(entry.date);
    final tempStr = entry.temp != null
        ? '${convertTemp(entry.temp as double).round()}$unitLabel'
        : 'N/D';

    return Container(
      decoration: glassDecoration(radius: 16),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(dateStr,
                  style:
                      const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
              Text(entry.city,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _chip(tempStr, const Color(0xFF1D4ED8)),
              _chip(comfortLabel(entry.comfort), const Color(0xFF6D28D9)),
            ],
          ),
          if (entry.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(entry.notes,
                style: const TextStyle(fontSize: 13, color: Color(0xFFD1D5DB))),
          ],
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: const TextStyle(fontSize: 12)),
      );
}
