import '../models/driver_contact.dart';
import '../models/request_model.dart';
import '../models/route_model.dart';
import '../models/schedule_model.dart';
import '../models/user_model.dart';
import '../models/vehicle_model.dart';

/// Everything the app reads or writes, independent of the backend.
///
/// [SupabaseSource] is the production implementation; [DemoSource] is an
/// in-memory stand-in with simulated vehicles used when Supabase is not
/// configured.
abstract class TransitSource {
  // Auth
  UserModel? get currentUser;
  Stream<UserModel?> get userChanges;
  Future<UserModel?> restoreSession();
  Future<UserModel> signIn({required String email, required String password});
  Future<UserModel?> signUp({required String name, required String email, required String password, String? phone});
  Future<void> signOut();
  Future<UserModel> updateProfile({required String name, String? phone});

  // Vehicles
  Stream<List<VehicleModel>> watchVehicles();
  Future<List<VehicleModel>> fetchVehicles();
  Future<void> claimVehicle(String vehicleId, String driverId);
  Future<void> releaseVehicle(String vehicleId);
  Future<void> setVehicleStatus(String vehicleId, VehicleStatus status);
  Future<void> updateVehicleLocation(
    String vehicleId, {
    required double latitude,
    required double longitude,
    required double heading,
  });
  Future<List<DriverContact>> fetchDrivers();

  // Routes & schedules
  Future<List<RouteModel>> fetchRoutes();
  Stream<List<ScheduleModel>> watchSchedules();

  // Demand requests
  Stream<List<RequestModel>> watchRequests();
  Future<void> submitRequest({required String locationName, required double latitude, required double longitude});
  Future<void> resolveRequest(String requestId);

  void dispose();
}

class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;

  @override
  String toString() => message;
}
