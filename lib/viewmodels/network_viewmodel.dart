import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../core/services/journey_planner.dart';
import '../core/utils/geo_utils.dart';
import '../data/models/network_model.dart';
import '../data/repositories/network_repository.dart';

/// City-wide network browsing and the trip planner.
class NetworkViewModel extends ChangeNotifier {
  NetworkViewModel(this._repo);

  final NetworkRepository _repo;

  TransitNetwork? network;
  JourneyPlanner? _planner;
  bool loading = false;
  String? error;

  NetworkStop? from;
  NetworkStop? to;
  NetworkStop? via;
  NetworkFilter filter = NetworkFilter.all;
  List<Journey>? results;

  Future<void> load() async {
    if (network != null || loading) return;
    loading = true;
    notifyListeners();
    try {
      network = await _repo.load();
      _planner = JourneyPlanner(network!);
      error = null;
    } catch (e) {
      error = 'Could not load the route network.';
      debugPrint('Network load failed: $e');
    }
    loading = false;
    notifyListeners();
  }

  List<NetworkRoute> routesFor(NetworkFilter f) => network?.routes.where(f.allows).toList() ?? const [];

  NetworkRoute? routeById(String id) => network?.routes.where((r) => r.id == id).firstOrNull;

  List<NetworkStop> stopsOf(NetworkRoute r) => [for (final id in r.stopIds) network!.stop(id)!];

  NetworkStop? nearestStop(LatLng p) {
    final stops = network?.servedStops;
    if (stops == null || stops.isEmpty) return null;
    return stops.reduce((a, b) => distanceMeters(a.position, p) <= distanceMeters(b.position, p) ? a : b);
  }

  void setFrom(NetworkStop? s) => _update(() => from = s);
  void setTo(NetworkStop? s) => _update(() => to = s);
  void setVia(NetworkStop? s) => _update(() => via = s);
  void setFilter(NetworkFilter f) => _update(() => filter = f);

  void swap() => _update(() {
    final t = from;
    from = to;
    to = t;
  });

  void clear() => _update(() {
    from = to = via = null;
    results = null;
  });

  void _update(VoidCallback change) {
    change();
    _search();
    notifyListeners();
  }

  void _search() {
    final p = _planner;
    if (p == null || from == null || to == null || from == to) {
      results = null;
      return;
    }
    results = via == null || via == from || via == to
        ? p.plan(from!, to!, filter: filter)
        : p.planVia(from!, via!, to!, filter: filter);
  }
}
