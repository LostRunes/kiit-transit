import '../../core/constants/campus_locations.dart';
import '../models/route_model.dart';
import '../models/schedule_model.dart';
import '../models/user_model.dart';
import '../models/vehicle_model.dart';

/// Reference data used by demo mode. `supabase/seed.sql` mirrors it (same
/// IDs) so both backends show the same network.
class SeedData {
  SeedData._();

  static RouteStop _stop(Landmark l) => RouteStop(name: l.name, latitude: l.position.latitude, longitude: l.position.longitude);

  static const routeA = 'a0000000-0000-4000-8000-000000000001';
  static const routeB = 'a0000000-0000-4000-8000-000000000002';
  static const routeC = 'a0000000-0000-4000-8000-000000000003';
  static const routeD = 'a0000000-0000-4000-8000-000000000004';

  static final routes = <RouteModel>[
    RouteModel(
      id: routeA,
      name: 'Route A -- Hostels to Campus 15',
      type: VehicleType.ev,
      color: '#10B981',
      stops: [
        CampusLocations.kp8,
        CampusLocations.kp15,
        CampusLocations.kp5,
        CampusLocations.campus6,
        CampusLocations.foodCourt,
        CampusLocations.library,
        CampusLocations.campus3,
        CampusLocations.kp7,
        CampusLocations.kp6,
        CampusLocations.campus15,
      ].map(_stop).toList(),
    ),
    RouteModel(
      id: routeB,
      name: 'Route B -- Campus 25 Express',
      type: VehicleType.bus,
      color: '#F59E0B',
      stops: [
        CampusLocations.campus25,
        CampusLocations.queensHostel,
        CampusLocations.cricketGround,
        CampusLocations.campus14,
        CampusLocations.library,
        CampusLocations.mainGate,
        CampusLocations.campus15,
      ].map(_stop).toList(),
    ),
    RouteModel(
      id: routeC,
      name: 'Route C -- Day Scholar Shuttle',
      type: VehicleType.bus,
      color: '#3B82F6',
      stops: [
        CampusLocations.patiaPickup,
        CampusLocations.kp8,
        CampusLocations.kp15,
        CampusLocations.campus6,
        CampusLocations.campus17,
        CampusLocations.campus15,
      ].map(_stop).toList(),
    ),
    RouteModel(
      id: routeD,
      name: 'Route D -- Campus Loop',
      type: VehicleType.ev,
      color: '#8B5CF6',
      isLoop: true,
      stops: [
        CampusLocations.campus6,
        CampusLocations.campus17,
        CampusLocations.kp7,
        CampusLocations.campus3,
        CampusLocations.library,
        CampusLocations.campus14,
        CampusLocations.kp5,
        CampusLocations.kp15,
      ].map(_stop).toList(),
    ),
  ];

  static const drivers = <UserModel>[
    UserModel(
      id: 'd0000000-0000-4000-8000-000000000001',
      name: 'Ramesh Behera',
      email: 'driver@kiit.ac.in',
      role: UserRole.driver,
      phone: '+919437000101',
    ),
    UserModel(
      id: 'd0000000-0000-4000-8000-000000000002',
      name: 'Sanjay Pradhan',
      email: 'sanjay.driver@kiit.ac.in',
      role: UserRole.driver,
      phone: '+919437000102',
    ),
    UserModel(
      id: 'd0000000-0000-4000-8000-000000000003',
      name: 'Bikash Nayak',
      email: 'bikash.driver@kiit.ac.in',
      role: UserRole.driver,
      phone: '+919437000103',
    ),
    UserModel(
      id: 'd0000000-0000-4000-8000-000000000004',
      name: 'Prakash Sahoo',
      email: 'prakash.driver@kiit.ac.in',
      role: UserRole.driver,
      phone: '+919437000104',
    ),
    UserModel(
      id: 'd0000000-0000-4000-8000-000000000005',
      name: 'Manoj Das',
      email: 'manoj.driver@kiit.ac.in',
      role: UserRole.driver,
      phone: '+919437000105',
    ),
    UserModel(
      id: 'd0000000-0000-4000-8000-000000000006',
      name: 'Suresh Mohanty',
      email: 'suresh.driver@kiit.ac.in',
      role: UserRole.driver,
      phone: '+919437000106',
    ),
  ];

  /// Vehicles with the route they run. The first driver starts unassigned so
  /// the demo driver login can claim a vehicle.
  static final vehicles = <VehicleModel>[
    const VehicleModel(
      id: 'b0000000-0000-4000-8000-000000000001',
      vehicleNumber: 'EV-01',
      type: VehicleType.ev,
      status: VehicleStatus.active,
      routeId: routeA,
      driverId: 'd0000000-0000-4000-8000-000000000002',
    ),
    const VehicleModel(
      id: 'b0000000-0000-4000-8000-000000000002',
      vehicleNumber: 'EV-02',
      type: VehicleType.ev,
      status: VehicleStatus.active,
      routeId: routeA,
      driverId: 'd0000000-0000-4000-8000-000000000003',
    ),
    const VehicleModel(
      id: 'b0000000-0000-4000-8000-000000000003',
      vehicleNumber: 'EV-03',
      type: VehicleType.ev,
      status: VehicleStatus.active,
      routeId: routeD,
      driverId: 'd0000000-0000-4000-8000-000000000004',
    ),
    const VehicleModel(
      id: 'b0000000-0000-4000-8000-000000000004',
      vehicleNumber: 'EV-04',
      type: VehicleType.ev,
      status: VehicleStatus.offline,
      routeId: routeD,
    ),
    const VehicleModel(
      id: 'b0000000-0000-4000-8000-000000000005',
      vehicleNumber: 'BUS-01',
      type: VehicleType.bus,
      status: VehicleStatus.active,
      routeId: routeB,
      driverId: 'd0000000-0000-4000-8000-000000000005',
    ),
    const VehicleModel(
      id: 'b0000000-0000-4000-8000-000000000006',
      vehicleNumber: 'BUS-02',
      type: VehicleType.bus,
      status: VehicleStatus.active,
      routeId: routeC,
      driverId: 'd0000000-0000-4000-8000-000000000006',
    ),
    const VehicleModel(
      id: 'b0000000-0000-4000-8000-000000000007',
      vehicleNumber: 'BUS-03',
      type: VehicleType.bus,
      status: VehicleStatus.offline,
      routeId: routeB,
    ),
    const VehicleModel(
      id: 'b0000000-0000-4000-8000-000000000008',
      vehicleNumber: 'EV-05',
      type: VehicleType.ev,
      status: VehicleStatus.offline,
      routeId: routeA,
    ),
  ];

  /// Bus timetables: Route B every 30 min, Route C every 45 min.
  static List<ScheduleModel> schedules() {
    final out = <ScheduleModel>[];
    void generate(String routeId, int start, int end, int every, int duration) {
      var i = 0;
      for (var t = start; t <= end; t += every, i++) {
        out.add(
          ScheduleModel(
            id: '$routeId-$t',
            routeId: routeId,
            departureMinutes: t,
            arrivalMinutes: t + duration,
            delayMinutes: i % 5 == 2 ? 5 + (i % 3) * 3 : 0,
            isCancelled: i == 7,
          ),
        );
      }
    }

    generate(routeB, 7 * 60 + 30, 20 * 60, 30, 25);
    generate(routeC, 7 * 60, 19 * 60 + 30, 45, 30);
    return out;
  }
}
