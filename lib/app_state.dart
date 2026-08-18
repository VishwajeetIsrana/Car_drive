import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'models/service_center.dart';

class VehicleAlert {
  final String id;
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final DateTime time;

  VehicleAlert({
    required this.id,
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    required this.time,
  });
}

class AppState {
  AppState._privateConstructor();
  static final AppState instance = AppState._privateConstructor();

  // Theme state
  final themeMode = ValueNotifier<ThemeMode>(ThemeMode.system);

  // Vehicle Telematics & Controls
  final isLocked = ValueNotifier<bool>(true);
  final fuelLevel = ValueNotifier<double>(0.75); // 75%
  final batteryLevel = ValueNotifier<double>(0.92); // 92%
  final tirePressurePSI = ValueNotifier<Map<String, double>>({
    'Front Left': 32.0,
    'Front Right': 32.0,
    'Rear Left': 31.5,
    'Rear Right': 32.0,
  });
  final estimatedRangeKm = ValueNotifier<int>(380);

  // Location & Map State
  final deviceLocation = ValueNotifier<LatLng?>(null);
  final vehicleLocation = ValueNotifier<LatLng?>(null);
  final centers = ValueNotifier<List<ServiceCenter>>([]);
  final targetCenter = ValueNotifier<ServiceCenter?>(null);

  // Navigation State: 0=Home, 1=Map, 2=Centers
  final selectedTab = ValueNotifier<int>(0);

  // Active Alerts
  final alerts = ValueNotifier<List<VehicleAlert>>([
    VehicleAlert(
      id: 'a1',
      title: 'Scheduled Maintenance',
      message: 'Routine 10,000 km service due in 250 km.',
      icon: Icons.build_circle,
      color: Colors.orange,
      time: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    VehicleAlert(
      id: 'a2',
      title: 'Tire Pressure Normal',
      message: 'All tires are within optimal PSI range.',
      icon: Icons.speed,
      color: Colors.green,
      time: DateTime.now().subtract(const Duration(hours: 12)),
    ),
  ]);

  void toggleLock() {
    isLocked.value = !isLocked.value;
  }

  void removeAlert(String id) {
    alerts.value = alerts.value.where((a) => a.id != id).toList();
  }

  void generateCentersAround(LatLng base) {
    final list = generateNearbyCenters(base);
    centers.value = list;
  }
}
