import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/models/route_model.dart';
import '../data/models/schedule_model.dart';
import '../data/models/vehicle_model.dart';
import '../data/repositories/route_repository.dart';

/// Routes and digitized bus timetables.
class RouteViewModel extends ChangeNotifier {
  RouteViewModel(this._repo);

  final RouteRepository _repo;
  StreamSubscription<List<ScheduleModel>>? _sub;
  Timer? _clock;

  List<RouteModel> routes = const [];
  List<ScheduleModel> _schedules = const [];
  String? selectedRouteId;
  bool loading = true;
  String? error;

  /// Current time as minutes since midnight (injectable for tests).
  int Function() nowMinutes = () {
    final n = DateTime.now();
    return n.hour * 60 + n.minute;
  };

  Future<void> start() async {
    if (_sub != null) return;
    _sub = _repo.watchSchedules().listen(
      (list) {
        _schedules = list;
        loading = false;
        notifyListeners();
      },
      onError: (Object e) {
        error = 'Could not load schedules.';
        loading = false;
        notifyListeners();
      },
    );
    _clock = Timer.periodic(const Duration(seconds: 30), (_) => notifyListeners());
    await load();
  }

  Future<void> load({bool refresh = false}) async {
    try {
      routes = await _repo.fetchRoutes(refresh: refresh);
      error = null;
    } catch (e) {
      error = 'Could not load routes.';
    }
    notifyListeners();
  }

  /// Only buses run to a timetable; EVs circulate on demand.
  List<RouteModel> get busRoutes => routes.where((r) => r.type == VehicleType.bus).toList();

  List<RouteModel> get visibleRoutes =>
      selectedRouteId == null ? busRoutes : busRoutes.where((r) => r.id == selectedRouteId).toList();

  void selectRoute(String? id) {
    selectedRouteId = id;
    notifyListeners();
  }

  RouteModel? routeById(String id) => routes.where((r) => r.id == id).firstOrNull;

  List<ScheduleModel> schedulesFor(String routeId) =>
      _schedules.where((s) => s.routeId == routeId).toList()..sort((a, b) => a.departureMinutes.compareTo(b.departureMinutes));

  /// Departures that have not left yet (delays included), soonest first.
  List<ScheduleModel> upcoming(String routeId, {int count = 5}) {
    final now = nowMinutes();
    return schedulesFor(routeId)
        .where((s) => s.status == ScheduleStatus.cancelled ? s.departureMinutes >= now : s.expectedDepartureMinutes >= now)
        .take(count)
        .toList();
  }

  ScheduleModel? nextDeparture(String routeId) =>
      upcoming(routeId, count: 10).where((s) => s.status != ScheduleStatus.cancelled).firstOrNull;

  int minutesUntil(ScheduleModel s) => s.expectedDepartureMinutes - nowMinutes();

  bool get hasServiceToday => busRoutes.any((r) => nextDeparture(r.id) != null);

  @override
  void dispose() {
    _sub?.cancel();
    _clock?.cancel();
    super.dispose();
  }
}
