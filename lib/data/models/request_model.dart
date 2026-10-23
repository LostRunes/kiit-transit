import 'package:latlong2/latlong.dart';

import '../../core/constants/app_constants.dart';

/// An aggregated "students waiting here" demand signal. Not a booking.
class RequestModel {
  const RequestModel({
    required this.id,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.studentCount,
    required this.createdAt,
    this.lastRequestedAt,
  });

  final String id;
  final String locationName;
  final double latitude;
  final double longitude;
  final int studentCount;
  final DateTime createdAt;
  final DateTime? lastRequestedAt;

  LatLng get position => LatLng(latitude, longitude);

  DateTime get latestActivity => lastRequestedAt ?? createdAt;

  bool isExpired([DateTime? now]) => (now ?? DateTime.now()).difference(latestActivity) > AppConstants.requestWindow;

  /// Rough urgency bucket used for colour coding.
  int get level => studentCount >= 10 ? 3 : (studentCount >= 5 ? 2 : 1);

  factory RequestModel.fromMap(Map<String, dynamic> map) => RequestModel(
    id: map['id'] as String,
    locationName: (map['location_name'] as String?) ?? 'Unknown',
    latitude: (map['latitude'] as num).toDouble(),
    longitude: (map['longitude'] as num).toDouble(),
    studentCount: (map['student_count'] as num?)?.toInt() ?? 1,
    createdAt: DateTime.parse(map['created_at'].toString()).toLocal(),
    lastRequestedAt: DateTime.tryParse(map['last_requested_at']?.toString() ?? '')?.toLocal(),
  );

  RequestModel copyWith({int? studentCount, DateTime? lastRequestedAt}) => RequestModel(
    id: id,
    locationName: locationName,
    latitude: latitude,
    longitude: longitude,
    createdAt: createdAt,
    studentCount: studentCount ?? this.studentCount,
    lastRequestedAt: lastRequestedAt ?? this.lastRequestedAt,
  );
}
