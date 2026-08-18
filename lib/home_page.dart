import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'app_state.dart';
import 'models/service_center.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _showSettingsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: AppState.instance.themeMode,
          builder: (context, currentMode, _) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'App Settings',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text('Appearance Theme'),
                  const SizedBox(height: 8),
                  ListTile(
                    title: const Text('System Default'),
                    trailing: currentMode == ThemeMode.system
                        ? const Icon(Icons.check, color: Colors.indigo)
                        : null,
                    onTap: () {
                      AppState.instance.themeMode.value = ThemeMode.system;
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    title: const Text('Light Theme'),
                    trailing: currentMode == ThemeMode.light
                        ? const Icon(Icons.check, color: Colors.indigo)
                        : null,
                    onTap: () {
                      AppState.instance.themeMode.value = ThemeMode.light;
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    title: const Text('Dark Theme'),
                    trailing: currentMode == ThemeMode.dark
                        ? const Icon(Icons.check, color: Colors.indigo)
                        : null,
                    onTap: () {
                      AppState.instance.themeMode.value = ThemeMode.dark;
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showTirePressureDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return ValueListenableBuilder<Map<String, double>>(
          valueListenable: AppState.instance.tirePressurePSI,
          builder: (context, tires, _) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.speed, color: Colors.indigo),
                  SizedBox(width: 8),
                  Text('Tire Pressure Details'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: tires.entries.map((e) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(e.key),
                    trailing: Text(
                      '${e.value} PSI',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  );
                }).toList(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Car Telematics'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vehicle Hero / Greeting Card
            Card(
              color: scheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: scheme.primary,
                          child: Icon(
                            Icons.directions_car,
                            color: scheme.onPrimary,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tesla Model 3',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: scheme.onPrimaryContainer,
                                ),
                              ),
                              const SizedBox(height: 2),
                              ValueListenableBuilder<LatLng?>(
                                valueListenable:
                                    AppState.instance.vehicleLocation,
                                builder: (context, vloc, _) {
                                  if (vloc == null) {
                                    return Text(
                                      'Location: Not synced (Tap map to set)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: scheme.onPrimaryContainer
                                            .withValues(alpha: 0.8),
                                      ),
                                    );
                                  }
                                  return Text(
                                    'Location: ${vloc.latitude.toStringAsFixed(4)}, ${vloc.longitude.toStringAsFixed(4)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: scheme.onPrimaryContainer
                                          .withValues(alpha: 0.8),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Quick Remote Lock Toggle
                    ValueListenableBuilder<bool>(
                      valueListenable: AppState.instance.isLocked,
                      builder: (context, locked, _) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.surface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    locked ? Icons.lock : Icons.lock_open,
                                    color: locked ? Colors.green : Colors.red,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    locked ? 'Vehicle Locked' : 'Vehicle Unlocked',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: locked
                                      ? scheme.errorContainer
                                      : Colors.green.shade100,
                                  foregroundColor: locked
                                      ? scheme.onErrorContainer
                                      : Colors.green.shade900,
                                ),
                                icon: Icon(
                                  locked
                                      ? Icons.lock_open
                                      : Icons.lock_outline,
                                  size: 18,
                                ),
                                label: Text(locked ? 'Unlock' : 'Lock'),
                                onPressed: () {
                                  AppState.instance.toggleLock();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      duration: const Duration(seconds: 1),
                                      content: Text(
                                        locked
                                            ? 'Vehicle Unlocked'
                                            : 'Vehicle Locked',
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Vehicle Health Dashboard Grid
            Text(
              'Vehicle Health',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // Battery / Fuel Card
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ValueListenableBuilder<double>(
                        valueListenable: AppState.instance.batteryLevel,
                        builder: (context, battery, _) {
                          return ValueListenableBuilder<int>(
                            valueListenable: AppState.instance.estimatedRangeKm,
                            builder: (context, range, _) {
                              final pct = (battery * 100).toInt();
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(
                                        Icons.battery_charging_full,
                                        color: Colors.green,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Battery',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    '$pct%',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  LinearProgressIndicator(
                                    value: battery,
                                    color: Colors.green,
                                    backgroundColor:
                                        Colors.green.withValues(alpha: 0.2),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Range: ~$range km',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Tire Pressure Card
                Expanded(
                  child: InkWell(
                    onTap: () => _showTirePressureDialog(context),
                    borderRadius: BorderRadius.circular(16),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.speed, color: Colors.blue),
                                SizedBox(width: 8),
                                Text(
                                  'Tire Pressure',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              '32 PSI',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Optimal',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap for details',
                              style: TextStyle(
                                fontSize: 12,
                                color: scheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Nearest Service Center card
            Text(
              'Nearest Service Center',
              style: TextStyle(
                fontSize: 16,
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
                      backgroundColor: Colors.green.withValues(alpha: 0.1),
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
                          if (centers.isEmpty) {
                            return const Text(
                              'No centers nearby. Tap Map to refresh.',
                              style: TextStyle(color: Colors.grey),
                            );
                          }

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
                              Row(
                                children: [
                                  Icon(
                                    Icons.star,
                                    size: 14,
                                    color: Colors.amber[700],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${nearest.rating}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${(nearest.distanceMeters ?? 0).toStringAsFixed(0)}m away',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
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

            const SizedBox(height: 16),

            // Active Vehicle Alerts Card
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Vehicle Alerts',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: scheme.primary,
                  ),
                ),
                ValueListenableBuilder<List<VehicleAlert>>(
                  valueListenable: AppState.instance.alerts,
                  builder: (context, alerts, _) {
                    return Text(
                      '${alerts.length} active',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            ValueListenableBuilder<List<VehicleAlert>>(
              valueListenable: AppState.instance.alerts,
              builder: (context, alerts, _) {
                if (alerts.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: Text(
                          'No active alerts. Vehicle is operating smoothly!',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  );
                }

                return Column(
                  children: alerts.map((alert) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: alert.color.withValues(alpha: 0.2),
                          child: Icon(alert.icon, color: alert.color),
                        ),
                        title: Text(
                          alert.title,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(alert.message),
                        trailing: IconButton(
                          icon: const Icon(Icons.check, size: 20),
                          onPressed: () {
                            AppState.instance.removeAlert(alert.id);
                          },
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
