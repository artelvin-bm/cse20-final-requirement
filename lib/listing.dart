/// Data model representing a single rental listing.
class Listing {
  /// Display title, usually the address line.
  final String title;

  /// City and state (for example "Austin, TX").
  final String location;

  /// Monthly rent price.
  final num price;

  final num? beds;
  final num? baths;
  final num? sqft;
  final num? lotSqft;
  final String? propertyType;
  final int? yearBuilt;
  final String? status;
  final String? listingType;
  final String? listedDate;
  final double? latitude;
  final double? longitude;
  final String? listingUrl;
  final String? thumbnailUrl;
  final String? description;

  /// Creates an immutable Listing instance.
  const Listing({
    required this.title,
    required this.location,
    required this.price,
    this.beds,
    this.baths,
    this.sqft,
    this.lotSqft,
    this.propertyType,
    this.yearBuilt,
    this.status,
    this.listingType,
    this.listedDate,
    this.latitude,
    this.longitude,
    this.listingUrl,
    this.thumbnailUrl,
    this.description,
  });

  /// Builds a Listing from a JSON map (for example decoded API response).
  factory Listing.fromJson(Map<String, dynamic> json) {
    return Listing(
      title: json['title'] as String? ?? 'Rental',
      location: json['location'] as String? ?? '',
      price: json['price'] ?? 0,
      beds: json['beds'],
      baths: json['baths'],
      sqft: json['sqft'],
      lotSqft: json['lotSqft'],
      propertyType: json['propertyType'] as String?,
      yearBuilt: json['yearBuilt'] as int?,
      status: json['status'] as String?,
      listingType: json['listingType'] as String?,
      listedDate: json['listedDate'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      listingUrl: json['listingUrl'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      description: json['description'] as String?,
    );
  }

  /// Converts this Listing into a JSON map for storage or network calls.
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'location': location,
      'price': price,
      'beds': beds,
      'baths': baths,
      'sqft': sqft,
      'lotSqft': lotSqft,
      'propertyType': propertyType,
      'yearBuilt': yearBuilt,
      'status': status,
      'listingType': listingType,
      'listedDate': listedDate,
      'latitude': latitude,
      'longitude': longitude,
      'listingUrl': listingUrl,
      'thumbnailUrl': thumbnailUrl,
      'description': description,
    };
  }
}
