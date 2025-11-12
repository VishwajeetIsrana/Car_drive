import 'package:flutter/material.dart';
import 'app_state.dart';
import 'models/service_center.dart';

class CentersPage2 extends StatelessWidget {
  const CentersPage2({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Service Centers')),
      body: ValueListenableBuilder<List<ServiceCenter>>(
        valueListenable: AppState.instance.centers,
        builder: (context, centers, _) {
          if (centers.isEmpty) {
            return const Center(child: Text('No service centers available. Set vehicle or device location to generate centers.'));
          }

          ServiceCenter nearest = centers.first;
          for (final s in centers) {
            if ((s.distanceMeters ?? double.infinity) < (nearest.distanceMeters ?? double.infinity)) {
              nearest = s;
            }
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: centers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final c = centers[i];
              final isNearest = identical(c, nearest);
              return Card(
                elevation: isNearest ? 6 : 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: Icon(Icons.room, color: isNearest ? Colors.green : Colors.orange),
                  title: Text(c.name),
                  subtitle: Text('Distance: ${(c.distanceMeters ?? 0).toStringAsFixed(0)} m'),
                  trailing: ElevatedButton.icon(
                    icon: const Icon(Icons.map),
                    label: const Text('Show'),
                    onPressed: () {
                      AppState.instance.targetCenter.value = c;
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selected center — open Map tab to view.')));
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
