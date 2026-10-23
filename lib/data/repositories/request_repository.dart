import '../datasources/transit_source.dart';
import '../models/request_model.dart';

class RequestRepository {
  RequestRepository(this._source);

  final TransitSource _source;

  Stream<List<RequestModel>> watchRequests() => _source.watchRequests();

  Future<void> submit({required String locationName, required double latitude, required double longitude}) =>
      _source.submitRequest(locationName: locationName, latitude: latitude, longitude: longitude);

  Future<void> resolve(String requestId) => _source.resolveRequest(requestId);
}
