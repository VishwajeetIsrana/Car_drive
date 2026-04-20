import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_state.dart';
import 'models/service_center.dart';

class CentersPage extends StatelessWidget {
  const CentersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Service Centers'), centerTitle: true),
      body: ValueListenableBuilder<List<ServiceCenter>>(
        valueListenable: AppState.instance.centers,
        builder: (context, centers, _) {
          if (centers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off, size: 64, color: scheme.outline),
                  const SizedBox(height: 16),
                  const Text('No service centers found nearby'),
                ],
              ),
            );
          }

          final sortedCenters = List<ServiceCenter>.from(centers)
            ..sort(
              (a, b) =>
                  (a.distanceMeters ?? 0).compareTo(b.distanceMeters ?? 0),
            );

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sortedCenters.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final center = sortedCenters[index];
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: scheme.outlineVariant),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: scheme.primaryContainer,
                    child: Icon(
                      Icons.home_repair_service,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  title: Text(
                    center.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${(center.distanceMeters ?? 0).toStringAsFixed(0)} meters away',
                      ),
                      Text(
                        center.phoneNumber,
                        style: TextStyle(
                          color: scheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      IconButton.filledTonal(
                        icon: const Icon(Icons.call),
                        onPressed: () async {
                          final Uri url = Uri(
                            scheme: 'tel',
                            path: center.phoneNumber,
                          );
                          try {
                            await launchUrl(
                              url,
                              mode: LaunchMode.externalApplication,
                            );
                          } catch (e) {
                            debugPrint('Error launching dialer: $e');
                          }
                        },
                      ),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.navigation_outlined),
                        onPressed: () {
                          AppState.instance.targetCenter.value = center;
                          AppState.instance.selectedTab.value = 1;
                        },
                      ),
                    ],
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
