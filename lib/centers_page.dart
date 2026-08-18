import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_state.dart';
import 'models/service_center.dart';

enum SortOption { distance, rating }

class CentersPage extends StatefulWidget {
  const CentersPage({super.key});

  @override
  State<CentersPage> createState() => _CentersPageState();
}

class _CentersPageState extends State<CentersPage> {
  String _searchQuery = '';
  SortOption _sortOption = SortOption.distance;

  void _showBookingDialog(BuildContext context, ServiceCenter center) {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Book Service at ${center.name}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    center.address,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today),
                    title: Text(
                      'Date: ${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                    ),
                    trailing: const Icon(Icons.arrow_drop_down),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.access_time),
                    title: Text('Time: ${selectedTime.format(context)}'),
                    trailing: const Icon(Icons.arrow_drop_down),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (picked != null) {
                        setDialogState(() => selectedTime = picked);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogCtx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Service appointment booked at ${center.name}!',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: const Text('Confirm Booking'),
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
      appBar: AppBar(title: const Text('Service Centers'), centerTitle: true),
      body: Column(
        children: [
          // Search Bar & Filter Strip
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search centers or address...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Sort by:',
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SegmentedButton<SortOption>(
                      segments: const [
                        ButtonSegment(
                          value: SortOption.distance,
                          label: Text('Distance'),
                          icon: Icon(Icons.near_me, size: 16),
                        ),
                        ButtonSegment(
                          value: SortOption.rating,
                          label: Text('Rating'),
                          icon: Icon(Icons.star, size: 16),
                        ),
                      ],
                      selected: {_sortOption},
                      onSelectionChanged: (Set<SortOption> selected) {
                        setState(() {
                          _sortOption = selected.first;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Service Centers List
          Expanded(
            child: ValueListenableBuilder<List<ServiceCenter>>(
              valueListenable: AppState.instance.centers,
              builder: (context, centers, _) {
                if (centers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_off,
                          size: 64,
                          color: scheme.outline,
                        ),
                        const SizedBox(height: 16),
                        const Text('No service centers found nearby'),
                      ],
                    ),
                  );
                }

                var filtered = centers.where((c) {
                  final q = _searchQuery.toLowerCase();
                  return c.name.toLowerCase().contains(q) ||
                      c.address.toLowerCase().contains(q);
                }).toList();

                if (_sortOption == SortOption.distance) {
                  filtered.sort(
                    (a, b) => (a.distanceMeters ?? 0).compareTo(
                      b.distanceMeters ?? 0,
                    ),
                  );
                } else {
                  filtered.sort((a, b) => b.rating.compareTo(a.rating));
                }

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('No service centers match your search.'),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final center = filtered[index];
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: scheme.outlineVariant),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  backgroundColor: scheme.primaryContainer,
                                  child: Icon(
                                    Icons.home_repair_service,
                                    color: scheme.onPrimaryContainer,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        center.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        center.address,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: scheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.star,
                                            size: 16,
                                            color: Colors.amber[700],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${center.rating}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Icon(
                                            Icons.location_on_outlined,
                                            size: 16,
                                            color: scheme.primary,
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            '${(center.distanceMeters ?? 0).toStringAsFixed(0)}m away',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: scheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.calendar_month, size: 18),
                                    label: const Text('Book Service'),
                                    onPressed: () => _showBookingDialog(
                                      context,
                                      center,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
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
                                const SizedBox(width: 4),
                                IconButton.filledTonal(
                                  icon: const Icon(Icons.navigation_outlined),
                                  onPressed: () {
                                    AppState.instance.targetCenter.value = center;
                                    AppState.instance.selectedTab.value = 1;
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
