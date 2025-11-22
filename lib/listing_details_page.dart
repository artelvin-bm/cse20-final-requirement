import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'listing.dart';

/// Screen that shows full details for a single listing, including map.
class ListingDetailsPage extends StatelessWidget {
  final Listing listing;

  const ListingDetailsPage({super.key, required this.listing});

  @override
  Widget build(BuildContext context) {
    // Unpack fields from the Listing model for easier use below.
    final beds = listing.beds;
    final baths = listing.baths;
    final sqft = listing.sqft;
    final lotSqft = listing.lotSqft;
    final type = listing.propertyType;
    final yearBuilt = listing.yearBuilt;
    final status = listing.status;
    final listingType = listing.listingType;
    final rawListedDate = listing.listedDate;
    // Trim ISO date string like 2025-11-22T00:00:00.000Z to just the date.
    final listedDate = rawListedDate?.split('T').first;
    final lat = listing.latitude;
    final lng = listing.longitude;
    final url = listing.listingUrl;
    final desc = listing.description;
    final thumb = listing.thumbnailUrl;

    return Scaffold(
      appBar: AppBar(
        title: Text(listing.title),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Main listing image if available.
          if (thumb != null && (thumb as String).isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                thumb,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 12),
          Text(
            listing.title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            listing.location,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '\$${listing.price} / month',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Divider(height: 24),

          // Quick property stats row.
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              if (beds != null) Text('Beds: $beds'),
              if (baths != null) Text('Baths: $baths'),
              if (sqft != null) Text('Area: $sqft sq ft'),
              if (lotSqft != null) Text('Lot: $lotSqft sq ft'),
            ],
          ),
          const SizedBox(height: 12),

          // Additional metadata about the property.
          if (type != null) Text('Property type: $type'),
          if (yearBuilt != null) Text('Year built: $yearBuilt'),
          if (status != null) Text('Status: $status'),
          if (listingType != null) Text('Listing type: $listingType'),
          if (listedDate != null) Text('Listed: $listedDate'),
          if (lat != null && lng != null)
            Text('Coordinates: $lat, $lng'),
          const SizedBox(height: 16),

          // Only show description section if there is non-empty text.
          if (desc != null && (desc as String).isNotEmpty) ...[
            Text(
              'Description',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(desc),
            const SizedBox(height: 16),
          ],

          // Link out to the external listing page if provided.
          if (url != null && url.isNotEmpty)
            Text(
              'Listing URL:\n$url',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),

          // Embedded map centered on the listing coordinates.
          if (lat != null && lng != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(lat, lng),
                  initialZoom: 14,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.rental_listing_app',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(lat, lng),
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 36,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
