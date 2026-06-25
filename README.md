<div align="center">

<img src="assets/images/logo.png" width="150" height="150" alt="MeteoMobile Logo"/>

# MeteoMobile 🌤️

### Application Météo Mobile — Flutter
**MeteoMobile** est une application météo mobile complète développée en Flutter.  
Elle fournit des données météorologiques en temps réel pour n'importe quelle ville du monde,  
avec 6 modules fonctionnels et une interface moderne en thème sombre.

[Fonctionnalités](#-fonctionnalités) •
[Installation](#-installation) •
[Technologies](#-technologies-utilisées) •
[APIs](#-apis-intégrées) •
[Architecture](#️-architecture)

</div>

---

## 🌟 Fonctionnalités

### 📊 Dashboard — Page Principale
- 🔍 **Recherche intelligente** — Auto-complétion en temps réel pour toute ville du monde
- 🌡️ **Météo actuelle** — Température, ressenti, humidité, vent, pression atmosphérique
- ⚠️ **Alertes automatiques** — Chaleur extrême, gel, vents violents, risque de pluie
- 📈 **Graphique 24h** — Courbe température + probabilité de pluie heure par heure
- ☀️ **Indice UV** — Barre de progression avec niveau de risque
- 🌅 **Lever / Coucher du soleil** — Heures calculées selon la position
- 📅 **Prévisions 7 jours** — Températures max/min avec icônes météo
- 🕐 **Prévisions horaires** — 24 cartes défilantes heure par heure
- 🌙 **Phase lunaire** — Phase et pourcentage d'illumination
- 🗺️ **Informations pays** — Drapeau, capitale, population, devise via modal

### ⭐ Favoris
- Sauvegarde des villes préférées en un tap
- Accès rapide avec rechargement instantané
- Persistance locale (conservé après fermeture de l'app)
- Suppression individuelle ou globale

### 🔄 Comparer
- Comparaison côte à côte de 2 villes simultanément
- Température, conditions, humidité, vent, UV, précipitations
- Basculement °C / °F pour les deux colonnes en même temps

### 📔 Journal Météo Personnel
- 5 niveaux de confort thermique (😫 🥶 👌 🥵 😰)
- Notes textuelles personnalisées
- Historique complet avec horodatage automatique
- Analyse des habitudes météo (plage de température idéale)

### 🧩 Consensus Multi-Modèles
- Comparaison de 3 sources météo sur 24h
- Graphique avec 3 courbes (Open-Meteo, OpenWeather, Weatherbit)
- Score de fiabilité basé sur la variance entre modèles
- Statistiques : Moyenne, Écart, Variance

### 🌡️ Psychrométrie
- Calcul des propriétés de l'air humide (formules ASHRAE)
- Humidité Relative (HR), Point de rosée (Td), Enthalpie (h), Volume spécifique (v)
- Zone de confort ASHRAE (20-26°C / 30-60% HR)
- Recalcul en temps réel à chaque saisie

---

## 🚀 Installation

### Prérequis

- [Flutter](https://flutter.dev/docs/get-started/install) 3.x ou supérieur
- [Android Studio](https://developer.android.com/studio) avec SDK Android
- Un appareil Android 5.0+ (API 21+) ou un émulateur

### Étapes

```bash
# 1. Cloner le dépôt
git clone https://github.com/Manu-dev-00/MeteoMobile.git
cd MeteoMobile

# 2. Installer les dépendances
flutter pub get

# 3. Générer les icônes de l'app
dart run flutter_launcher_icons

# 4. Lancer l'application
flutter run
```

### Générer l'APK

```bash
# APK release complet
flutter build apk --release

# APK optimisé par architecture (recommandé)
flutter build apk --split-per-abi
```

L'APK se trouve dans :
```
build/app/outputs/flutter-apk/app-release.apk
```

---

## 🛠️ Technologies Utilisées

| Technologie | Version | Rôle |
|-------------|---------|------|
| **Flutter** | 3.x | Framework UI mobile |
| **Dart** | 3.x | Langage de programmation |
| **Provider** | ^6.1.5 | Gestion d'état (MVVM) |
| **http** | ^1.2.0 | Requêtes HTTP vers les APIs |
| **shared_preferences** | ^2.2.2 | Stockage local persistant |
| **fl_chart** | ^0.68.0 | Graphiques interactifs |
| **flutter_map** | ^6.1.0 | Cartes interactives |
| **geolocator** | ^11.0.0 | Géolocalisation GPS |
| **intl** | ^0.19.0 | Formatage des dates en français |
| **permission_handler** | ^11.3.0 | Gestion des permissions Android |
| **flutter_launcher_icons** | ^0.13.1 | Génération des icônes |

---

## 🌐 APIs Intégrées

| API | URL | Authentification | Données |
|-----|-----|-----------------|---------|
| **Open-Meteo Forecast** | `api.open-meteo.com` | ✅ Gratuit — Sans clé | Météo actuelle, 48h horaire, 7j journalier |
| **Open-Meteo Geocoding** | `geocoding-api.open-meteo.com` | ✅ Gratuit — Sans clé | Recherche ville, coordonnées GPS |
| **REST Countries** | `restcountries.com/v3.1` | ✅ Gratuit — Open Source | Drapeau, capitale, population, devise |

> 💡 **Aucune clé API requise** — L'application fonctionne immédiatement sans configuration.

---

## 🏗️ Architecture

MeteoMobile utilise le pattern **MVVM simplifié** avec Provider.

```
lib/
├── main.dart                      # Point d'entrée + Splash Screen + Navigation
├── models/
│   └── weather_model.dart         # Classes de données (WeatherData, DailyData...)
├── services/
│   ├── app_state.dart             # État global (ChangeNotifier / Provider)
│   └── weather_service.dart       # Appels HTTP aux APIs
├── screens/
│   ├── dashboard_screen.dart      # Page principale
│   ├── favorites_screen.dart      # Page favoris
│   ├── compare_screen.dart        # Page comparaison
│   ├── journal_screen.dart        # Page journal
│   ├── consensus_screen.dart      # Page consensus
│   └── psychro_screen.dart        # Page psychrométrie
├── widgets/
│   ├── search_bar_widget.dart     # Barre de recherche avec auto-complétion
│   ├── weather_alerts_widget.dart # Composant alertes météo
│   └── country_modal.dart         # Modal informations pays
└── utils/
    ├── weather_utils.dart         # Codes météo, icônes, alertes
    └── app_theme.dart             # Thème sombre, palette de couleurs
```

### Flux de données

```
Utilisateur
    ↓ interaction
UI (Screens / Widgets)
    ↓ appelle
AppState (Provider)
    ↓ appelle
WeatherService (HTTP)
    ↓ contacte
APIs Open-Meteo / REST Countries
    ↓ retourne JSON
Models (WeatherData...)
    ↓ stocké dans AppState
    ↓ notifyListeners()
UI se rafraîchit automatiquement
```

---

## 📋 Structure des Données Locales

Les données sont stockées avec **SharedPreferences** :

| Clé | Type | Contenu |
|-----|------|---------|
| `favorites` | Liste JSON | Villes favorites |
| `recent` | Liste JSON | 5 dernières recherches |
| `weatherJournal` | Liste JSON | Entrées du journal |
| `unit` | String | `metric` ou `imperial` |

---

## ✅ Tests Fonctionnels

| Module | Scénario | Statut |
|--------|---------|--------|
| Dashboard | Recherche ville "Lomé" | ✅ OK |
| Dashboard | Alertes automatiques | ✅ OK |
| Dashboard | Prévisions 7 jours | ✅ OK |
| Favoris | Ajout / suppression | ✅ OK |
| Comparer | 2 villes simultanées | ✅ OK |
| Journal | Saisie et historique | ✅ OK |
| Psychro | Calcul HR, Td, h, v | ✅ OK |
| Global | Basculement °C/°F | ✅ OK |
| Global | Persistance données | ✅ OK |

---

## 🎓 Contexte Académique

Ce projet a été développé dans le cadre du :

- **Formation** : Bachelor 3 IABD (Intelligence Artificielle & Big Data)
- **Établissement** : Collège de Paris Supérieur — Campus de Lomé, Togo
- **Année** : 2025 – 2026
- **Étudiant** : ALEZA Mazamasso Amos

---

## 📄 Licence

Ce projet est sous licence **MIT** — voir le fichier [LICENSE](LICENSE) pour plus de détails.

---

<div align="center">

Développé avec ❤️ par **ALEZA Mazamasso Amos** — Lomé, Togo 

⭐ N'hésitez pas à mettre une étoile si ce projet vous a été utile !

</div>
