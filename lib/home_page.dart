import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'app_state.dart';
import 'models/service_center.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Car'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting / Header
            Row(
              children: [
                CircleAvatar(backgroundColor: scheme.primary, child: const Icon(Icons.directions_car, color: Colors.white)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Welcome back', style: TextStyle(color: scheme.onBackground, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('Track your vehicle & find nearby service centers', style: TextStyle(color: scheme.onBackground.withOpacity(0.8), fontSize: 13)),
                  ]),
                ),
                IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.settings, color: scheme.primary),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Vehicle status card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(children: [
                  const Icon(Icons.ev_station, size: 36, color: Colors.redAccent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Vehicle status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      ValueListenableBuilder<LatLng?>(
                        valueListenable: AppState.instance.vehicleLocation,
                        builder: (context, vloc, _) {
                          if (vloc == null) return const Text('Vehicle location not set', style: TextStyle(color: Colors.grey));
                          return Text('Vehicle at ${vloc.latitude.toStringAsFixed(5)}, ${vloc.longitude.toStringAsFixed(5)}');
                        },
                      ),
                    ]),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // go to map tab to set or view vehicle
                      AppState.instance.selectedTab.value = 1;
                    },
                    child: const Text('View map'),
                  ),
                ]),
              ),
            ),

            const SizedBox(height: 12),

            // Nearest Service Center card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(children: [
                  const Icon(Icons.room_service, size: 36, color: Colors.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ValueListenableBuilder<List<ServiceCenter>>(
                      valueListenable: AppState.instance.centers,
                      builder: (context, centers, _) {
                        if (centers.isEmpty) return const Text('No nearby centers', style: TextStyle(color: Colors.grey));
                        ServiceCenter nearest = centers.first;
                        for (final s in centers) {
                          if ((s.distanceMeters ?? double.infinity) < (nearest.distanceMeters ?? double.infinity)) {
                            nearest = s;
                          }
                        }
                        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(nearest.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Text('Distance: ${(nearest.distanceMeters ?? 0).toStringAsFixed(0)} m', style: const TextStyle(color: Colors.grey)),
                        ]);
                      },
                    ),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.map),
                    label: const Text('Show'),
                    onPressed: () {
                      // show nearest on map
                      final centers = AppState.instance.centers.value;
                      if (centers.isNotEmpty) {
                        ServiceCenter nearest = centers.first;
                        for (final s in centers) {
                          if ((s.distanceMeters ?? double.infinity) < (nearest.distanceMeters ?? double.infinity)) nearest = s;
                        }
                        AppState.instance.targetCenter.value = nearest;
                        AppState.instance.selectedTab.value = 1;
                      }
                    },
                  ),
                ]),
              ),
            ),

            const SizedBox(height: 12),

            // Quick actions
            Text('Quick actions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.my_location),
                  label: const Text('Refresh location'),
                  onPressed: () => AppState.instance.deviceLocation.value = AppState.instance.deviceLocation.value,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.map),
                  label: const Text('Open map'),
                  onPressed: () => AppState.instance.selectedTab.value = 1,
                ),
              ),
            ]),

            const SizedBox(height: 16),

            // Recent alerts placeholder
            Text('Recent alerts', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                  Text('No alerts', style: TextStyle(color: Colors.grey)),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
