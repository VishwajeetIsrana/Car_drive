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
  late VoidCallback _targetListener;

  @override
  void initState() {
    super.initState();
    _initDeviceLocation();
    _targetListener = () {
      final c = AppState.instance.targetCenter.value;
      if (c != null) {
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

  void _centerOnDevice() {
    if (_deviceLocation != null) {
      _mapController.move(_deviceLocation!, 15.0);
    } else {
      _initDeviceLocation();
    }
  }

  void _centerOnVehicle() {
    if (_vehicleLocation != null) {
      _mapController.move(_vehicleLocation!, 15.0);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tap on the map to set vehicle location first.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final distKm = _distanceKm();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Car Tracker Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Find My Location',
            onPressed: _initDeviceLocation,
          ),
        ],
      ),
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
                                  builder: (ctx) => Tooltip(
                                    message: 'My Location',
                                    child: const Icon(
                                      Icons.my_location,
                                      color: Colors.blue,
                                      size: 32,
                                    ),
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
                                  builder: (ctx) => Tooltip(
                                    message: 'Vehicle Position',
                                    child: const Icon(
                                      Icons.directions_car_filled,
                                      color: Colors.red,
                                      size: 36,
                                    ),
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
                              color: Colors.blue.withValues(alpha: 0.7),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),

                // Floating Map Action Quick Controls
                Positioned(
                  top: 16,
                  right: 16,
                  child: Column(
                    children: [
                      FloatingActionButton.small(
                        heroTag: 'fab_my_loc',
                        onPressed: _centerOnDevice,
                        tooltip: 'Center on Me',
                        child: const Icon(Icons.my_location),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton.small(
                        heroTag: 'fab_car_loc',
                        onPressed: _centerOnVehicle,
                        tooltip: 'Center on Vehicle',
                        child: const Icon(Icons.directions_car),
                      ),
                      ValueListenableBuilder<ServiceCenter?>(
                        valueListenable: AppState.instance.targetCenter,
                        builder: (context, target, _) {
                          if (target == null) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: FloatingActionButton.small(
                              heroTag: 'fab_clear_route',
                              backgroundColor: scheme.errorContainer,
                              foregroundColor: scheme.onErrorContainer,
                              onPressed: () {
                                AppState.instance.targetCenter.value = null;
                              },
                              tooltip: 'Clear Navigation Route',
                              child: const Icon(Icons.close),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Selected Center Info Overlay Card
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: ValueListenableBuilder<ServiceCenter?>(
                    valueListenable: AppState.instance.targetCenter,
                    builder: (context, target, _) {
                      if (target == null) return const SizedBox.shrink();
                      return Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: scheme.primaryContainer,
                            child: Icon(
                              Icons.navigation,
                              color: scheme.onPrimaryContainer,
                            ),
                          ),
                          title: Text(
                            target.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${(target.distanceMeters ?? 0).toStringAsFixed(0)}m away • ${target.address}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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

          // Map Status Info Panel
          Container(
            padding: const EdgeInsets.all(16.0),
            color: scheme.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_gettingLocation)
                  const Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('Acquiring GPS location...'),
                    ],
                  )
                else if (_deviceLocation == null)
                  const Text(
                    'Device location unavailable. Tap map or enable location services.',
                  ),
                if (_vehicleLocation == null)
                  Text(
                    'Tip: Tap anywhere on the map to place/move vehicle pin.',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  )
                else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Vehicle Location: ${_vehicleLocation!.latitude.toStringAsFixed(4)}, ${_vehicleLocation!.longitude.toStringAsFixed(4)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (distKm != null)
                        Chip(
                          label: Text('${distKm.toStringAsFixed(2)} km away'),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
