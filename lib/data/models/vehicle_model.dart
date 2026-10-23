import 'package:latlong2/latlong.dart';

import '../../core/constants/app_constants.dart';

enum VehicleType {
  ev,
  bus;

  static VehicleType parse(String? value) => value == 'bus' ? VehicleType.bus : VehicleType.ev;

  String get label => this == VehicleType.bus ? 'Bus' : 'EV Cart';
}

enum VehicleStatus {
  active,
  idle,
  offline;

  static VehicleStatus parse(String? value) =>
      VehicleStatus.values.firstWhere((s) => s.name == value, orElse: () => VehicleStatus.offline);

  String get label => switch (this) {
    VehicleStatus.active => 'On duty',
    VehicleStatus.idle => 'Idle',
    VehicleStatus.offline => 'Offline',
  };
}

class VehicleModel {
  const VehicleModel({
    required this.id,
    required this.vehicleNumber,
    required this.type,
    required this.status,
    this.driverId,
    this.routeId,
    this.latitude,
    this.longitude,
    this.heading = 0,
    this.lastUpdated,
    this.distanceMeters,
    this.etaMinutes,
  });

  final String id;
  final String vehicleNumber;
  final VehicleType type;
  final VehicleStatus status;
  final String? driverId;
  final String? routeId;
  final double? latitude;
  final double? longitude;
  final double heading;
  final DateTime? lastUpdated;

  /// Client-side values computed relative to the viewer's position.
  final double? distanceMeters;
  final int? etaMinutes;

  bool get hasPosition => latitude != null && longitude != null;
  LatLng? get position => hasPosition ? LatLng(latitude!, longitude!) : null;

  bool isStale([DateTime? now]) =>
      lastUpdated == null || (now ?? DateTime.now()).difference(lastUpdated!) > AppConstants.vehicleStaleAfter;

  /// Visible on the student map: on duty, reporting recently, with a fix.
  bool get isLive => status == VehicleStatus.active && hasPosition && !isStale();

  factory VehicleModel.fromMap(Map<String, dynamic> map) => VehicleModel(
    id: map['id'] as String,
    vehicleNumber: (map['vehicle_number'] as String?) ?? '—',
    type: VehicleType.parse(map['vehicle_type'] as String?),
    status: VehicleStatus.parse(map['status'] as String?),
    driverId: map['driver_id'] as String?,
    routeId: map['route_id'] as String?,
    latitude: (map['latitude'] as num?)?.toDouble(),
    longitude: (map['longitude'] as num?)?.toDouble(),
    heading: (map['heading'] as num?)?.toDouble() ?? 0,
    lastUpdated: DateTime.tryParse(map['last_updated']?.toString() ?? '')?.toLocal(),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'vehicle_number': vehicleNumber,
    'vehicle_type': type.name,
    'status': status.name,
    'driver_id': driverId,
    'route_id': routeId,
    'latitude': latitude,
    'longitude': longitude,
    'heading': heading,
    'last_updated': lastUpdated?.toUtc().toIso8601String(),
  };

  VehicleModel copyWith({
    VehicleStatus? status,
    String? driverId,
    bool clearDriver = false,
    double? latitude,
    double? longitude,
    double? heading,
    DateTime? lastUpdated,
    double? distanceMeters,
    int? etaMinutes,
  }) => VehicleModel(
    id: id,
    vehicleNumber: vehicleNumber,
    type: type,
    routeId: routeId,
    status: status ?? this.status,
    driverId: clearDriver ? null : (driverId ?? this.driverId),
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    heading: heading ?? this.heading,
    lastUpdated: lastUpdated ?? this.lastUpdated,
    distanceMeters: distanceMeters ?? this.distanceMeters,
    etaMinutes: etaMinutes ?? this.etaMinutes,
  );
}
