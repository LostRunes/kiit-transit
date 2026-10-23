import 'package:flutter_test/flutter_test.dart';
import 'package:kiit_transit/core/services/journey_planner.dart';
import 'package:kiit_transit/data/models/network_model.dart';
import 'package:latlong2/latlong.dart';

/// Stops laid out about 1.1 km apart along a line, plus one stop 200 m
/// from "d" to exercise walking changes.
NetworkStop _stop(String id, double lat, double lng, {bool campus = false}) =>
    NetworkStop(id: id, name: id.toUpperCase(), position: LatLng(lat, lng), isCampus: campus);

NetworkRoute _route(String id, List<String> stops, {NetworkOperator op = NetworkOperator.mobus}) => NetworkRoute(
  id: id,
  ref: id,
  name: id,
  operator: op,
  mode: NetworkMode.bus,
  color: '#000000',
  stopIds: stops,
  geometry: const [],
);

void main() {
  final stops = [
    _stop('a', 20.30, 85.80, campus: true),
    _stop('b', 20.31, 85.80),
    _stop('c', 20.32, 85.80),
    _stop('d', 20.33, 85.80),
    _stop('d2', 20.3318, 85.80), // ~200 m north of d
    _stop('e', 20.34, 85.80),
    _stop('f', 20.35, 85.80),
    _stop('x', 20.30, 85.83),
  ];
  final net = TransitNetwork(
    stops: stops,
    routes: [
      _route('k1', ['a', 'b'], op: NetworkOperator.kiit),
      _route('m1', ['b', 'c', 'd']),
      _route('m2', ['d2', 'e', 'f']),
      _route('m3', ['a', 'x']),
    ],
  );
  final planner = JourneyPlanner(net);
  NetworkStop s(String id) => net.stop(id)!;

  test('finds a direct ride in either direction', () {
    final there = planner.plan(s('b'), s('d'));
    expect(there.first.isDirect, isTrue);
    expect(there.first.rides.single.route!.id, 'm1');
    expect(there.first.rides.single.stopCount, 2);

    final back = planner.plan(s('d'), s('b'));
    expect(back.first.rides.single.from.id, 'd');
    expect(back.first.rides.single.to.id, 'b');
  });

  test('changes routes, including a short walk between nearby stops', () {
    final trips = planner.plan(s('a'), s('f'));
    expect(trips, isNotEmpty);
    final best = trips.first;
    expect(best.changes, 2);
    expect(best.rides.map((l) => l.route!.id), ['k1', 'm1', 'm2']);
    expect(best.legs.where((l) => l.isWalk).single.to.id, 'd2');
    expect(best.usesKiit && best.usesMobus, isTrue);
  });

  test('respects the network filter', () {
    expect(planner.plan(s('a'), s('d'), filter: NetworkFilter.mobus), isEmpty);
    expect(planner.plan(s('a'), s('d'), filter: NetworkFilter.all).first.changes, 1);
  });

  test('routes through a chosen stop', () {
    final trips = planner.planVia(s('x'), s('a'), s('c'));
    expect(trips, isNotEmpty);
    expect(trips.first.rides.first.route!.id, 'm3');
    expect(trips.first.legs.any((l) => l.to.id == 'a'), isTrue);
  });

  test('returns nothing for the same stop or unreachable stops', () {
    expect(planner.plan(s('a'), s('a')), isEmpty);
    final lonely = TransitNetwork(
      stops: stops,
      routes: [
        _route('m1', ['b', 'c']),
      ],
    );
    expect(JourneyPlanner(lonely).plan(lonely.stop('b')!, lonely.stop('f')!), isEmpty);
  });
}
