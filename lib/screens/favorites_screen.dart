// lib/screens/favorites_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../utils/app_theme.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Lieux Enregistrés',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    if (state.favorites.isNotEmpty)
                      TextButton(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              backgroundColor: const Color(0xFF1F2937),
                              title: const Text('Effacer les favoris'),
                              content: const Text('Supprimer tous les favoris ?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
                                TextButton(onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Supprimer', style: TextStyle(color: Colors.red))),
                              ],
                            ),
                          );
                          if (confirm == true) state.clearFavorites();
                        },
                        child: const Text('Tout Effacer', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                if (state.favorites.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.star_outline_rounded, size: 64, color: Colors.grey[700]),
                          const SizedBox(height: 16),
                          Text('Aucune ville favorite pour l\'instant.',
                              style: TextStyle(color: Colors.grey[500]),
                              textAlign: TextAlign.center),
                          const SizedBox(height: 8),
                          Text('Appuyez sur l\'étoile dans le tableau de bord !',
                              style: TextStyle(color: Colors.grey[600], fontSize: 13),
                              textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.3,
                      ),
                      itemCount: state.favorites.length,
                      itemBuilder: (context, i) {
                        final fav = state.favorites[i];
                        return GestureDetector(
                          onTap: () {
                            state.fetchWeather(fav.lat, fav.lon, fav.city, fav.countryCode);
                            // Revenir au dashboard
                            final nav = context.findAncestorStateOfType<_NavigatorState>();
                            if (nav != null) nav.goToDashboard();
                          },
                          child: Container(
                            decoration: glassDecoration(radius: 20),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.location_on_rounded, size: 20, color: Color(0xFF60A5FA)),
                                const Spacer(),
                                Text(fav.city,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis),
                                Text(fav.countryCode,
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                              ],
                            ),
                          ),
                        );
                      },
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

// Trick pour naviguer vers le dashboard depuis les favoris
class _NavigatorState extends State<StatefulWidget> {
  void goToDashboard() {}
  @override Widget build(BuildContext context) => throw UnimplementedError();
}
