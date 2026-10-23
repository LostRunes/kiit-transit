import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../core/constants/campus_locations.dart';
import '../core/utils/geo_utils.dart';
import '../data/models/request_model.dart';
import '../data/repositories/request_repository.dart';

/// High-demand signals: students submit, drivers see aggregated counts.
class RequestViewModel extends ChangeNotifier {
  RequestViewModel(this._repo);

  final RequestRepository _repo;
  StreamSubscription<List<RequestModel>>? _sub;
  Timer? _clock;

  List<RequestModel> _requests = const [];
  Landmark? selectedLandmark;
  bool loading = true;
  bool submitting = false;
  String? error;
  String? lastSubmittedLocation;
  DateTime? lastSubmittedAt;

  void start() {
    if (_sub != null) return;
    _sub = _repo.watchRequests().listen(
      (list) {
        _requests = list;
        loading = false;
        notifyListeners();
      },
      onError: (Object e) {
        loading = false;
        error = 'Could not load demand signals.';
        notifyListeners();
      },
    );
    _clock = Timer.periodic(const Duration(seconds: 30), (_) => notifyListeners());
  }

  /// Active signals, busiest first.
  List<RequestModel> get requests =>
      _requests.where((r) => !r.isExpired()).toList()..sort((a, b) => b.studentCount.compareTo(a.studentCount));

  int get totalWaiting => requests.fold(0, (sum, r) => sum + r.studentCount);

  /// Active signals sorted by distance from [from] (driver view).
  List<({RequestModel request, double distance})> nearby(LatLng? from) {
    final list = requests.map((r) => (request: r, distance: from == null ? 0.0 : distanceMeters(from, r.position))).toList();
    if (from != null) list.sort((a, b) => a.distance.compareTo(b.distance));
    return list;
  }

  RequestModel? requestAt(String locationName) => requests.where((r) => r.locationName == locationName).firstOrNull;

  void selectLandmark(Landmark? landmark) {
    selectedLandmark = landmark;
    error = null;
    notifyListeners();
  }

  /// Pre-selects the landmark nearest to [position] if nothing is chosen.
  void suggestFrom(LatLng? position) {
    if (position == null || selectedLandmark != null) return;
    final idx = nearestIndex(CampusLocations.all.map((l) => l.position).toList(), position);
    if (distanceMeters(CampusLocations.all[idx].position, position) < 600) {
      selectedLandmark = CampusLocations.all[idx];
      notifyListeners();
    }
  }

  Future<bool> submit() async {
    final landmark = selectedLandmark;
    if (landmark == null) {
      error = 'Choose where you are waiting.';
      notifyListeners();
      return false;
    }
    submitting = true;
    error = null;
    notifyListeners();
    try {
      await _repo.submit(
        locationName: landmark.name,
        latitude: landmark.position.latitude,
        longitude: landmark.position.longitude,
      );
      lastSubmittedLocation = landmark.name;
      lastSubmittedAt = DateTime.now();
      return true;
    } on StateError catch (e) {
      error = e.message;
    } catch (e) {
      error = 'Could not send your request. Try again.';
      debugPrint('Request submit failed: $e');
    } finally {
      submitting = false;
      notifyListeners();
    }
    return false;
  }

  Future<void> resolve(RequestModel r) async {
    try {
      await _repo.resolve(r.id);
    } catch (e) {
      error = 'Could not update the request.';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _clock?.cancel();
    super.dispose();
  }
}
