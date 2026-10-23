import 'package:latlong2/latlong.dart';

/// Who runs a route in the city-wide network.
enum NetworkOperator {
  kiit('KIIT'),
  mobus('Mo Bus');

  const NetworkOperator(this.label);
  final String label;

  static NetworkOperator parse(String? v) => v == 'mobus' ? mobus : kiit;
}

enum NetworkMode {
  bus('Bus'),
  shuttle('Shuttle');

  const NetworkMode(this.label);
  final String label;

  static NetworkMode parse(String? v) => v == 'shuttle' ? shuttle : bus;
}

/// Which part of the network a search or list should cover.
enum NetworkFilter {
  all('All'),
  kiitBus('KIIT bus'),
  kiitShuttle('KIIT shuttle'),
  mobus('Mo Bus');

  const NetworkFilter(this.label);
  final String label;

  bool allows(NetworkRoute r) => switch (this) {
    NetworkFilter.all => true,
    NetworkFilter.kiitBus => r.operator == NetworkOperator.kiit && r.mode == NetworkMode.bus,
    NetworkFilter.kiitShuttle => r.operator == NetworkOperator.kiit && r.mode == NetworkMode.shuttle,
    NetworkFilter.mobus => r.operator == NetworkOperator.mobus,
  };
}

class NetworkStop {
  const NetworkStop({
    required this.id,
    required this.name,
    required this.position,
    this.isCampus = false,
    this.approximate = false,
  });

  final String id;
  final String name;
  final LatLng position;
  final bool isCampus;

  /// Position was estimated rather than taken from a map source.
  final bool approximate;

  factory NetworkStop.fromJson(Map<String, dynamic> j) => NetworkStop(
    id: j['id'] as String,
    name: j['name'] as String,
    position: LatLng((j['lat'] as num).toDouble(), (j['lng'] as num).toDouble()),
    isCampus: j['kind'] == 'campus',
    approximate: (j['approx'] as bool?) ?? false,
  );

  @override
  bool operator ==(Object other) => other is NetworkStop && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// A two-way route: vehicles run in both directions along [stopIds].
class NetworkRoute {
  const NetworkRoute({
    required this.id,
    required this.ref,
    required this.name,
    required this.operator,
    required this.mode,
    required this.color,
    required this.stopIds,
    required this.geometry,
    this.originId,
  });

  final String id;

  /// Short code shown on badges: "10", "29E", "B-12", "S-4".
  final String ref;
  final String name;
  final NetworkOperator operator;
  final NetworkMode mode;
  final String color;
  final List<String> stopIds;

  /// Road-snapped polyline through every stop.
  final List<LatLng> geometry;

  /// KIIT only: campus where the vehicles are based and fill up.
  final String? originId;

  bool get isKiit => operator == NetworkOperator.kiit;

  String get label => isKiit ? '${mode.label} $ref' : 'Route $ref';

  factory NetworkRoute.fromJson(Map<String, dynamic> j) => NetworkRoute(
    id: j['id'] as String,
    ref: j['ref'] as String,
    name: j['name'] as String,
    operator: NetworkOperator.parse(j['operator'] as String?),
    mode: NetworkMode.parse(j['mode'] as String?),
    color: j['color'] as String,
    stopIds: (j['stops'] as List).cast<String>(),
    geometry: [for (final p in j['geometry'] as List) LatLng(((p as List)[0] as num).toDouble(), (p[1] as num).toDouble())],
    originId: j['origin'] as String?,
  );
}

/// The whole network plus lookups used by the planner.
class TransitNetwork {
  TransitNetwork({required List<NetworkStop> stops, required this.routes, this.sources = const {}})
    : stops = {for (final s in stops) s.id: s} {
    for (final r in routes) {
      for (final id in r.stopIds) {
        (_routesAt[id] ??= []).add(r);
      }
    }
  }

  final Map<String, NetworkStop> stops;
  final List<NetworkRoute> routes;
  final Map<String, String> sources;
  final Map<String, List<NetworkRoute>> _routesAt = {};

  NetworkStop? stop(String id) => stops[id];

  List<NetworkRoute> routesAt(String stopId) => _routesAt[stopId] ?? const [];

  /// Stops served by at least one route, campuses first, then A–Z.
  List<NetworkStop> get servedStops {
    final list = stops.values.where((s) => _routesAt.containsKey(s.id)).toList()
      ..sort((a, b) {
        if (a.isCampus != b.isCampus) return a.isCampus ? -1 : 1;
        if (a.isCampus) return _campusNo(a.id).compareTo(_campusNo(b.id));
        return a.name.compareTo(b.name);
      });
    return list;
  }

  static int _campusNo(String id) => int.tryParse(id.replaceAll(RegExp(r'\D'), '')) ?? 0;

  factory TransitNetwork.fromJson(Map<String, dynamic> j) {
    final meta = (j['meta'] as Map?)?.cast<String, dynamic>() ?? const {};
    return TransitNetwork(
      stops: [for (final s in j['stops'] as List) NetworkStop.fromJson((s as Map).cast<String, dynamic>())],
      routes: [for (final r in j['routes'] as List) NetworkRoute.fromJson((r as Map).cast<String, dynamic>())],
      sources: ((meta['sources'] as Map?) ?? const {}).cast<String, String>(),
    );
  }
}
