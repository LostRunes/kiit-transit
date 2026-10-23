import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../core/services/location_service.dart';
import '../core/utils/geo_utils.dart';
import '../data/datasources/location_source.dart';
import '../data/models/vehicle_model.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/vehicle_repository.dart';

/// Driver side: vehicle assignment, duty on/off and GPS broadcasting.
///
/// GPS fixes arrive as fast as the device reports them, but are sent to the
/// backend at most every [AppConstants.gpsBroadcastInterval]. The same timer
/// acts as a heartbeat while parked, so students can tell a stopped vehicle
/// from one whose phone has gone offline.
class VehicleViewModel extends ChangeNotifier {
  VehicleViewModel(this._vehicles, this._auth, this._location);

  final VehicleRepository _vehicles;
  final AuthRepository _auth;
  final LocationSource _location;

  StreamSubscription<List<VehicleModel>>? _vehicleSub;
  StreamSubscription<GpsFix>? _gpsSub;
  Timer? _heartbeat;

  List<VehicleModel> vehicles = const [];
  bool loading = true;
  bool busy = false;
  String? error;
  LocationAccess? locationAccess;

  bool onDuty = false;
  DateTime? dutyStartedAt;
  GpsFix? lastFix;
  DateTime? lastSentAt;
  int updatesSent = 0;
  int failedUpdates = 0;
  double distanceCoveredMeters = 0;

  String? get _driverId => _auth.currentUser?.id;

  VehicleModel? get myVehicle => _driverId == null ? null : vehicles.where((v) => v.driverId == _driverId).firstOrNull;

  /// Vehicles this driver may claim: free, or not currently being driven.
  List<VehicleModel> get availableVehicles =>
      vehicles.where((v) => v.driverId == null || v.driverId == _driverId || v.status != VehicleStatus.active).toList();

  bool isTaken(VehicleModel v) => v.driverId != null && v.driverId != _driverId && v.status == VehicleStatus.active;

  void start() {
    if (_vehicleSub != null) return;
    _vehicleSub = _vehicles.watchVehicles().listen(
      (list) {
        vehicles = list..sort((a, b) => a.vehicleNumber.compareTo(b.vehicleNumber));
        loading = false;
        notifyListeners();
      },
      onError: (Object e) {
        error = 'Connection lost. Retrying…';
        notifyListeners();
      },
    );
  }

  Future<bool> claim(VehicleModel vehicle) => _guard(() async {
    final current = myVehicle;
    if (current != null && current.id != vehicle.id) await _vehicles.release(current.id);
    await _vehicles.claim(vehicle.id, _driverId!);
  });

  Future<bool> startDuty() async {
    final vehicle = myVehicle;
    if (vehicle == null) {
      error = 'Select your vehicle first.';
      notifyListeners();
      return false;
    }
    locationAccess = await _location.service.ensurePermission();
    if (locationAccess != LocationAccess.granted) {
      error = locationAccess == LocationAccess.serviceDisabled
          ? 'Turn on location services to start broadcasting.'
          : 'Location permission is required to broadcast your position.';
      notifyListeners();
      return false;
    }
    return _guard(() async {
      await _vehicles.goOnDuty(vehicle.id);
      onDuty = true;
      dutyStartedAt = DateTime.now();
      updatesSent = 0;
      failedUpdates = 0;
      distanceCoveredMeters = 0;
      _gpsSub = _location
          .broadcastFixes(vehicleNumber: vehicle.vehicleNumber)
          .listen(
            _onFix,
            onError: (Object e) {
              error = 'GPS signal lost. Waiting for a fix…';
              notifyListeners();
            },
          );
      _heartbeat = Timer.periodic(AppConstants.gpsBroadcastInterval, (_) => _send());
    });
  }

  void _onFix(GpsFix fix) {
    final previous = lastFix;
    if (previous != null && fix.accuracy < 30) {
      distanceCoveredMeters += distanceMeters(previous.position, fix.position);
    }
    lastFix = fix;
    error = null;
    // Send the very first fix immediately so the vehicle appears at once.
    if (lastSentAt == null) unawaited(_send());
    notifyListeners();
  }

  Future<void> _send() async {
    final fix = lastFix;
    final vehicle = myVehicle;
    if (!onDuty || fix == null || vehicle == null) return;
    try {
      await _vehicles.broadcast(vehicle.id, lat: fix.position.latitude, lng: fix.position.longitude, heading: fix.heading);
      lastSentAt = DateTime.now();
      updatesSent++;
    } catch (e) {
      failedUpdates++;
      debugPrint('Broadcast failed: $e');
    }
    notifyListeners();
  }

  Future<void> stopDuty() async {
    await _stopStreams();
    final vehicle = myVehicle;
    if (vehicle != null) {
      try {
        await _vehicles.goOffDuty(vehicle.id);
      } catch (_) {}
    }
    onDuty = false;
    lastSentAt = null;
    notifyListeners();
  }

  /// Ends duty and hands the vehicle back (used on sign-out).
  Future<void> endShift() async {
    if (onDuty) await stopDuty();
    final vehicle = myVehicle;
    if (vehicle != null) {
      try {
        await _vehicles.release(vehicle.id);
      } catch (_) {}
    }
  }

  Future<void> _stopStreams() async {
    _heartbeat?.cancel();
    _heartbeat = null;
    await _gpsSub?.cancel();
    _gpsSub = null;
  }

  Future<bool> _guard(Future<void> Function() action) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on StateError catch (e) {
      error = e.message;
    } catch (e) {
      error = 'Could not reach the server. Try again.';
      debugPrint('Vehicle action failed: $e');
    } finally {
      busy = false;
      notifyListeners();
    }
    return false;
  }

  @override
  void dispose() {
    _vehicleSub?.cancel();
    _stopStreams();
    super.dispose();
  }
}
