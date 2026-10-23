import 'package:latlong2/latlong.dart';

import '../../data/models/network_model.dart';
import '../utils/geo_utils.dart';

/// One part of a trip: riding a route between two stops, or walking.
class JourneyLeg {
  const JourneyLeg.ride({required this.route, required this.from, required this.to, required this.stops, required this.minutes})
    : walkMeters = 0;

  const JourneyLeg.walk({required this.from, required this.to, required this.walkMeters, required this.minutes})
    : route = null,
      stops = const [];

  final NetworkRoute? route;
  final NetworkStop from;
  final NetworkStop to;

  /// Stops visited on a ride, boarding and alighting stops included.
  final List<NetworkStop> stops;
  final double walkMeters;
  final int minutes;

  bool get isWalk => route == null;
  int get stopCount => stops.isEmpty ? 0 : stops.length - 1;
}

class Journey {
  Journey(this.legs);

  final List<JourneyLeg> legs;

  List<JourneyLeg> get rides => legs.where((l) => !l.isWalk).toList();
  int get changes => rides.isEmpty ? 0 : rides.length - 1;
  bool get isDirect => changes == 0;
  int get rideMinutes => rides.fold(0, (s, l) => s + l.minutes);
  int get walkMinutes => legs.where((l) => l.isWalk).fold(0, (s, l) => s + l.minutes);

  /// Moving time plus a nominal wait per boarding, used for ranking only.
  int get score => rideMinutes + walkMinutes + rides.length * JourneyPlanner.boardingPenalty;

  bool get usesKiit => rides.any((l) => l.route!.isKiit);
  bool get usesMobus => rides.any((l) => !l.route!.isKiit);

  String get signature => rides.map((l) => l.route!.id).join('|');
}

/// Finds trips across the KIIT and Mo Bus networks with up to two changes.
/// Routes run both ways. Changes can include a short walk between nearby stops.
class JourneyPlanner {
  JourneyPlanner(this.network, {this.maxWalkMeters = 450}) {
    for (final r in network.routes) {
      if (r.geometry.length < 2) continue;
      final cum = <double>[0];
      for (var i = 1; i < r.geometry.length; i++) {
        cum.add(cum.last + distanceMeters(r.geometry[i - 1], r.geometry[i]));
      }
      _along[r.id] = [for (final id in r.stopIds) cum[nearestIndex(r.geometry, network.stop(id)!.position)]];
    }
    final list = network.stops.values.where((s) => network.routesAt(s.id).isNotEmpty).toList();
    for (final a in list) {
      for (final b in list) {
        if (a.id == b.id) continue;
        final d = distanceMeters(a.position, b.position);
        if (d <= maxWalkMeters) (_walks[a.id] ??= []).add((stop: b, meters: d));
      }
    }
  }

  final TransitNetwork network;
  final double maxWalkMeters;
  final Map<String, List<({NetworkStop stop, double meters})>> _walks = {};

  /// Distance along each route's road geometry at every stop.
  final Map<String, List<double>> _along = {};

  static const walkMetersPerMinute = 75.0;
  static const boardingPenalty = 8;

  /// Minutes to ride [meters]: city pace including stops, faster once a leg
  /// leaves town (Cuttack, Khordha and Puri runs are mostly highway).
  static int rideMinutes(NetworkRoute r, double meters) {
    final city = switch ((r.operator, r.mode)) {
      (NetworkOperator.mobus, _) => 350.0, // ~21 km/h
      (NetworkOperator.kiit, NetworkMode.bus) => 250.0,
      (NetworkOperator.kiit, NetworkMode.shuttle) => 200.0,
    };
    const cityPart = 12000.0;
    final minutes = meters <= cityPart ? meters / city : cityPart / city + (meters - cityPart) / 600; // 36 km/h
    return minutes.ceil().clamp(1, 1 << 20);
  }

  List<({NetworkStop stop, double meters})> walksFrom(String stopId) => _walks[stopId] ?? const [];

