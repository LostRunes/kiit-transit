import 'package:latlong2/latlong.dart';

import '../../core/services/location_service.dart';
import '../../core/utils/geo_utils.dart';

/// A single GPS reading, with a heading that is always usable.
class GpsFix {
  const GpsFix({required this.position, required this.heading, required this.accuracy, this.speed = 0});

  final LatLng position;
  final double heading;
  final double accuracy;

  /// Metres per second.
  final double speed;
}

/// Raw device GPS stream turned into [GpsFix]es.
///
/// Many devices report heading 0 when stationary or without a compass, so
/// when the reported value is unusable we derive it from movement instead.
class LocationSource {
  LocationSource(this._service);

  final LocationService _service;

  LocationService get service => _service;

  Stream<GpsFix> broadcastFixes({required String vehicleNumber}) {
    LatLng? previous;
    var lastHeading = 0.0;
    return _service.watchForBroadcast(vehicleNumber: vehicleNumber).map((p) {
      final current = LatLng(p.latitude, p.longitude);
      if (p.heading > 0 && p.speed > 0.8) {
        lastHeading = p.heading;
      } else if (previous != null && distanceMeters(previous!, current) > 4) {
        lastHeading = bearingDegrees(previous!, current);
      }
      previous = current;
      return GpsFix(position: current, heading: lastHeading, accuracy: p.accuracy, speed: p.speed);
    });
  }

  Stream<LatLng> passivePositions() => _service.watchPassive().map((p) => LatLng(p.latitude, p.longitude));

  Future<LatLng?> currentPosition() async {
    final p = await _service.currentPosition();
    return p == null ? null : LatLng(p.latitude, p.longitude);
  }
}
