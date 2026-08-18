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
        SnackBar(
          content: const Text(
            'Tap on the map to set vehicle location first.',
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
        title: const Text('Live Navigation'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.my_location_rounded, size: 20),
              tooltip: 'Find My Location',
              onPressed: _initDeviceLocation,
            ),
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
                                      Icons.my_location_rounded,
                                      color: Color(0xFF2563EB),
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
                                      Icons.directions_car_filled_rounded,
                                      color: Colors.redAccent,
                                      size: 38,
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
                                          ? Icons.stars_rounded
                                          : Icons.location_on_rounded,
                                      color: isTarget
                                          ? const Color(0xFF2563EB)
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
                              strokeWidth: 5.0,
                              color: const Color(0xFF2563EB),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),

                // Sleek Floating Action Pills
                Positioned(
                  top: 16,
                  right: 16,
                  child: Column(
                    children: [
                      FloatingActionButton.small(
                        heroTag: 'fab_my_loc',
                        elevation: 3,
                        backgroundColor: scheme.surface,
                        foregroundColor: scheme.onSurface,
                        onPressed: _centerOnDevice,
                        tooltip: 'Center on Me',
                        child: const Icon(Icons.my_location_rounded),
                      ),
                      const SizedBox(height: 10),
                      FloatingActionButton.small(
                        heroTag: 'fab_car_loc',
                        elevation: 3,
                        backgroundColor: scheme.surface,
                        foregroundColor: scheme.onSurface,
                        onPressed: _centerOnVehicle,
                        tooltip: 'Center on Vehicle',
                        child: const Icon(Icons.directions_car_filled_rounded),
                      ),
                      ValueListenableBuilder<ServiceCenter?>(
                        valueListenable: AppState.instance.targetCenter,
                        builder: (context, target, _) {
                          if (target == null) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 10.0),
                            child: FloatingActionButton.small(
                              heroTag: 'fab_clear_route',
                              elevation: 3,
                              backgroundColor: scheme.errorContainer,
                              foregroundColor: scheme.onErrorContainer,
                              onPressed: () {
                                AppState.instance.targetCenter.value = null;
                              },
                              tooltip: 'Clear Navigation Route',
                              child: const Icon(Icons.close_rounded),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Floating Selected Center Card Banner
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: ValueListenableBuilder<ServiceCenter?>(
                    valueListenable: AppState.instance.targetCenter,
                    builder: (context, target, _) {
                      if (target == null) return const SizedBox.shrink();
                      return Card(
                        elevation: 8,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF2563EB,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: const Icon(
                                  Icons.near_me_rounded,
                                  color: Color(0xFF2563EB),
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      target.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${(target.distanceMeters ?? 0).toStringAsFixed(0)}m away • ${target.address}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton.filledTonal(
                                style: IconButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.call_rounded,
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
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () => AppState.instance
                                    .targetCenter.value = null,
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

          // Refined Map Status Info Sheet
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: scheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
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
                      Text('Acquiring high-accuracy GPS signal...'),
                    ],
                  )
                else if (_deviceLocation == null)
                  const Text(
                    'Device location unavailable. Tap map or enable location services.',
                  ),
                if (_vehicleLocation == null)
                  Row(
                    children: [
                      Icon(
                        Icons.touch_app_rounded,
                        size: 16,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Tap anywhere on map to position vehicle marker.',
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  )
                else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Vehicle Telematics Pin',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${_vehicleLocation!.latitude.toStringAsFixed(4)}, ${_vehicleLocation!.longitude.toStringAsFixed(4)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      if (distKm != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF2563EB,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${distKm.toStringAsFixed(2)} km away',
                            style: const TextStyle(
                              color: Color(0xFF2563EB),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
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
