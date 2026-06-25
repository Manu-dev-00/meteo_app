import 'package:flutter/material.dart';
import '../services/weather_service.dart';
import '../utils/app_theme.dart';

class CountryModal extends StatefulWidget {
  final String countryCode;
  const CountryModal({super.key, required this.countryCode});

  @override
  State<CountryModal> createState() => _CountryModalState();
}

class _CountryModalState extends State<CountryModal> {
  Map<String, dynamic>? _country;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCountry();
  }

  Future<void> _loadCountry() async {
    final data = await WeatherService.fetchCountryInfo(widget.countryCode);
    setState(() { _country = data; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Color(0xFF1A2234),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // En-tête
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Informations du Pays',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          // Contenu
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
                : _country == null
                    ? const Center(child: Text('Données indisponibles', style: TextStyle(color: Color(0xFF9CA3AF))))
                    : _CountryDetails(country: _country!),
          ),
        ],
      ),
    );
  }
}

class _CountryDetails extends StatelessWidget {
  final Map<String, dynamic> country;
  const _CountryDetails({required this.country});

  @override
  Widget build(BuildContext context) {
    final name = country['name']?['common'] ?? 'N/D';
    final capital = (country['capital'] as List?)?.firstOrNull ?? 'N/D';
    final population = ((country['population'] as num?)?.toDouble() ?? 0) / 1e6;
    final region = country['subregion'] ?? country['region'] ?? 'N/D';
    final area = (country['area'] as num?)?.toStringAsFixed(0) ?? 'N/D';
    final currencies = (country['currencies'] as Map?)?.keys.join(', ') ?? 'N/D';
    final languages = (country['languages'] as Map?)?.values.join(', ') ?? 'N/D';
    final timezones = (country['timezones'] as List?)?.firstOrNull ?? 'N/D';
    final flagUrl = country['flags']?['png'] ?? '';

    // borders peut être un int (base locale) ou une List (API REST Countries)
    final bordersRaw = country['borders'];
    final borders = bordersRaw is List
        ? bordersRaw.length
        : (bordersRaw as num?)?.toInt() ?? 0;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Drapeau + nom
        Row(
          children: [
            if (flagUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  flagUrl,
                  width: 64,
                  height: 42,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 64, height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFF374151),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.flag_rounded, color: Color(0xFF6B7280)),
                  ),
                ),
              ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis),
                  Text(region,
                      style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Grille d'infos
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 2.0,
          children: [
            _InfoTile(icon: Icons.location_city_rounded, label: 'Capitale', value: capital.toString()),
            _InfoTile(icon: Icons.people_rounded, label: 'Population', value: '${population.toStringAsFixed(1)}M'),
            _InfoTile(icon: Icons.attach_money_rounded, label: 'Devise', value: currencies),
            _InfoTile(icon: Icons.map_outlined, label: 'Superficie', value: '$area km²'),
            _InfoTile(icon: Icons.language_rounded, label: 'Langues', value: languages),
            _InfoTile(icon: Icons.access_time_rounded, label: 'Fuseau', value: timezones.toString()),
            _InfoTile(icon: Icons.account_tree_rounded, label: 'Frontières', value: '$borders pays'),
          ],
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: glassDecoration(radius: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, size: 14, color: const Color(0xFF60A5FA)),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
        ]),
        const Spacer(),
        Text(value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis),
      ],
    ),
  );
}