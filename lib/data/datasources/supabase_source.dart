import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/realtime_service.dart';
import '../../core/utils/validators.dart';
import '../models/driver_contact.dart';
import '../models/request_model.dart';
import '../models/route_model.dart';
import '../models/schedule_model.dart';
import '../models/user_model.dart';
import '../models/vehicle_model.dart';
import 'transit_source.dart';

/// All Supabase reads, writes and subscriptions. Schema: `supabase/schema.sql`.
class SupabaseSource implements TransitSource {
  SupabaseSource(this._client) : _auth = AuthService(_client), _realtime = RealtimeService(_client) {
    _authSub = _auth.authStateChanges.listen(_onAuthChange);
  }

  final SupabaseClient _client;
  final AuthService _auth;
  final RealtimeService _realtime;
  late final StreamSubscription<AuthState> _authSub;
  final _userCtrl = StreamController<UserModel?>.broadcast();
  UserModel? _user;

  // ---------------------------------------------------------------- auth

  @override
  UserModel? get currentUser => _user;

  @override
  Stream<UserModel?> get userChanges => _userCtrl.stream;

  Future<void> _onAuthChange(AuthState state) async {
    switch (state.event) {
      case AuthChangeEvent.signedOut:
        _setUser(null);
      case AuthChangeEvent.signedIn || AuthChangeEvent.userUpdated:
        final id = state.session?.user.id;
        if (id != null && _user?.id != id) _setUser(await _loadProfile(id));
      default:
        break;
    }
  }

  void _setUser(UserModel? user) {
    _user = user;
    _userCtrl.add(user);
  }

  Future<UserModel?> _loadProfile(String id) async {
    final row = await _client.from('profiles').select().eq('id', id).maybeSingle();
    return row == null ? null : UserModel.fromMap(row);
  }

  @override
  Future<UserModel?> restoreSession() async {
    final authUser = _auth.currentUser;
    if (authUser == null) return null;
    try {
      _user = await _loadProfile(authUser.id);
    } catch (_) {
      _user = null;
    }
    return _user;
  }

  @override
  Future<UserModel> signIn({required String email, required String password}) async {
    if (!Validators.isKiitEmail(email)) {
      throw const AuthFailure('Only @${AppConstants.allowedEmailDomain} accounts can sign in.');
    }
    try {
      final res = await _auth.signIn(email.trim().toLowerCase(), password);
      final profile = await _loadProfile(res.user!.id);
      if (profile == null) {
        await _auth.signOut();
        throw const AuthFailure('No profile found for this account. Contact the transport office.');
      }
      _setUser(profile);
      return profile;
    } on AuthException catch (e) {
      throw AuthFailure(_friendly(e.message));
    }
  }