  /// Best trips from [from] to [to], fewest changes first.
  List<Journey> plan(NetworkStop from, NetworkStop to, {NetworkFilter filter = NetworkFilter.all, int maxChanges = 2}) {
    if (from.id == to.id) return const [];
    final found = <String, Journey>{};

    // Labels: best partial journey per stop after k rides.
    var frontier = <String, List<JourneyLeg>>{from.id: const []};
    for (final w in walksFrom(from.id)) {
      frontier[w.stop.id] = [_walk(from, w.stop, w.meters)];
    }

    for (var rides = 1; rides <= maxChanges + 1; rides++) {
      final next = <String, List<JourneyLeg>>{};
      for (final entry in frontier.entries) {
        final at = network.stop(entry.key)!;
        for (final route in network.routesAt(at.id)) {
          if (!filter.allows(route)) continue;
          if (entry.value.any((l) => l.route?.id == route.id)) continue; // no re-boarding the same route
          final i = route.stopIds.indexOf(at.id);
          for (final dir in const [1, -1]) {
            for (var j = i + dir; j >= 0 && j < route.stopIds.length; j += dir) {
              final leg = _ride(route, i, j);
              final legs = [...entry.value, leg];
              final reached = leg.to.id;
              if (reached == to.id) {
                _keep(found, Journey(legs));
              } else if (_walkTo(reached, to) case final w?) {
                _keep(found, Journey([...legs, _walk(leg.to, to, w)]));
              }
              if (rides <= maxChanges && _better(legs, next[reached])) next[reached] = legs;
            }
          }
        }
      }
      // Allow a short walk to a nearby stop before the next boarding.
      for (final e in next.entries.toList()) {
        for (final w in walksFrom(e.key)) {
          final legs = [...e.value, _walk(network.stop(e.key)!, w.stop, w.meters)];
          if (_better(legs, next[w.stop.id])) next[w.stop.id] = legs;
        }
      }
      frontier = next;
      if (found.values.any((j) => j.changes < rides - 1)) break; // nothing better with more changes
    }

    final list = found.values.toList()
      ..sort((a, b) {
        final c = a.changes.compareTo(b.changes);
        return c != 0 ? c : a.score.compareTo(b.score);
      });
    return _trim(list);
  }

  /// Trips that pass through [via].
  List<Journey> planVia(NetworkStop from, NetworkStop via, NetworkStop to, {NetworkFilter filter = NetworkFilter.all}) {
    final first = plan(from, via, filter: filter, maxChanges: 1).take(3).toList();
    final second = plan(via, to, filter: filter, maxChanges: 1).take(3).toList();
    final out = <String, Journey>{};
    for (final a in first) {
      for (final b in second) {
        final j = Journey([...a.legs, ...b.legs]);
        out.putIfAbsent(j.signature, () => j);
      }
    }
    final list = out.values.toList()
      ..sort((a, b) {
        final c = a.changes.compareTo(b.changes);
        return c != 0 ? c : a.score.compareTo(b.score);
      });
    return list.take(6).toList();
  }

  /// Direct options first; trips with changes only while they add something.
  List<Journey> _trim(List<Journey> list) {
    final direct = list.where((j) => j.isDirect).take(5).toList();
    final one = list.where((j) => j.changes == 1).take(direct.length >= 3 ? 1 : 4).toList();
    final two = direct.isEmpty && one.isEmpty ? list.where((j) => j.changes == 2).take(4).toList() : <Journey>[];
    return [...direct, ...one, ...two];
  }

  /// One trip per sequence of boarded routes: the quickest.
  void _keep(Map<String, Journey> found, Journey j) {
    final existing = found[j.signature];
    if (existing == null || j.score < existing.score) found[j.signature] = j;
  }

  bool _better(List<JourneyLeg> legs, List<JourneyLeg>? current) =>
      current == null || Journey(legs).score < Journey(current).score;

  double? _walkTo(String stopId, NetworkStop target) {
    for (final w in walksFrom(stopId)) {
      if (w.stop.id == target.id) return w.meters;
    }
    return null;
  }

  JourneyLeg _ride(NetworkRoute route, int i, int j) {
    final step = j > i ? 1 : -1;
    final stops = <NetworkStop>[for (var k = i; k != j + step; k += step) network.stop(route.stopIds[k])!];
    var straight = 0.0;
    for (var k = 0; k < stops.length - 1; k++) {
      straight += distanceMeters(stops[k].position, stops[k + 1].position);
    }
    // Prefer the distance along the traced road; fall back to straight lines
    // plus a typical road detour when the geometry can't be trusted.
    final along = _along[route.id];
    final road = along == null ? 0.0 : (along[j] - along[i]).abs();
    final meters = road >= straight * 0.9 ? road : straight * 1.3;
    return JourneyLeg.ride(route: route, from: stops.first, to: stops.last, stops: stops, minutes: rideMinutes(route, meters));
  }

  JourneyLeg _walk(NetworkStop a, NetworkStop b, double meters) =>
      JourneyLeg.walk(from: a, to: b, walkMeters: meters, minutes: (meters / walkMetersPerMinute).ceil());
}

/// The stretch of road a ride covers, cut from its route's geometry.
List<LatLng> legPath(JourneyLeg leg) {
  final route = leg.route;
  if (route == null || route.geometry.length < 2) return [for (final s in leg.stops) s.position];
  final a = nearestIndex(route.geometry, leg.from.position);
  final b = nearestIndex(route.geometry, leg.to.position);
  final part = a <= b ? route.geometry.sublist(a, b + 1) : route.geometry.sublist(b, a + 1).reversed.toList();
  return [leg.from.position, ...part, leg.to.position];
}
