enum ScheduleStatus {
  onTime,
  delayed,
  cancelled;

  String get label => switch (this) {
    ScheduleStatus.onTime => 'On time',
    ScheduleStatus.delayed => 'Delayed',
    ScheduleStatus.cancelled => 'Cancelled',
  };
}

class ScheduleModel {
  const ScheduleModel({
    required this.id,
    required this.routeId,
    required this.departureMinutes,
    required this.arrivalMinutes,
    this.delayMinutes = 0,
    this.isCancelled = false,
  });

  final String id;
  final String routeId;

  /// Times are stored as minutes since midnight (Postgres TIME on the wire).
  final int departureMinutes;
  final int arrivalMinutes;
  final int delayMinutes;
  final bool isCancelled;

  ScheduleStatus get status {
    if (isCancelled) return ScheduleStatus.cancelled;
    if (delayMinutes > 0) return ScheduleStatus.delayed;
    return ScheduleStatus.onTime;
  }

  int get expectedDepartureMinutes => departureMinutes + delayMinutes;

  int get durationMinutes => arrivalMinutes - departureMinutes;

  factory ScheduleModel.fromMap(Map<String, dynamic> map) => ScheduleModel(
    id: map['id'] as String,
    routeId: map['route_id'] as String,
    departureMinutes: parseTime(map['departure_time']),
    arrivalMinutes: parseTime(map['arrival_time']),
    delayMinutes: (map['delay_minutes'] as num?)?.toInt() ?? 0,
    isCancelled: (map['is_cancelled'] as bool?) ?? false,
  );

  /// Parses "HH:MM" or "HH:MM:SS".
  static int parseTime(Object? value) {
    final parts = value.toString().split(':');
    if (parts.length < 2) return 0;
    return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
  }

  static String toTime(int minutes) =>
      '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}:00';
}
