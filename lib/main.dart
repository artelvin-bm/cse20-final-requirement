import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() => runApp(const RentalListingApp());

class RentalListingApp extends StatefulWidget {
  const RentalListingApp({super.key});

  @override
  State<RentalListingApp> createState() => _RentalListingAppState();
}

class _RentalListingAppState extends State<RentalListingApp> {
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }

  Future<void> _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    _saveTheme();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rental Listing App',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      debugShowCheckedModeBanner: false,
      home: HomePage(
        isDarkMode: _isDarkMode,
        toggleTheme: _toggleTheme,
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback toggleTheme;

  const HomePage({
    super.key,
    required this.isDarkMode,
    required this.toggleTheme,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  List<Map<String, dynamic>> _favorites = [];
  String _locationFilter = 'All';
  String _priceFilter = 'All';
  double? _customMinPrice;
  double? _customMaxPrice;

  final List<Map<String, dynamic>> _rooms = [
    {"title": "Studio Apartment", "location": "Manila", "price": 12000},
    {"title": "2BR Condo", "location": "Quezon City", "price": 18000},
    {"title": "Shared Room", "location": "Cavite", "price": 8000},
    {"title": "Luxury Condo", "location": "Makati", "price": 25000},
  ];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final String? favoritesJson = prefs.getString('favorites');
    if (favoritesJson != null) {
      setState(() {
        _favorites = List<Map<String, dynamic>>.from(jsonDecode(favoritesJson));
      });
    }
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('favorites', jsonEncode(_favorites));
  }

  List<Map<String, dynamic>> get _filteredRooms {
    List<Map<String, dynamic>> filtered = _rooms;

    if (_locationFilter != 'All') {
      filtered = filtered.where((r) => r['location'] == _locationFilter).toList();
    }

    if (_priceFilter != 'All') {
      if (_priceFilter == '<10k') {
        filtered = filtered.where((r) => r['price'] < 10000).toList();
      } else if (_priceFilter == '10k-15k') {
        filtered = filtered
            .where((r) => r['price'] >= 10000 && r['price'] <= 15000)
            .toList();
      } else if (_priceFilter == '>15k') {
        filtered = filtered.where((r) => r['price'] > 15000).toList();
      } else if (_priceFilter == 'Custom' &&
          _customMinPrice != null &&
          _customMaxPrice != null) {
        filtered = filtered
            .where((r) =>
        r['price'] >= _customMinPrice! && r['price'] <= _customMaxPrice!)
            .toList();
      }
    }

    return filtered;
  }

  void _toggleFavorite(Map<String, dynamic> room) {
    setState(() {
      if (_favorites.any((f) => f['title'] == room['title'])) {
        _favorites.removeWhere((f) => f['title'] == room['title']);
      } else {
        _favorites.add(room);
      }
      _saveFavorites();
    });
  }

  Future<void> _showCustomPriceDialog() async {
    final minController =
    TextEditingController(text: _customMinPrice?.toString() ?? '');
    final maxController =
    TextEditingController(text: _customMaxPrice?.toString() ?? '');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Custom Price Range"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: minController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Min Price (₱)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: maxController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Max Price (₱)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final min = double.tryParse(minController.text);
              final max = double.tryParse(maxController.text);
              if (min != null && max != null && min <= max) {
                setState(() {
                  _priceFilter = 'Custom';
                  _customMinPrice = min;
                  _customMaxPrice = max;
                });
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter valid numbers (min ≤ max).'),
                  ),
                );
              }
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _locationFilter = 'All';
      _priceFilter = 'All';
      _customMinPrice = null;
      _customMaxPrice = null;
    });
  }

  String get _filterSummary {
    String location = _locationFilter == 'All' ? 'All Locations' : _locationFilter;
    String price;
    if (_priceFilter == 'All') {
      price = 'All Prices';
    } else if (_priceFilter == 'Custom') {
      price = '₱${_customMinPrice?.toStringAsFixed(0)} – ₱${_customMaxPrice?.toStringAsFixed(0)}';
    } else if (_priceFilter == '<10k') {
      price = 'Below ₱10,000';
    } else if (_priceFilter == '10k-15k') {
      price = '₱10,000 – ₱15,000';
    } else {
      price = 'Above ₱15,000';
    }
    return 'Filters: $location • $price';
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildListingsPage(),
      _buildFavoritesPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentIndex == 0 ? "Rental Listings" : "My Favorites"),
        actions: _currentIndex == 0
            ? [
          IconButton(
            icon: Icon(widget.isDarkMode
                ? Icons.dark_mode
                : Icons.light_mode),
            onPressed: widget.toggleTheme,
          ),
          PopupMenuButton<String>(
            onSelected: (value) => setState(() => _locationFilter = value),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'All', child: Text('All Locations')),
              PopupMenuItem(value: 'Manila', child: Text('Manila')),
              PopupMenuItem(value: 'Quezon City', child: Text('Quezon City')),
              PopupMenuItem(value: 'Cavite', child: Text('Cavite')),
              PopupMenuItem(value: 'Makati', child: Text('Makati')),
            ],
            icon: const Icon(Icons.location_on),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'Custom') {
                await _showCustomPriceDialog();
              } else {
                setState(() => _priceFilter = value);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'All', child: Text('All Prices')),
              PopupMenuItem(value: '<10k', child: Text('Below ₱10,000')),
              PopupMenuItem(value: '10k-15k', child: Text('₱10,000 – ₱15,000')),
              PopupMenuItem(value: '>15k', child: Text('Above ₱15,000')),
              PopupMenuItem(value: 'Custom', child: Text('Custom Range')),
            ],
            icon: const Icon(Icons.attach_money),
          ),
        ]
            : null,
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.indigo,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Listings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
        ],
      ),
    );
  }

  Widget _buildListingsPage() {
    final rooms = _filteredRooms;
    return Column(
      children: [
        if (_locationFilter != 'All' || _priceFilter != 'All')
          Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _filterSummary,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
                TextButton(
                  onPressed: _clearFilters,
                  child: const Text('Clear Filters'),
                )
              ],
            ),
          ),
        Expanded(
          child: rooms.isEmpty
              ? const Center(child: Text("No rooms match your filter."))
              : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              final isFav =
              _favorites.any((f) => f['title'] == room['title']);

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.indigo.shade100,
                    child:
                    const Icon(Icons.home, color: Colors.indigo),
                  ),
                  title: Text(room['title'],
                      style:
                      const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle:
                  Text('${room['location']} • ₱${room['price']}'),
                  trailing: IconButton(
                    icon: Icon(
                      isFav
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: isFav ? Colors.red : Colors.grey,
                    ),
                    onPressed: () => _toggleFavorite(room),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFavoritesPage() {
    if (_favorites.isEmpty) {
      return const Center(child: Text("No favorites yet."));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _favorites.length,
      itemBuilder: (context, index) {
        final room = _favorites[index];
        return Card(
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.red.shade100,
              child: const Icon(Icons.favorite, color: Colors.red),
            ),
            title: Text(room['title'],
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${room['location']} • ₱${room['price']}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _toggleFavorite(room),
            ),
          ),
        );
      },
    );
  }
}
