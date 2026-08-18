import 'package:latlong2/latlong.dart';

class ServiceCenter {
  final String id;
  final String name;
  final LatLng location;
  final double? distanceMeters;
  final String phoneNumber;
  final double rating;
  final String address;
  final bool isOpen;

  ServiceCenter({
    required this.id,
    required this.name,
    required this.location,
    this.distanceMeters,
    required this.phoneNumber,
    this.rating = 4.5,
    this.address = 'Main Street, City',
    this.isOpen = true,
  });
}

/// Generate a few sample service centers around [base].
List<ServiceCenter> generateNearbyCenters(LatLng base) {
  final offsets = [
    LatLng(0.010, 0.000),
    LatLng(-0.008, 0.006),
    LatLng(0.004, -0.009),
    LatLng(0.012, 0.010),
    LatLng(-0.006, -0.012),
  ];

  final names = [
    'QuickFix Auto',
    'City Service Center',
    'Speedy Repair',
    'Main St. Garage',
    'Ace Mechanics',
  ];
  final phones = [
    '+919876543210',
    '+919876543211',
    '+919876543212',
    '+919876543213',
    '+919876543214',
  ];
  final ratings = [4.8, 4.2, 4.6, 4.0, 4.9];
  final addresses = [
    '123 Grand Ave, Downtown',
    '45 West Blvd, Midtown',
    '789 Highway 10, Industrial Park',
    '12 Main Street, Central Plaza',
    '555 Speed Way, Auto Zone',
  ];

  final Distance dist = Distance();

  return List.generate(offsets.length, (i) {
    final off = offsets[i];
    final loc = LatLng(
      base.latitude + off.latitude,
      base.longitude + off.longitude,
    );
    final meters = dist.as(LengthUnit.Meter, base, loc);
    return ServiceCenter(
      id: 'sc_$i',
      name: names[i],
      location: loc,
      distanceMeters: meters,
      phoneNumber: phones[i],
      rating: ratings[i],
      address: addresses[i],
      isOpen: i % 4 != 3,
    );
  });
}
