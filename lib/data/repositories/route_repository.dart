import '../datasources/transit_source.dart';
import '../models/route_model.dart';
import '../models/schedule_model.dart';

class RouteRepository {
  RouteRepository(this._source);

  final TransitSource _source;
  List<RouteModel>? _routes;

  /// Routes rarely change, so they are cached for the session.
  Future<List<RouteModel>> fetchRoutes({bool refresh = false}) async {
    if (_routes != null && !refresh) return _routes!;
    return _routes = await _source.fetchRoutes();
  }

  Stream<List<ScheduleModel>> watchSchedules() => _source.watchSchedules();
}
