import 'package:latlong2/latlong.dart';

import 'vehicle_model.dart';

class RouteStop {
  const RouteStop({required this.name, required this.latitude, required this.longitude});

  final String name;
  final double latitude;
  final double longitude;

  LatLng get position => LatLng(latitude, longitude);

  factory RouteStop.fromMap(Map<String, dynamic> map) =>
      RouteStop(name: map['name'] as String, latitude: (map['lat'] as num).toDouble(), longitude: (map['lng'] as num).toDouble());

  Map<String, dynamic> toMap() => {'name': name, 'lat': latitude, 'lng': longitude};
}

class RouteModel {
  const RouteModel({
    required this.id,
    required this.name,
    required this.type,
    required this.stops,
    this.color,
    this.isLoop = false,
  });

  final String id;
  final String name;
  final VehicleType type;
  final List<RouteStop> stops;
  final String? color;

  /// Loop routes return to the first stop after the last.
  final bool isLoop;

  List<LatLng> get path {
    final points = stops.map((s) => s.position).toList();
    if (isLoop && points.length > 1) points.add(points.first);
    return points;
  }

  String get shortName => name.split('--').first.trim();

  String get summary => stops.isEmpty ? '' : '${stops.first.name} → ${stops.last.name}';

  factory RouteModel.fromMap(Map<String, dynamic> map) => RouteModel(
    id: map['id'] as String,
    name: (map['route_name'] as String?) ?? 'Route',
    type: VehicleType.parse(map['route_type'] as String?),
    color: map['color'] as String?,
    isLoop: (map['is_loop'] as bool?) ?? false,
    stops: ((map['stops'] as List?) ?? const []).map((s) => RouteStop.fromMap(Map<String, dynamic>.from(s as Map))).toList(),
  );
}
