import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/campus_locations.dart';
import '../../core/utils/geo_utils.dart';
import '../../core/utils/validators.dart';
import '../models/driver_contact.dart';
import '../models/request_model.dart';
import '../models/route_model.dart';
import '../models/schedule_model.dart';
import '../models/user_model.dart';
import '../models/vehicle_model.dart';
import 'seed_data.dart';
import 'transit_source.dart';

/// In-memory backend used when Supabase is not configured.
///
/// Vehicles on duty drive along their routes on a timer, so the student map
/// behaves like the real thing. A vehicle claimed by the signed-in driver
/// stops being simulated and follows that device's GPS instead.
///
/// Demo logins (any password of 6+ characters):
///   driver@kiit.ac.in -> driver, admin@kiit.ac.in -> admin, else student.
class DemoSource implements TransitSource {
  DemoSource() {
    _vehicles = {for (final v in SeedData.vehicles) v.id: v};
    _routes = {for (final r in SeedData.routes) r.id: r};
    _schedules = SeedData.schedules();
    _seedRequests();
    _placeVehicles();
    _ticker = Timer.periodic(_tick, (_) => _step());
  }

  static const _tick = Duration(seconds: 2);
  static const _prefsUser = 'demo.user';
  static const _prefsNames = 'demo.names';

  final _rng = math.Random(7);
  late final Map<String, VehicleModel> _vehicles;
  late final Map<String, RouteModel> _routes;
  late List<ScheduleModel> _schedules;
  final _requests = <String, RequestModel>{};
  final _progress = <String, double>{};
  final _deviceControlled = <String>{};
  final _lastRequestAt = <String, DateTime>{};
  late final Timer _ticker;
  var _tickCount = 0;

  final _vehicleCtrl = StreamController<List<VehicleModel>>.broadcast();
  final _requestCtrl = StreamController<List<RequestModel>>.broadcast();
  final _scheduleCtrl = StreamController<List<ScheduleModel>>.broadcast();
  final _userCtrl = StreamController<UserModel?>.broadcast();

  UserModel? _user;

  // ---------------------------------------------------------------- auth

  @override
  UserModel? get currentUser => _user;

  @override
  Stream<UserModel?> get userChanges => _userCtrl.stream;

