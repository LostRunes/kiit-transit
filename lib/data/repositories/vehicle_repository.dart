import '../datasources/transit_source.dart';
import '../models/driver_contact.dart';
import '../models/vehicle_model.dart';

class VehicleRepository {
  VehicleRepository(this._source);

  final TransitSource _source;

  Stream<List<VehicleModel>> watchVehicles() => _source.watchVehicles();

  Future<List<VehicleModel>> fetchVehicles() => _source.fetchVehicles();

  Future<List<DriverContact>> fetchDrivers() => _source.fetchDrivers();

  Future<void> claim(String vehicleId, String driverId) => _source.claimVehicle(vehicleId, driverId);

  Future<void> release(String vehicleId) => _source.releaseVehicle(vehicleId);

  Future<void> goOnDuty(String vehicleId) => _source.setVehicleStatus(vehicleId, VehicleStatus.active);

  Future<void> goOffDuty(String vehicleId) => _source.setVehicleStatus(vehicleId, VehicleStatus.idle);

  Future<void> broadcast(String vehicleId, {required double lat, required double lng, required double heading}) =>
      _source.updateVehicleLocation(vehicleId, latitude: lat, longitude: lng, heading: heading);
}
