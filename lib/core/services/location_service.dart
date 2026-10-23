import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

enum LocationAccess { granted, denied, deniedForever, serviceDisabled }

/// Device GPS access: permission handling and position streams.
class LocationService {
  Future<LocationAccess> ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return LocationAccess.serviceDisabled;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return switch (permission) {
      LocationPermission.always || LocationPermission.whileInUse => LocationAccess.granted,
      LocationPermission.deniedForever => LocationAccess.deniedForever,
      _ => LocationAccess.denied,
    };
  }

  Future<Position?> currentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 12)),
      );
    } catch (_) {
      return Geolocator.getLastKnownPosition();
    }
  }

  /// Passive position stream for students (battery-friendly).
  Stream<Position> watchPassive() => Geolocator.getPositionStream(
    locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium, distanceFilter: 15),
  );

  /// High-accuracy stream for drivers. On Android this runs as a foreground
  /// service with a persistent notification so broadcasting survives the
  /// screen turning off.
  Stream<Position> watchForBroadcast({required String vehicleNumber}) {
    final LocationSettings settings;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      settings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        intervalDuration: const Duration(seconds: 3),
        foregroundNotificationConfig: ForegroundNotificationConfig(
          notificationTitle: 'KIIT Transit — on duty',
          notificationText: 'Sharing $vehicleNumber location with students',
          enableWakeLock: true,
          setOngoing: true,
        ),
      );
    } else if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      settings = AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.automotiveNavigation,
        allowBackgroundLocationUpdates: true,
        showBackgroundLocationIndicator: true,
        pauseLocationUpdatesAutomatically: false,
      );
    } else {
      settings = const LocationSettings(accuracy: LocationAccuracy.high);
    }
    return Geolocator.getPositionStream(locationSettings: settings);
  }

  Future<bool> openSettings() => Geolocator.openAppSettings();

  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();
}
