import 'package:flutter/material.dart';
import 'home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Entry point of the app – starts the Flutter widget tree.
void main() => runApp(const RentalListingApp());

/// Root app widget that manages global theme (light/dark).
class RentalListingApp extends StatefulWidget {
  const RentalListingApp({super.key});

  @override
  State<RentalListingApp> createState() => _RentalListingAppState();
}

class _RentalListingAppState extends State<RentalListingApp> {
  /// Whether dark mode is currently enabled.
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    // Load the saved theme preference when the app starts.
    _loadTheme();
  }

  /// Reads the saved theme preference from local storage.
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }

  /// Persists the current theme preference to local storage.
  Future<void> _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
  }

  /// Toggles between light and dark mode and saves the choice.
  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    _saveTheme();
  }

  @override
  Widget build(BuildContext context) {
    // Base color used to generate the Material 3 color scheme.
    const seed = Colors.indigo;

    return MaterialApp(
      title: 'Rental Listing App',
      // Material 3 light theme using a seed-based ColorScheme.
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      // Material 3 dark theme using the same seed color.
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      // Choose light or dark based on the saved preference.
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      debugShowCheckedModeBanner: false,
      // HomePage handles listings, filters, favorites, etc.
      home: HomePage(
        isDarkMode: _isDarkMode,
        toggleTheme: _toggleTheme,
      ),
    );
  }
}