  @override
  Future<UserModel?> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsUser);
      if (raw != null) _user = UserModel.fromMap(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      _user = null;
    }
    return _user;
  }

  @override
  Future<UserModel> signIn({required String email, required String password}) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final normalized = email.trim().toLowerCase();
    if (!Validators.isKiitEmail(normalized)) {
      throw const AuthFailure('Only @${AppConstants.allowedEmailDomain} accounts can sign in.');
    }
    if (password.length < AppConstants.minPasswordLength) {
      throw const AuthFailure('Incorrect email or password.');
    }
    final names = await _loadNames();
    final seededDriver = SeedData.drivers.where((d) => d.email == normalized).firstOrNull;
    final local = normalized.split('@').first;
    final user =
        seededDriver ??
        UserModel(
          id: 'demo-${local.hashCode.toUnsigned(32)}',
          name: names[normalized] ?? _nameFromEmail(local),
          email: normalized,
          role: local.startsWith('admin') ? UserRole.admin : (local.contains('driver') ? UserRole.driver : UserRole.student),
          createdAt: DateTime.now(),
        );
    await _setUser(user);
    return user;
  }

  @override
  Future<UserModel?> signUp({required String name, required String email, required String password, String? phone}) async {
    final names = await _loadNames();
    names[email.trim().toLowerCase()] = name.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsNames, jsonEncode(names));
    final user = await signIn(email: email, password: password);
    final withPhone = user.copyWith(phone: phone);
    await _setUser(withPhone);
    return withPhone;
  }

  @override
  Future<void> signOut() async {
    final user = _user;
    if (user != null) {
      for (final v in _vehicles.values.where((v) => v.driverId == user.id).toList()) {
        await releaseVehicle(v.id);
      }
    }
    await _setUser(null);
  }

  @override
  Future<UserModel> updateProfile({required String name, String? phone}) async {
    final updated = _user!.copyWith(name: name, phone: phone);
    await _setUser(updated);
    return updated;
  }

  Future<void> _setUser(UserModel? user) async {
    _user = user;
    final prefs = await SharedPreferences.getInstance();
    if (user == null) {
      await prefs.remove(_prefsUser);
    } else {
      await prefs.setString(_prefsUser, jsonEncode(user.toMap()));
    }
    _userCtrl.add(user);
  }

  Future<Map<String, String>> _loadNames() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsNames);
    if (raw == null) return {};
    return Map<String, String>.from(jsonDecode(raw) as Map);
  }

  String _nameFromEmail(String local) => local
      .split(RegExp(r'[._\d]+'))
      .where((p) => p.isNotEmpty)
      .map((p) => p[0].toUpperCase() + p.substring(1))
      .join(' ')
      .ifEmpty('KIIT Student');

  // ------------------------------------------------------------ vehicles

  @override
  Stream<List<VehicleModel>> watchVehicles() => _withInitial(_vehicleList, _vehicleCtrl.stream);

  @override
  Future<List<VehicleModel>> fetchVehicles() async => _vehicleList();

  List<VehicleModel> _vehicleList() => _vehicles.values.toList();

  @override
  Future<void> claimVehicle(String vehicleId, String driverId) async {
    final v = _vehicles[vehicleId]!;
    if (v.driverId != null && v.driverId != driverId && v.status == VehicleStatus.active) {
      throw StateError('${v.vehicleNumber} is already on duty with another driver.');
    }
    _deviceControlled.add(vehicleId);
    _vehicles[vehicleId] = v.copyWith(driverId: driverId, status: VehicleStatus.idle);
    _emitVehicles();
  }

  @override
  Future<void> releaseVehicle(String vehicleId) async {
    _deviceControlled.remove(vehicleId);
    _vehicles[vehicleId] = _vehicles[vehicleId]!.copyWith(clearDriver: true, status: VehicleStatus.offline);
    _emitVehicles();
  }

  @override
  Future<void> setVehicleStatus(String vehicleId, VehicleStatus status) async {
    _vehicles[vehicleId] = _vehicles[vehicleId]!.copyWith(status: status, lastUpdated: DateTime.now());
    _emitVehicles();
  }

  @override
  Future<void> updateVehicleLocation(
    String vehicleId, {
    required double latitude,
    required double longitude,
    required double heading,
  }) async {
    _vehicles[vehicleId] = _vehicles[vehicleId]!.copyWith(
      latitude: latitude,
      longitude: longitude,
      heading: heading,
      lastUpdated: DateTime.now(),
    );
    _emitVehicles();
  }

  @override
  Future<List<DriverContact>> fetchDrivers() async {
    final all = [...SeedData.drivers];
    final me = _user;
    if (me != null && me.isDriver && all.every((d) => d.id != me.id)) all.add(me);
    return all.map((d) {
      final vehicle = _vehicles.values.where((v) => v.driverId == d.id).firstOrNull;
      return DriverContact(id: d.id, name: d.name, phone: d.phone, vehicle: vehicle);
    }).toList();
  }

  // --------------------------------------------------- routes/schedules

  @override
  Future<List<RouteModel>> fetchRoutes() async => _routes.values.toList();

  @override
  Stream<List<ScheduleModel>> watchSchedules() => _withInitial(() => _schedules, _scheduleCtrl.stream);

  // ------------------------------------------------------------ requests

  @override
  Stream<List<RequestModel>> watchRequests() => _withInitial(_requestList, _requestCtrl.stream);

  List<RequestModel> _requestList() => _requests.values.where((r) => !r.isExpired()).toList();

  @override
  Future<void> submitRequest({required String locationName, required double latitude, required double longitude}) async {
    final last = _lastRequestAt[locationName];
    if (last != null && DateTime.now().difference(last) < AppConstants.requestCooldown) {
      throw StateError('You already signalled $locationName. Try again in a few minutes.');
    }
    _lastRequestAt[locationName] = DateTime.now();
    final existing = _requests.values.where((r) => r.locationName == locationName && !r.isExpired()).firstOrNull;
    if (existing != null) {
      _requests[existing.id] = existing.copyWith(studentCount: existing.studentCount + 1, lastRequestedAt: DateTime.now());
    } else {
      final id = 'req-${DateTime.now().microsecondsSinceEpoch}';
      _requests[id] = RequestModel(
        id: id,
        locationName: locationName,
        latitude: latitude,
        longitude: longitude,
        studentCount: 1,
        createdAt: DateTime.now(),
      );
    }
    _requestCtrl.add(_requestList());
  }

  @override
  Future<void> resolveRequest(String requestId) async {
    _requests.remove(requestId);
    _requestCtrl.add(_requestList());
  }

  void _seedRequests() {
    final now = DateTime.now();
    void add(Landmark l, int count, int minutesAgo) {
      final id = 'req-seed-${l.id}';
      _requests[id] = RequestModel(
        id: id,
        locationName: l.name,
        latitude: l.position.latitude,
        longitude: l.position.longitude,
        studentCount: count,
        createdAt: now.subtract(Duration(minutes: minutesAgo)),
        lastRequestedAt: now.subtract(const Duration(minutes: 1)),
      );
    }

    add(CampusLocations.campus14, 12, 9);
    add(CampusLocations.kp6, 5, 4);
    add(CampusLocations.foodCourt, 2, 2);
  }

  // ---------------------------------------------------------- simulation

  void _placeVehicles() {
    for (final v in _vehicles.values.toList()) {
      final route = _routes[v.routeId];
      if (route == null) continue;
      final length = pathLength(route.path);
      _progress[v.id] = _rng.nextDouble() * length * (route.isLoop ? 1 : 2);
      final pos = _positionFor(route, _progress[v.id]!);
      _vehicles[v.id] = v.copyWith(
        latitude: pos.point.latitude,
        longitude: pos.point.longitude,
        heading: pos.heading,
        lastUpdated: v.status == VehicleStatus.active ? DateTime.now() : DateTime.now().subtract(const Duration(hours: 3)),
      );
    }
  }

  /// Loops wrap around; linear routes ping-pong between their terminals.
  ({LatLng point, double heading}) _positionFor(RouteModel route, double progress) {
    final path = route.path;
    final length = pathLength(path);
    if (route.isLoop) return pointAlong(path, progress % length);
    final cycle = progress % (length * 2);
    if (cycle <= length) return pointAlong(path, cycle);
    return pointAlong(path.reversed.toList(), cycle - length);
  }

  void _step() {
    _tickCount++;
    final now = DateTime.now();
    for (final v in _vehicles.values.toList()) {
      if (v.status != VehicleStatus.active || _deviceControlled.contains(v.id)) continue;
      final route = _routes[v.routeId];
      if (route == null) continue;
      final metersPerSecond = v.type == VehicleType.bus ? 5.0 : 4.2;
      _progress[v.id] = (_progress[v.id] ?? 0) + metersPerSecond * _tick.inSeconds;
      final pos = _positionFor(route, _progress[v.id]!);
      _vehicles[v.id] = v.copyWith(
        latitude: pos.point.latitude,
        longitude: pos.point.longitude,
        heading: pos.heading,
        lastUpdated: now,
      );
    }
    _emitVehicles();

    // Every ~20 s someone new joins a waiting crowd.
    if (_tickCount % 10 == 0 && _requests.isNotEmpty) {
      final r = _requests.values.elementAt(_rng.nextInt(_requests.length));
      _requests[r.id] = r.copyWith(studentCount: r.studentCount + 1, lastRequestedAt: now);
      _requestCtrl.add(_requestList());
    }
  }

  void _emitVehicles() => _vehicleCtrl.add(_vehicleList());

  Stream<T> _withInitial<T>(T Function() current, Stream<T> updates) async* {
    yield current();
    yield* updates;
  }

  @override
  void dispose() {
    _ticker.cancel();
    _vehicleCtrl.close();
    _requestCtrl.close();
    _scheduleCtrl.close();
    _userCtrl.close();
  }
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