  @override
  Future<UserModel?> signUp({required String name, required String email, required String password, String? phone}) async {
    if (!Validators.isKiitEmail(email)) {
      throw const AuthFailure('Registration is limited to @${AppConstants.allowedEmailDomain} emails.');
    }
    try {
      final res = await _auth.signUp(email.trim().toLowerCase(), password, name: name.trim(), phone: phone);
      // With email confirmation on there is no session yet.
      if (res.session == null || res.user == null) return null;
      final profile = await _loadProfile(res.user!.id);
      _setUser(profile);
      return profile;
    } on AuthException catch (e) {
      throw AuthFailure(_friendly(e.message));
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<UserModel> updateProfile({required String name, String? phone}) async {
    final row = await _client.from('profiles').update({'name': name, 'phone': phone}).eq('id', _user!.id).select().single();
    final updated = UserModel.fromMap(row);
    _setUser(updated);
    return updated;
  }

  String _friendly(String message) {
    final m = message.toLowerCase();
    if (m.contains('invalid login')) return 'Incorrect email or password.';
    if (m.contains('already registered')) return 'An account with this email already exists.';
    if (m.contains('email not confirmed')) return 'Confirm your email first — check your KIIT inbox.';
    if (m.contains('domain')) return 'Registration is limited to @${AppConstants.allowedEmailDomain} emails.';
    return message;
  }

  // ------------------------------------------------------------ vehicles

  @override
  Stream<List<VehicleModel>> watchVehicles() =>
      _realtime.watchTable('vehicles', orderBy: 'vehicle_number').map((rows) => rows.map(VehicleModel.fromMap).toList());

  @override
  Future<List<VehicleModel>> fetchVehicles() async {
    final rows = await _client.from('vehicles').select().order('vehicle_number');
    return rows.map(VehicleModel.fromMap).toList();
  }

  @override
  Future<void> claimVehicle(String vehicleId, String driverId) async {
    // Only succeeds if nobody else is actively driving this vehicle.
    final rows = await _client
        .from('vehicles')
        .update({'driver_id': driverId, 'status': VehicleStatus.idle.name})
        .eq('id', vehicleId)
        .or('driver_id.is.null,driver_id.eq.$driverId,status.neq.active')
        .select();
    if (rows.isEmpty) throw StateError('This vehicle is already on duty with another driver.');
  }

  @override
  Future<void> releaseVehicle(String vehicleId) =>
      _client.from('vehicles').update({'driver_id': null, 'status': VehicleStatus.offline.name}).eq('id', vehicleId);

  @override
  Future<void> setVehicleStatus(String vehicleId, VehicleStatus status) => _client
      .from('vehicles')
      .update({'status': status.name, 'last_updated': DateTime.now().toUtc().toIso8601String()})
      .eq('id', vehicleId);

  @override
  Future<void> updateVehicleLocation(
    String vehicleId, {
    required double latitude,
    required double longitude,
    required double heading,
  }) => _client
      .from('vehicles')
      .update({
        'latitude': latitude,
        'longitude': longitude,
        'heading': heading,
        'last_updated': DateTime.now().toUtc().toIso8601String(),
      })
      .eq('id', vehicleId);

  @override
  Future<List<DriverContact>> fetchDrivers() async {
    final (profiles, vehicles) = await (
      _client.from('profiles').select('id, name, phone').eq('role', 'driver').order('name'),
      fetchVehicles(),
    ).wait;
    return profiles
        .map(
          (p) => DriverContact(
            id: p['id'] as String,
            name: (p['name'] as String?) ?? 'Driver',
            phone: p['phone'] as String?,
            vehicle: vehicles.where((v) => v.driverId == p['id']).firstOrNull,
          ),
        )
        .toList();
  }

  // --------------------------------------------------- routes/schedules

  @override
  Future<List<RouteModel>> fetchRoutes() async {
    final rows = await _client.from('routes').select().order('route_name');
    return rows.map(RouteModel.fromMap).toList();
  }

  @override
  Stream<List<ScheduleModel>> watchSchedules() =>
      _realtime.watchTable('schedules', orderBy: 'departure_time').map((rows) => rows.map(ScheduleModel.fromMap).toList());

  // ------------------------------------------------------------ requests

  @override
  Stream<List<RequestModel>> watchRequests() => _realtime
      .watchTable('requests', orderBy: 'created_at')
      .map((rows) => rows.map(RequestModel.fromMap).where((r) => !r.isExpired()).toList());

  @override
  Future<void> submitRequest({required String locationName, required double latitude, required double longitude}) async {
    try {
      await _client.rpc(
        'submit_demand_request',
        params: {'p_location_name': locationName, 'p_latitude': latitude, 'p_longitude': longitude},
      );
    } on PostgrestException catch (e) {
      if (e.message.contains('cooldown')) {
        throw StateError('You already signalled $locationName. Try again in a few minutes.');
      }
      rethrow;
    }
  }

  @override
  Future<void> resolveRequest(String requestId) => _client.from('requests').delete().eq('id', requestId);

  @override
  void dispose() {
    _authSub.cancel();
    _userCtrl.close();
  }
}
