import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../constants/app_constants.dart';
import '../constants/campus_locations.dart';

/// Map configuration shared by every map in the app.
class MapService {
  MapService._();

  static bool get _hasMapTiler => AppConstants.mapTilerKey.isNotEmpty;

  /// MapTiler raster tiles (512px, served at z-1) with an OSM fallback.
  static TileLayer tileLayer(Brightness brightness) {
    if (!_hasMapTiler) {
      return TileLayer(
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        userAgentPackageName: AppConstants.userAgentPackageName,
        maxNativeZoom: 19,
      );
    }
    final style = brightness == Brightness.dark ? 'streets-v2-dark' : 'streets-v2';
    return TileLayer(
      urlTemplate: 'https://api.maptiler.com/maps/$style/{z}/{x}/{y}.png?key={key}',
      additionalOptions: const {'key': AppConstants.mapTilerKey},
      tileDimension: 512,
      zoomOffset: -1,
      maxNativeZoom: 20,
      userAgentPackageName: AppConstants.userAgentPackageName,
    );
  }

  static Widget attribution() => Align(
    alignment: Alignment.bottomRight,
    child: ColoredBox(
      color: Colors.white70,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        child: Text(
          _hasMapTiler ? '© MapTiler © OpenStreetMap contributors' : '© OpenStreetMap contributors',
          style: const TextStyle(fontSize: 10, color: Colors.black87),
        ),
      ),
    ),
  );

  static MapOptions options({
    LatLng? center,
    double? zoom,
    void Function(TapPosition, LatLng)? onTap,
    VoidCallback? onReady,
    void Function(MapCamera, bool)? onPositionChanged,
  }) => MapOptions(
    initialCenter: center ?? CampusLocations.center,
    initialZoom: zoom ?? CampusLocations.initialZoom,
    minZoom: CampusLocations.minZoom,
    maxZoom: CampusLocations.maxZoom,
    cameraConstraint: CameraConstraint.containCenter(bounds: LatLngBounds(CampusLocations.southWest, CampusLocations.northEast)),
    interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
    onTap: onTap,
    onMapReady: onReady,
    onPositionChanged: onPositionChanged,
  );

  /// Camera that frames [points] with padding.
  static CameraFit fit(List<LatLng> points, {EdgeInsets padding = const EdgeInsets.all(48)}) =>
      CameraFit.coordinates(coordinates: points, padding: padding, maxZoom: 17.5);
}
