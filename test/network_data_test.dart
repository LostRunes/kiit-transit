import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiit_transit/core/services/journey_planner.dart';
import 'package:kiit_transit/data/models/network_model.dart';

/// Sanity checks on the bundled network built by tool/build_network.py.
void main() {
  final net = TransitNetwork.fromJson(
    jsonDecode(File('assets/network/network.json').readAsStringSync()) as Map<String, dynamic>,
  );
  final planner = JourneyPlanner(net);
  NetworkStop byName(String name) => net.stops.values.firstWhere((s) => s.name == name);

  test('contains both networks with traced geometry', () {
    expect(net.routes.where((r) => r.isKiit), hasLength(38));
    expect(net.routes.where((r) => !r.isKiit), hasLength(27));
    for (final r in net.routes) {
      expect(r.geometry.length, greaterThanOrEqualTo(2), reason: r.id);
      for (final id in r.stopIds) {
        expect(net.stop(id), isNotNull, reason: '${r.id} -> $id');
      }
    }
  });

  test('every stop lies in the Bhubaneswar-Cuttack-Puri region', () {
    for (final s in net.stops.values) {
      expect(s.position.latitude, inInclusiveRange(19.7, 20.6), reason: s.name);
      expect(s.position.longitude, inInclusiveRange(85.5, 86.2), reason: s.name);
    }
  });

  test('KIIT campuses link directly where the research says so', () {
    final trips = planner.plan(byName('Campus 3 (Kathajodi)'), byName('Campus 25 (CSE)'));
    expect(trips.first.isDirect, isTrue);
    expect(trips.where((j) => j.isDirect).map((j) => j.rides.single.route!.ref), contains('B-23'));
  });

  test('a campus reaches the railway station through Mo Bus', () {
    final trips = planner.plan(byName('Campus 6 (Kosi)'), byName('Bhubaneswar Railway Station'));
    expect(trips, isNotEmpty);
    expect(trips.first.usesMobus, isTrue);
  });

  test('Mo Bus 12 runs Nandankanan to the railway station directly', () {
    final trips = planner.plan(byName('Nandankanan'), byName('Bhubaneswar Railway Station'), filter: NetworkFilter.mobus);
    expect(trips.any((j) => j.isDirect && j.rides.single.route!.ref == '12'), isTrue);
  });
}
