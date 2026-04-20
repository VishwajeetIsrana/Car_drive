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
      appBar: AppBar(title: const Text('Car'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting / Header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: scheme.primary,
                  child: const Icon(Icons.directions_car, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back',
                        style: TextStyle(
                          color: scheme.onBackground,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Track your vehicle & find nearby service centers',
                        style: TextStyle(
                          color: scheme.onBackground.withOpacity(0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
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
                child: Row(
                  children: [
                    const Icon(
                      Icons.ev_station,
                      size: 36,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Vehicle status',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ValueListenableBuilder<LatLng?>(
                            valueListenable: AppState.instance.vehicleLocation,
                            builder: (context, vloc, _) {
                              if (vloc == null)
                                return const Text(
                                  'Vehicle location not set',
                                  style: TextStyle(color: Colors.grey),
                                );
                              return Text(
                                'Vehicle at ${vloc.latitude.toStringAsFixed(5)}, ${vloc.longitude.toStringAsFixed(5)}',
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // go to map tab to set or view vehicle
                        AppState.instance.selectedTab.value = 1;
                      },
                      child: const Text('View map'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Nearest Service Center card
            Text(
              'Nearest Service Center',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: scheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.green.withOpacity(0.1),
                      child: const Icon(
                        Icons.home_repair_service,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ValueListenableBuilder<List<ServiceCenter>>(
                        valueListenable: AppState.instance.centers,
                        builder: (context, centers, _) {
                          if (centers.isEmpty)
                            return const Text(
                              'No centers nearby',
                              style: TextStyle(color: Colors.grey),
                            );

                          final nearest = centers.reduce(
                            (a, b) =>
                                (a.distanceMeters ?? double.infinity) <
                                    (b.distanceMeters ?? double.infinity)
                                ? a
                                : b,
                          );

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nearest.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${(nearest.distanceMeters ?? 0).toStringAsFixed(0)}m away',
                                style: TextStyle(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.navigation_outlined),
                      onPressed: () {
                        final centers = AppState.instance.centers.value;
                        if (centers.isEmpty) return;
                        final nearest = centers.reduce(
                          (a, b) =>
                              (a.distanceMeters ?? double.infinity) <
                                  (b.distanceMeters ?? double.infinity)
                              ? a
                              : b,
                        );
                        AppState.instance.targetCenter.value = nearest;
                        AppState.instance.selectedTab.value = 1;
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Quick actions
            Text(
              'Quick actions',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    icon: const Icon(Icons.list),
                    label: const Text('All Centers'),
                    onPressed: () => AppState.instance.selectedTab.value = 2,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonalIcon(
                    icon: const Icon(Icons.map),
                    label: const Text('Open map'),
                    onPressed: () => AppState.instance.selectedTab.value = 1,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Recent alerts placeholder
            Text(
              'Recent alerts',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('No alerts', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
