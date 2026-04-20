import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'models/service_center.dart';
import 'app_state.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  LatLng? _vehicleLocation;
  LatLng? _deviceLocation;
  bool _gettingLocation = false;

  final MapController _mapController = MapController();
  // Shared state held in AppState
  late VoidCallback _targetListener;
  // _highlightCenter was unused; remove field to avoid analyzer warning.

  @override
  void initState() {
    super.initState();
    _initDeviceLocation();
    _targetListener = () {
      final c = AppState.instance.targetCenter.value;
      if (c != null) {
        // move map to selected center. No setState needed because we don't store highlight locally.
        _mapController.move(c.location, 15.0);
      }
    };
    AppState.instance.targetCenter.addListener(_targetListener);
  }

  @override
  void dispose() {
    AppState.instance.targetCenter.removeListener(_targetListener);
    super.dispose();
  }

  Future<void> _initDeviceLocation() async {
    setState(() => _gettingLocation = true);
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      setState(() => _gettingLocation = false);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _gettingLocation = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _gettingLocation = false);
      return;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _deviceLocation = LatLng(pos.latitude, pos.longitude);
        _gettingLocation = false;
      });
      final base = LatLng(pos.latitude, pos.longitude);
      AppState.instance.deviceLocation.value = base;
      AppState.instance.generateCentersAround(base);
      // move map to device location
      _mapController.move(_deviceLocation!, 15.0);
    } catch (e) {
      setState(() => _gettingLocation = false);
    }
  }

  double? _distanceKm() {
    if (_deviceLocation == null || _vehicleLocation == null) return null;
    final Distance dist = Distance();
    final meters = dist.as(
      LengthUnit.Meter,
      _deviceLocation!,
      _vehicleLocation!,
    );
    return meters / 1000.0;
  }

  void _onMapTap(TapPosition tapPos, LatLng latlng) {
    setState(() {
      _vehicleLocation = latlng;
      final base = latlng;
      AppState.instance.vehicleLocation.value = base;
      AppState.instance.generateCentersAround(base);
    });
  }

  // _simulateConnect removed — connect action is simulated elsewhere or omitted for this demo

  @override
  Widget build(BuildContext context) {
    final distKm = _distanceKm();

    return Scaffold(
      appBar: AppBar(title: const Text('Car Tracker')),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    center: _deviceLocation ?? LatLng(20.0, 0.0),
                    zoom: 4.0,
                    onTap: _onMapTap,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                      userAgentPackageName: 'com.example.car_drive',
                    ),
                    ValueListenableBuilder<List<ServiceCenter>>(
                      valueListenable: AppState.instance.centers,
                      builder: (context, centers, _) {
                        return ValueListenableBuilder<ServiceCenter?>(
                          valueListenable: AppState.instance.targetCenter,
                          builder: (context, target, _) {
                            ServiceCenter? nearest;
                            if (centers.isNotEmpty) {
                              // avoid using reduce (can cause DDC runtime typing issues); use explicit loop
                              ServiceCenter curNearest = centers.first;
                              for (final s in centers) {
                                if ((s.distanceMeters ?? double.infinity) <
                                    (curNearest.distanceMeters ??
                                        double.infinity)) {
                                  curNearest = s;
                                }
                              }
                              nearest = curNearest;
                            }
                            final markers = <Marker>[];
                            if (_deviceLocation != null) {
                              markers.add(
                                Marker(
                                  width: 80,
                                  height: 80,
                                  point: _deviceLocation!,
                                  builder: (ctx) => const Icon(
                                    Icons.my_location,
                                    color: Colors.blue,
                                    size: 32,
                                  ),
                                ),
                              );
                            }
                            if (_vehicleLocation != null) {
                              markers.add(
                                Marker(
                                  width: 80,
                                  height: 80,
                                  point: _vehicleLocation!,
                                  builder: (ctx) => const Icon(
                                    Icons.local_taxi,
                                    color: Colors.red,
                                    size: 32,
                                  ),
                                ),
                              );
                            }
                            for (final c in centers) {
                              final isTarget =
                                  target != null && identical(c, target);
                              final isNearest =
                                  !isTarget && identical(c, nearest);
                              markers.add(
                                Marker(
                                  width: 56,
                                  height: 56,
                                  point: c.location,
                                  builder: (ctx) => GestureDetector(
                                    onTap: () {
                                      AppState.instance.targetCenter.value = c;
                                    },
                                    child: Icon(
                                      isTarget
                                          ? Icons.stars
                                          : Icons.location_on,
                                      color: isTarget
                                          ? Colors.blue
                                          : (isNearest
                                                ? Colors.green
                                                : Colors.orange),
                                      size: isTarget
                                          ? 44
                                          : (isNearest ? 40 : 30),
                                    ),
                                  ),
                                ),
                              );
                            }
                            return MarkerLayer(markers: markers);
                          },
                        );
                      },
                    ),
                    // draw a line between base (vehicle or device) and highlighted center
                    ValueListenableBuilder<ServiceCenter?>(
                      valueListenable: AppState.instance.targetCenter,
                      builder: (context, target, _) {
                        if (target == null) return const SizedBox.shrink();
                        final base = _vehicleLocation ?? _deviceLocation;
                        if (base == null) return const SizedBox.shrink();
                        return PolylineLayer(
                          polylines: [
                            Polyline(
                              points: [base, target.location],
                              strokeWidth: 4.0,
                              color: Colors.blue.withOpacity(0.6),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
                // Selected Center Info Overlay
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: ValueListenableBuilder<ServiceCenter?>(
                    valueListenable: AppState.instance.targetCenter,
                    builder: (context, target, _) {
                      if (target == null) return const SizedBox.shrink();
                      return Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            child: const Icon(Icons.home_repair_service),
                          ),
                          title: Text(
                            target.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${(target.distanceMeters ?? 0).toStringAsFixed(0)}m away',
                              ),
                              Text(target.phoneNumber),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.call,
                                  color: Colors.green,
                                ),
                                onPressed: () async {
                                  final Uri url = Uri(
                                    scheme: 'tel',
                                    path: target.phoneNumber,
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
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () =>
                                    AppState.instance.targetCenter.value = null,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_gettingLocation) const Text('Getting device location...'),
                if (!_gettingLocation && _deviceLocation == null)
                  const Text(
                    'Device location unavailable. Enable location services.',
                  ),
                if (_vehicleLocation == null)
                  const Text(
                    'Tap on the map to set the vehicle location (simulated).',
                  )
                else ...[
                  Text(
                    'Vehicle: ${_vehicleLocation!.latitude.toStringAsFixed(6)}, ${_vehicleLocation!.longitude.toStringAsFixed(6)}',
                  ),
                  if (distKm != null)
                    Text('Distance: ${distKm.toStringAsFixed(2)} km'),
                ],
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.my_location),
                  label: const Text('Refresh my location'),
                  onPressed: _initDeviceLocation,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
