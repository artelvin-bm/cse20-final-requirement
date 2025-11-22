import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'listing_details_page.dart';
import 'listing.dart';

// RentCast API key used to fetch rental listings.
const String rentcastApiKey = 'f6c40bec38014605a816158e9f9bed78';

/// Main screen with the listings tab and favorites tab.
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
  /// Index of the bottom navigation (0 = listings, 1 = favorites).
  int _currentIndex = 0;

  /// Saved favorite listings, persisted in SharedPreferences.
  List<Listing> _favorites = [];

  /// Set of selected locations for filtering.
  /// Empty means show listings from all locations.
  final Set<String> _locationFilters = {};

  /// Current price filter identifier (All, <1k, 1k-1_5k, etc.).
  String _priceFilter = 'All';

  /// Custom price range when _priceFilter == 'Custom'.
  double? _customMinPrice;
  double? _customMaxPrice;

  /// True while more items are being loaded for infinite scroll.
  bool _isLoadingMore = false;

  /// True when the filter chip section is expanded.
  bool _filtersExpanded = true;

  /// All listings loaded from RentCast.
  List<Listing> _rooms = [];

  /// True while initial data is loading from the API.
  bool _isLoading = true;

  /// Error message when the API call fails.
  String? _errorMessage;

  /// Maximum number of listings currently shown in the list.
  int _itemsToShow = 15;

  /// Unique list of available locations (for filter chips).
  List<String> _availableLocations = [];

  /// Scroll controller used for infinite scrolling.
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _loadFavorites();
    _fetchRoomsFromRentCast();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// Triggers loading more items when user scrolls near the bottom.
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final total = _filteredRooms.length;
      if (!_isLoadingMore && total > _itemsToShow) {
        setState(() {
          _isLoadingMore = true;
        });

        // Simulate a short delay so the loading indicator is visible.
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          setState(() {
            _itemsToShow =
                (_itemsToShow + 15).clamp(0, total).toInt(); // keep int
            _isLoadingMore = false;
          });
        });
      }
    }
  }

  /// Fetches rental listings from the RentCast API and builds Listing objects.
  Future<void> _fetchRoomsFromRentCast() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final uri = Uri.https(
        'api.rentcast.io',
        '/v1/listings/rental/long-term',
        {
          // Fetch across an entire state to get many cities.
          'state': 'TX',
          'limit': '100',
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'accept': 'application/json',
          'X-Api-Key': rentcastApiKey,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        final rawRooms = data.map<Listing>((listing) {
          final addressLine1 = listing['addressLine1'] ?? 'Rental';
          final city = listing['city'] ?? '';
          final state = listing['state'] ?? '';
          final rent = listing['price'] ?? listing['rent'] ?? 0;

          return Listing(
            title: addressLine1,
            location: '$city, $state',
            price: rent,
            beds: listing['bedrooms'],
            baths: listing['bathrooms'],
            sqft: listing['squareFeet'],
            lotSqft: listing['lotSizeSquareFeet'],
            propertyType: listing['propertyType'],
            yearBuilt: listing['yearBuilt'],
            status: listing['status'],
            listingType: listing['listingType'],
            listedDate: listing['listedDate'],
            latitude: (listing['latitude'] as num?)?.toDouble(),
            longitude: (listing['longitude'] as num?)?.toDouble(),
            listingUrl: listing['url'],
            thumbnailUrl: listing['photoUrl'],
            description: listing['description'],
          );
        }).toList();

        // Remove duplicates based on address + location only.
        final Set<String> seen = <String>{};
        final List<Listing> rooms = <Listing>[];

        for (final room in rawRooms) {
          final key = '${room.title}|${room.location}';
          if (seen.add(key)) {
            rooms.add(room);
          }
        }

        // Build a sorted list of unique locations for the filter chips.
        final locations = rooms
            .map((r) => r.location)
            .where((loc) => loc.trim().isNotEmpty)
            .toSet()
            .toList()
          ..sort();

        setState(() {
          _rooms = rooms;
          _availableLocations = locations;
          _itemsToShow = 15;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Server error ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  /// Loads saved favorites from SharedPreferences and parses them as Listing.
  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final String? favoritesJson = prefs.getString('favorites');
    if (favoritesJson != null) {
      final List<dynamic> decoded = jsonDecode(favoritesJson);
      setState(() {
        _favorites = decoded
            .map((e) => Listing.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    }
  }

  /// Saves the current favorites list to SharedPreferences as JSON.
  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_favorites.map((l) => l.toJson()).toList());
    await prefs.setString('favorites', encoded);
  }

  /// Returns all listings filtered by location and price.
  List<Listing> get _filteredRooms {
    List<Listing> filtered = _rooms;

    // Filter by selected locations.
    if (_locationFilters.isNotEmpty) {
      filtered =
          filtered.where((r) => _locationFilters.contains(r.location)).toList();
    }

    // Filter by selected price band or custom range.
    if (_priceFilter != 'All') {
      if (_priceFilter == '<1k') {
        filtered = filtered.where((r) => r.price < 1000).toList();
      } else if (_priceFilter == '1k-1_5k') {
        filtered = filtered
            .where((r) => r.price >= 1000 && r.price <= 1500)
            .toList();
      } else if (_priceFilter == '1_5k-2k') {
        filtered = filtered
            .where((r) => r.price > 1500 && r.price <= 2000)
            .toList();
      } else if (_priceFilter == '>2k') {
        filtered = filtered.where((r) => r.price > 2000).toList();
      } else if (_priceFilter == 'Custom' &&
          _customMinPrice != null &&
          _customMaxPrice != null) {
        filtered = filtered
            .where((r) =>
        r.price >= _customMinPrice! && r.price <= _customMaxPrice!)
            .toList();
      }
    }

    // Final UI-level dedupe so a listing can appear only once.
    final Map<String, Listing> byKey = {};
    for (final room in filtered) {
      final key = '${room.title}|${room.location}';
      byKey.putIfAbsent(key, () => room);
    }
    return byKey.values.toList();
  }

  /// Adds or removes a listing from the favorites list.
  void _toggleFavorite(Listing room) {
    setState(() {
      if (_favorites.any((f) => f.title == room.title)) {
        _favorites.removeWhere((f) => f.title == room.title);
      } else {
        _favorites.add(room);
      }
      _saveFavorites();
    });
  }

  /// Shows a dialog to let the user pick a custom price range.
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
                labelText: 'Min Price (\$)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: maxController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Max Price (\$)',
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

  /// Resets all filters back to their default values.
  void _clearFilters() {
    setState(() {
      _locationFilters.clear();
      _priceFilter = 'All';
      _customMinPrice = null;
      _customMaxPrice = null;
    });
  }

  /// Short human readable summary of the current filters.
  String get _filterSummary {
    String location;
    if (_locationFilters.isEmpty) {
      location = 'All Locations';
    } else if (_locationFilters.length == 1) {
      location = _locationFilters.first;
    } else {
      location = '${_locationFilters.length} locations';
    }

    String price;
    if (_priceFilter == 'All') {
      price = 'All Prices';
    } else if (_priceFilter == 'Custom') {
      price =
      '\$${_customMinPrice?.toStringAsFixed(0)} – \$${_customMaxPrice?.toStringAsFixed(0)}';
    } else if (_priceFilter == '<1k') {
      price = 'Below \$1,000';
    } else if (_priceFilter == '1k-1_5k') {
      price = '\$1,000 – \$1,500';
    } else if (_priceFilter == '1_5k-2k') {
      price = '\$1,500 – \$2,000';
    } else {
      price = 'Above \$2,000';
    }

    return 'Filters: $location • $price';
  }

  @override
  Widget build(BuildContext context) {
    // Two main tabs: listings and favorites.
    final pages = [
      _buildListingsPage(),
      _buildFavoritesPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentIndex == 0 ? "Rental Listings" : "My Favorites"),
        actions: [
          IconButton(
            icon: Icon(
              widget.isDarkMode ? Icons.dark_mode : Icons.light_mode,
            ),
            onPressed: widget.toggleTheme,
          ),
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Listings',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
        ],
      ),
    );
  }

  /// Builds the row of location and price chips used for filtering.
  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          // Location filters.
          FilterChip(
            label: const Text('All locations'),
            selected: _locationFilters.isEmpty,
            onSelected: (_) {
              setState(() => _locationFilters.clear());
            },
          ),
          ..._availableLocations.map(
                (loc) => FilterChip(
              label: Text(loc),
              selected: _locationFilters.contains(loc),
              onSelected: (_) {
                setState(() {
                  if (_locationFilters.contains(loc)) {
                    _locationFilters.remove(loc);
                  } else {
                    _locationFilters.add(loc);
                  }
                });
              },
            ),
          ),

          const SizedBox(width: 8),

          // Price filters.
          FilterChip(
            label: const Text('All prices'),
            selected: _priceFilter == 'All',
            onSelected: (_) {
              setState(() => _priceFilter = 'All');
            },
          ),
          FilterChip(
            label: const Text('< \$1k'),
            selected: _priceFilter == '<1k',
            onSelected: (_) {
              setState(() {
                _priceFilter = _priceFilter == '<1k' ? 'All' : '<1k';
              });
            },
          ),
          FilterChip(
            label: const Text('\$1k–1.5k'),
            selected: _priceFilter == '1k-1_5k',
            onSelected: (_) {
              setState(() {
                _priceFilter =
                _priceFilter == '1k-1_5k' ? 'All' : '1k-1_5k';
              });
            },
          ),
          FilterChip(
            label: const Text('\$1.5k–2k'),
            selected: _priceFilter == '1_5k-2k',
            onSelected: (_) {
              setState(() {
                _priceFilter =
                _priceFilter == '1_5k-2k' ? 'All' : '1_5k-2k';
              });
            },
          ),
          FilterChip(
            label: const Text('> \$2k'),
            selected: _priceFilter == '>2k',
            onSelected: (_) {
              setState(() {
                _priceFilter = _priceFilter == '>2k' ? 'All' : '>2k';
              });
            },
          ),
          FilterChip(
            label: const Text('Custom'),
            selected: _priceFilter == 'Custom',
            onSelected: (selected) async {
              if (selected) {
                await _showCustomPriceDialog();
              } else {
                setState(() => _priceFilter = 'All');
              }
            },
          ),
        ],
      ),
    );
  }

  /// Builds the collapsible section wrapper for the filter header and chips.
  Widget _buildFilterSection() {
    return Column(
      children: [
        ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          leading: const Icon(Icons.filter_alt_outlined),
          title: const Text('Filters'),
          subtitle: Text(
            _filterSummary,
            style: const TextStyle(fontSize: 12),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: _clearFilters,
                child: const Text('Clear'),
              ),
              Icon(
                _filtersExpanded ? Icons.expand_less : Icons.expand_more,
              ),
            ],
          ),
          onTap: () {
            setState(() {
              _filtersExpanded = !_filtersExpanded;
            });
          },
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState: _filtersExpanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: _buildFilterChips(),
          secondChild: const SizedBox.shrink(),
        ),
      ],
    );
  }

  /// Builds the main listings tab with filters, infinite scroll, and cards.
  Widget _buildListingsPage() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _fetchRoomsFromRentCast,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final rooms = _filteredRooms;
    final visibleRooms = rooms.take(_itemsToShow).toList();

    return Column(
      children: [
        _buildFilterSection(),
        Expanded(
          child: visibleRooms.isEmpty
              ? const Center(child: Text("No rooms match your filter."))
              : ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(12),
            itemCount: visibleRooms.length,
            itemBuilder: (context, index) {
              final room = visibleRooms[index];
              final isFav =
              _favorites.any((f) => f.title == room.title);
              final thumb = room.thumbnailUrl;

              return Card(
                elevation: 1,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  leading: thumb != null && thumb.isNotEmpty
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      thumb,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                  )
                      : CircleAvatar(
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .primaryContainer,
                    child: Icon(
                      Icons.home,
                      color: Theme.of(context)
                          .colorScheme
                          .primary,
                    ),
                  ),
                  title: Text(
                    room.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Text(
                    '${room.location} • \$${room.price}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      isFav
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: isFav ? Colors.red : Colors.grey,
                    ),
                    onPressed: () => _toggleFavorite(room),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ListingDetailsPage(listing: room),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        if (_isLoadingMore)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('Loading more listings...'),
              ],
            ),
          ),
      ],
    );
  }

  /// Builds the favorites tab that reuses the same card layout.
  Widget _buildFavoritesPage() {
    if (_favorites.isEmpty) {
      return const Center(child: Text("No favorites yet."));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _favorites.length,
      itemBuilder: (context, index) {
        final room = _favorites[index];
        final thumb = room.thumbnailUrl;

        return Card(
          elevation: 1,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: ListTile(
            leading: thumb != null && thumb.isNotEmpty
                ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                thumb,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
              ),
            )
                : CircleAvatar(
              backgroundColor: Colors.red.shade100,
              child: const Icon(Icons.favorite, color: Colors.red),
            ),
            title: Text(
              room.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: Text(
              '${room.location} • \$${room.price}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _toggleFavorite(room),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ListingDetailsPage(listing: room),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
