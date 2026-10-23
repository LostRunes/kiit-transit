import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import '../constants/app_constants.dart';

const _distance = Distance();

/// Great-circle distance in metres.
double distanceMeters(LatLng a, LatLng b) => _distance.as(LengthUnit.Meter, a, b);

/// Initial bearing from [a] to [b] in degrees (0-360, 0 = north).
double bearingDegrees(LatLng a, LatLng b) => (_distance.bearing(a, b) + 360) % 360;

/// V1 ETA formula from the spec: distance / average campus speed, rounded up.
int etaMinutes(double meters, {double speed = AppConstants.campusSpeedMetersPerMinute}) => math.max(0, (meters / speed).ceil());

/// Linear interpolation between two points; accurate enough at campus scale.
LatLng lerpLatLng(LatLng a, LatLng b, double t) =>
    LatLng(a.latitude + (b.latitude - a.latitude) * t, a.longitude + (b.longitude - a.longitude) * t);

/// Interpolates between two headings along the shortest arc.
double lerpHeading(double a, double b, double t) {
  final delta = ((b - a + 540) % 360) - 180;
  return (a + delta * t + 360) % 360;
}

double pathLength(List<LatLng> path) {
  var total = 0.0;
  for (var i = 0; i < path.length - 1; i++) {
    total += distanceMeters(path[i], path[i + 1]);
  }
  return total;
}

/// Point [meters] along [path], plus the heading of the segment it lies on.
({LatLng point, double heading}) pointAlong(List<LatLng> path, double meters) {
  if (path.length < 2) return (point: path.first, heading: 0);
  var remaining = meters;
  for (var i = 0; i < path.length - 1; i++) {
    final seg = distanceMeters(path[i], path[i + 1]);
    if (remaining <= seg || i == path.length - 2) {
      final t = seg == 0 ? 0.0 : math.min(1.0, remaining / seg);
      return (point: lerpLatLng(path[i], path[i + 1], t), heading: bearingDegrees(path[i], path[i + 1]));
    }
    remaining -= seg;
  }
  return (point: path.last, heading: 0);
}

/// Index of the point in [points] nearest to [p].
int nearestIndex(List<LatLng> points, LatLng p) {
  var best = 0;
  var bestD = double.infinity;
  for (var i = 0; i < points.length; i++) {
    final d = distanceMeters(points[i], p);
    if (d < bestD) {
      bestD = d;
      best = i;
    }
  }
  return best;
}
