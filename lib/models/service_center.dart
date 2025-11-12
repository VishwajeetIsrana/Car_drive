import 'package:latlong2/latlong.dart';

class ServiceCenter {
  final String name;
  final LatLng location;
  final double? distanceMeters;

  ServiceCenter({required this.name, required this.location, this.distanceMeters});
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

  final names = ['QuickFix Auto', 'City Service Center', 'Speedy Repair', 'Main St. Garage', 'Ace Mechanics'];

  final Distance dist = Distance();

  return List.generate(offsets.length, (i) {
    final off = offsets[i];
    final loc = LatLng(base.latitude + off.latitude, base.longitude + off.longitude);
    final meters = dist.as(LengthUnit.Meter, base, loc);
    return ServiceCenter(name: names[i], location: loc, distanceMeters: meters);
  });
}
