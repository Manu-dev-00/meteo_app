// lib/widgets/search_bar_widget.dart

import 'package:flutter/material.dart';
import '../models/weather_model.dart';
import '../services/weather_service.dart';

class SearchBarWidget extends StatefulWidget {
  final void Function(GeoResult) onCitySelected;
  const SearchBarWidget({super.key, required this.onCitySelected});

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final _ctrl = TextEditingController();
  final _focusNode = FocusNode();
  List<GeoResult> _suggestions = [];
  bool _showSuggestions = false;

  Future<void> _search(String query) async {
    if (query.length < 2) {
      setState(() { _suggestions = []; _showSuggestions = false; });
      return;
    }
    final results = await WeatherService.searchCity(query);
    setState(() { _suggestions = results; _showSuggestions = results.isNotEmpty; });
  }

  void _selectCity(GeoResult geo) {
    _ctrl.text = geo.name;
    setState(() { _showSuggestions = false; _suggestions = []; });
    _focusNode.unfocus();
    widget.onCitySelected(geo);
  }

  @override
  void dispose() { _ctrl.dispose(); _focusNode.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _ctrl,
          focusNode: _focusNode,
          style: const TextStyle(color: Colors.white),
          onChanged: _search,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Rechercher une ville...',
            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF9CA3AF), size: 20),
            suffixIcon: _ctrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF9CA3AF), size: 18),
                    onPressed: () {
                      _ctrl.clear();
                      setState(() { _suggestions = []; _showSuggestions = false; });
                    },
                  )
                : null,
            filled: true,
            fillColor: const Color(0xFF1F2937).withValues(alpha: 0.8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Color(0xFF374151)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Color(0xFF374151)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        if (_showSuggestions)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1F2937),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF374151).withValues(alpha: 0.5)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 20)],
            ),
            child: Column(
              children: _suggestions.map((geo) => InkWell(
                onTap: () => _selectCity(geo),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF9CA3AF)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(geo.name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                            Text('${geo.admin1 != null ? '${geo.admin1}, ' : ''}${geo.country}',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                          ],
                        ),
                      ),
                      Text(geo.countryCode.toUpperCase(),
                          style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                    ],
                  ),
                ),
              )).toList(),
            ),
          ),
      ],
    );
  }
}
