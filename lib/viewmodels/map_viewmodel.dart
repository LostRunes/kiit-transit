import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../core/constants/campus_locations.dart';
import '../core/services/location_service.dart';
import '../core/utils/geo_utils.dart';
import '../data/datasources/location_source.dart';
import '../data/models/driver_contact.dart';
import '../data/models/route_model.dart';
import '../data/models/vehicle_model.dart';
import '../data/repositories/route_repository.dart';
import '../data/repositories/vehicle_repository.dart';

/// Student map state: the live fleet, routes, and the viewer's position.
class MapViewModel extends ChangeNotifier {
  MapViewModel(this._vehicles, this._routes, this._location);

  final VehicleRepository _vehicles;
  final RouteRepository _routes;
  final LocationSource _location;

  StreamSubscription<List<VehicleModel>>? _vehicleSub;
  StreamSubscription<LatLng>? _positionSub;
  Timer? _clock;
  bool _started = false;

  List<VehicleModel> _allVehicles = const [];
  List<RouteModel> routes = const [];
  Map<String, DriverContact> _drivers = const {};
  LatLng? userLocation;
  LocationAccess? locationAccess;
  Landmark? referenceLandmark;
  VehicleType? typeFilter;
  String? selectedVehicleId;
  String? highlightedRouteId;
  bool loading = true;
  String? error;

  /// Where ETAs are measured from: the device, or a landmark the student picked.
  LatLng? get referencePoint => userLocation ?? referenceLandmark?.position;

  String get referenceLabel => userLocation != null ? 'your location' : (referenceLandmark?.name ?? 'campus');

  Future<void> start() async {
    if (_started) return;
    _started = true;
    _vehicleSub = _vehicles.watchVehicles().listen(
      (list) {
        _allVehicles = list;
        loading = false;
        error = null;
        notifyListeners();
      },
      onError: (Object e) {
        error = 'Live updates paused. Reconnecting…';
        loading = false;
        notifyListeners();
      },
    );
    // Re-evaluate staleness and "updated x s ago" labels.
    _clock = Timer.periodic(const Duration(seconds: 15), (_) => notifyListeners());
    unawaited(_loadStatic());
    unawaited(refreshLocation());
  }

  Future<void> _loadStatic() async {
    try {
      routes = await _routes.fetchRoutes();
      final drivers = await _vehicles.fetchDrivers();
      _drivers = {for (final d in drivers) d.id: d};
      notifyListeners();
    } catch (e) {
      debugPrint('Map static load failed: $e');
    }
  }

  Future<void> refreshLocation() async {
    locationAccess = await _location.service.ensurePermission();
    notifyListeners();
    if (locationAccess != LocationAccess.granted) return;
    userLocation = await _location.currentPosition() ?? userLocation;
    notifyListeners();
    await _positionSub?.cancel();
    _positionSub = _location.passivePositions().listen((p) {
      userLocation = p;
      notifyListeners();
    }, onError: (_) {});
  }

  void setReferenceLandmark(Landmark? landmark) {
    referenceLandmark = landmark;
    notifyListeners();
  }

  void setTypeFilter(VehicleType? type) {
    typeFilter = type;
    notifyListeners();
  }

  void selectVehicle(String? id) {
    selectedVehicleId = id;
    highlightedRouteId = id == null ? null : vehicleById(id)?.routeId;
    notifyListeners();
  }

  void highlightRoute(String? routeId) {
    highlightedRouteId = routeId;
    notifyListeners();
  }

  // ------------------------------------------------------------ derived

  /// On-duty vehicles with fresh fixes, annotated with distance/ETA and
  /// sorted nearest first.
  List<VehicleModel> get liveVehicles {
    final ref = referencePoint;
    final list = _allVehicles.where((v) => v.isLive && (typeFilter == null || v.type == typeFilter)).map((v) {
      if (ref == null) return v;
      final d = distanceMeters(ref, v.position!);
      return v.copyWith(distanceMeters: d, etaMinutes: etaMinutes(d));
    }).toList();
    list.sort((a, b) => (a.distanceMeters ?? 0).compareTo(b.distanceMeters ?? 0));
    return list;
  }

  int get liveCount => _allVehicles.where((v) => v.isLive).length;
  int liveCountOf(VehicleType t) => _allVehicles.where((v) => v.isLive && v.type == t).length;

  VehicleModel? get nearest => liveVehicles.firstOrNull;

  VehicleModel? get selectedVehicle =>
      selectedVehicleId == null ? null : liveVehicles.where((v) => v.id == selectedVehicleId).firstOrNull;

  VehicleModel? vehicleById(String id) => _allVehicles.where((v) => v.id == id).firstOrNull;

  RouteModel? routeById(String? id) => id == null ? null : routes.where((r) => r.id == id).firstOrNull;

  String? driverName(VehicleModel v) => v.driverId == null ? null : _drivers[v.driverId]?.name;

  List<VehicleModel> vehiclesOnRoute(String routeId) => liveVehicles.where((v) => v.routeId == routeId).toList();

  /// Stops still ahead of [vehicle], inferred from its heading.
  List<RouteStop> upcomingStops(VehicleModel vehicle) {
    final route = routeById(vehicle.routeId);
    final pos = vehicle.position;
    if (route == null || pos == null || route.stops.length < 2) return const [];
    final stops = route.stops;
    final points = stops.map((s) => s.position).toList();
    final i = nearestIndex(points, pos);

    // Is the vehicle moving towards higher or lower stop indices?
    final nextIdx = i < stops.length - 1 ? i + 1 : (route.isLoop ? 0 : i - 1);
    final towardNext = bearingDegrees(points[i], points[nextIdx]);
    final diff = ((vehicle.heading - towardNext + 540) % 360 - 180).abs();
    final forward = (nextIdx > i || (route.isLoop && nextIdx == 0)) ? diff < 90 : diff >= 90;

    // Skip the nearest stop if the vehicle has already passed it.
    final passed =
        distanceMeters(pos, points[i]) > 25 && ((bearingDegrees(pos, points[i]) - vehicle.heading + 540) % 360 - 180).abs() > 90;
    final start = passed ? (forward ? i + 1 : i - 1) : i;

    if (route.isLoop) {
      return List.generate(stops.length, (k) {
        final idx = forward ? (start + k) % stops.length : (start - k) % stops.length;
        return stops[(idx + stops.length) % stops.length];
      });
    }
    return forward
        ? stops.sublist(start.clamp(0, stops.length))
        : stops.sublist(0, (start + 1).clamp(0, stops.length)).reversed.toList();
  }

  @override
  void dispose() {
    _vehicleSub?.cancel();
    _positionSub?.cancel();
    _clock?.cancel();
    super.dispose();
  }
}
