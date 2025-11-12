import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'models/service_center.dart';

class AppState {
  AppState._privateConstructor();
  static final AppState instance = AppState._privateConstructor();

  // ValueNotifiers so UI can listen for changes
  final deviceLocation = ValueNotifier<LatLng?>(null);
  final vehicleLocation = ValueNotifier<LatLng?>(null);
  final centers = ValueNotifier<List<ServiceCenter>>([]);
  final targetCenter = ValueNotifier<ServiceCenter?>(null);
  // Selected bottom tab index: 0=Home,1=Map,2=Centers
  final selectedTab = ValueNotifier<int>(0);

  void generateCentersAround(LatLng base) {
    final list = generateNearbyCenters(base);
    centers.value = list;
  }
}
