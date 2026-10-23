import 'vehicle_model.dart';

/// A row in the driver directory: a driver profile joined with their vehicle.
class DriverContact {
  const DriverContact({required this.id, required this.name, this.phone, this.vehicle});

  final String id;
  final String name;
  final String? phone;
  final VehicleModel? vehicle;

  bool get isOnDuty => vehicle?.status == VehicleStatus.active;
}
