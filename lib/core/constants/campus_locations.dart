import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

enum LandmarkType {
  academic(Icons.school_rounded),
  hostel(Icons.bed_rounded),
  food(Icons.restaurant_rounded),
  library(Icons.local_library_rounded),
  gate(Icons.door_sliding_rounded),
  facility(Icons.sports_cricket_rounded);

  const LandmarkType(this.icon);
  final IconData icon;
}

class Landmark {
  const Landmark(this.id, this.name, this.type, this.position);

  final String id;
  final String name;
  final LandmarkType type;
  final LatLng position;
}

/// Campus geography. Coordinates marked "approx" were placed by hand and
/// should be verified on site; the rest come from MapTiler/OSM POIs.
class CampusLocations {
  CampusLocations._();

  static const center = LatLng(20.3545, 85.8185);
  static const initialZoom = 15.6;
  static const minZoom = 13.5;
  static const maxZoom = 19.0;

  /// Bounds the camera cannot leave (campus plus a margin).
  static const southWest = LatLng(20.3380, 85.8020);
  static const northEast = LatLng(20.3720, 85.8380);

  static const campus3 = Landmark('campus3', 'Campus 3', LandmarkType.academic, LatLng(20.35324, 85.81712));
  static const campus6 = Landmark('campus6', 'Campus 6 (Main)', LandmarkType.academic, LatLng(20.35307, 85.82015));
  static const campus14 = Landmark('campus14', 'Campus 14', LandmarkType.academic, LatLng(20.35590, 85.81560)); // approx
  static const campus15 = Landmark('campus15', 'Campus 15', LandmarkType.academic, LatLng(20.34821, 85.81595));
  static const campus17 = Landmark('campus17', 'Campus 17', LandmarkType.academic, LatLng(20.34960, 85.81950)); // approx
  static const campus25 = Landmark('campus25', 'Campus 25', LandmarkType.academic, LatLng(20.36450, 85.81700)); // approx
  static const library = Landmark('library', 'Central Library', LandmarkType.library, LatLng(20.35428, 85.81618));
  static const foodCourt = Landmark('foodcourt', 'Food Court', LandmarkType.food, LatLng(20.35480, 85.81880)); // approx
  static const cricketGround = Landmark('ground', 'Cricket Ground', LandmarkType.facility, LatLng(20.35735, 85.81782));
  static const kp5 = Landmark('kp5', 'KP-5', LandmarkType.hostel, LatLng(20.35638, 85.81994));
  static const kp6 = Landmark('kp6', 'KP-6', LandmarkType.hostel, LatLng(20.34891, 85.81609));
  static const kp7 = Landmark('kp7', 'KP-7', LandmarkType.hostel, LatLng(20.35113, 85.81706));
  static const kp8 = Landmark('kp8', 'KP-8', LandmarkType.hostel, LatLng(20.35959, 85.82411));
  static const kp15 = Landmark('kp15', 'KP-15', LandmarkType.hostel, LatLng(20.35613, 85.82061));
  static const queensHostel = Landmark('qc', 'Queens Hostels', LandmarkType.hostel, LatLng(20.36100, 85.81900)); // approx
  static const mainGate = Landmark('gate', 'KIIT Square Gate', LandmarkType.gate, LatLng(20.35393, 85.81560));
  static const patiaPickup = Landmark('patia', 'Patia Day Scholar Pickup', LandmarkType.gate, LatLng(20.35491, 85.82933));

  static const all = <Landmark>[
    campus3,
    campus6,
    campus14,
    campus15,
    campus17,
    campus25,
    library,
    foodCourt,
    cricketGround,
    kp5,
    kp6,
    kp7,
    kp8,
    kp15,
    queensHostel,
    mainGate,
    patiaPickup,
  ];

  /// Closest landmark to [p], used for "near Campus 14" style labels.
  static Landmark nearest(LatLng p) {
    const d = Distance();
    return all.reduce((a, b) => d.as(LengthUnit.Meter, a.position, p) <= d.as(LengthUnit.Meter, b.position, p) ? a : b);
  }

  static Landmark? byName(String name) {
    for (final l in all) {
      if (l.name == name) return l;
    }
    return null;
  }
}
