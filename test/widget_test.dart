import 'package:flutter_test/flutter_test.dart';
import 'package:kiit_transit/core/constants/campus_locations.dart';
import 'package:kiit_transit/core/utils/formatters.dart';
import 'package:kiit_transit/core/utils/geo_utils.dart';
import 'package:kiit_transit/core/utils/validators.dart';
import 'package:kiit_transit/data/datasources/seed_data.dart';
import 'package:kiit_transit/data/models/request_model.dart';
import 'package:kiit_transit/data/models/schedule_model.dart';
import 'package:kiit_transit/data/models/vehicle_model.dart';
import 'package:kiit_transit/data/repositories/route_repository.dart';
import 'package:kiit_transit/data/datasources/demo_source.dart';
import 'package:kiit_transit/viewmodels/route_viewmodel.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ETA', () {
    test('matches the spec example: 650 m at 250 m/min is 3 minutes', () {
      expect(etaMinutes(650), 3);
    });

    test('formats arrival and longer waits', () {
      expect(formatEta(1), 'Arriving');
      expect(formatEta(12), '12 min');
      expect(formatEta(75), '1 h 15 min');
    });
  });

  group('geo', () {
    test('distance between Campus 6 and Campus 3 is a few hundred metres', () {
      final d = distanceMeters(CampusLocations.campus6.position, CampusLocations.campus3.position);
      expect(d, inInclusiveRange(250, 450));
    });

    test('heading interpolation takes the short way round', () {
      expect(lerpHeading(350, 10, 0.5), closeTo(0, 0.001));
    });

    test('pointAlong walks the path', () {
      final path = SeedData.routes.first.path;
      final end = pointAlong(path, pathLength(path) + 100).point;
      expect(distanceMeters(end, path.last), lessThan(1));
    });
  });

  group('validators', () {
    test('only KIIT emails are accepted', () {
      expect(Validators.kiitEmail('2205123@kiit.ac.in'), isNull);
      expect(Validators.kiitEmail('someone@gmail.com'), isNotNull);
      expect(Validators.kiitEmail('bad'), isNotNull);
    });
  });

  group('models', () {
    test('schedule status and times', () {
      final s = ScheduleModel.fromMap({
        'id': '1',
        'route_id': 'r',
        'departure_time': '08:30:00',
        'arrival_time': '08:55:00',
        'delay_minutes': 5,
      });
      expect(s.departureMinutes, 510);
      expect(s.status, ScheduleStatus.delayed);
      expect(s.expectedDepartureMinutes, 515);
      expect(ScheduleModel.toTime(515), '08:35:00');
    });

    test('stale vehicles are not live', () {
      final v = VehicleModel.fromMap({
        'id': 'v',
        'vehicle_number': 'EV-03',
        'vehicle_type': 'ev',
        'status': 'active',
        'latitude': 20.35,
        'longitude': 85.82,
        'last_updated': DateTime.now().subtract(const Duration(minutes: 10)).toUtc().toIso8601String(),
      });
      expect(v.isLive, isFalse);
      expect(v.copyWith(lastUpdated: DateTime.now()).isLive, isTrue);
    });

    test('request level buckets', () {
      RequestModel r(int n) =>
          RequestModel(id: '1', locationName: 'x', latitude: 0, longitude: 0, studentCount: n, createdAt: DateTime.now());
      expect(r(2).level, 1);
      expect(r(6).level, 2);
      expect(r(12).level, 3);
    });
  });

  group('demo backend', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('driver login gets the driver role and requests aggregate', () async {
      final source = DemoSource();
      addTearDown(source.dispose);

      final driver = await source.signIn(email: 'driver@kiit.ac.in', password: 'demo1234');
      expect(driver.isDriver, isTrue);
      await expectLater(source.signIn(email: 'x@gmail.com', password: 'demo1234'), throwsA(anything));

      final before = (await source.watchRequests().first).length;
      await source.submitRequest(locationName: 'Campus 25', latitude: 20.3645, longitude: 85.817);
      final after = await source.watchRequests().first;
      expect(after.length, before + 1);
      expect(() => source.submitRequest(locationName: 'Campus 25', latitude: 0, longitude: 0), throwsStateError);
    });

    test('schedule view model finds the next bus departure', () async {
      final source = DemoSource();
      addTearDown(source.dispose);
      final vm = RouteViewModel(RouteRepository(source))..nowMinutes = () => 9 * 60;
      addTearDown(vm.dispose);
      await vm.start();
      await Future<void>.delayed(Duration.zero);

      expect(vm.busRoutes.length, 2);
      final next = vm.nextDeparture(SeedData.routeB)!;
      expect(next.expectedDepartureMinutes, greaterThanOrEqualTo(9 * 60));
      expect(vm.upcoming(SeedData.routeB).length, 5);
    });
  });
}
