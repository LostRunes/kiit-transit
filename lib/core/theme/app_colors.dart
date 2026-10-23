import 'package:flutter/material.dart';

import '../../data/models/vehicle_model.dart';

/// "Campus Pulse" palette from the Stitch design (sage, muted teal, peach).
class AppColors {
  AppColors._();

  // Brand
  static const primary = Color(0xFF2D6957); // deep sage: buttons, active states
  static const primaryDark = Color(0xFF0E5040);
  static const primaryLight = Color(0xFF96D3BD);
  static const sage = Color(0xFF7CB8A3); // primary container
  static const sageSoft = Color(0xFFDDEFE7);
  static const onSage = Color(0xFF024939);
  static const secondary = Color(0xFF2A6863); // muted teal
  static const teal = Color(0xFFB0EEE8); // secondary container
  static const onTeal = Color(0xFF316E69);
  static const tertiary = Color(0xFF82533E); // warm brown
  static const peach = Color(0xFFF6B89E);
  static const peachSoft = Color(0xFFFFE6DA);

  // Vehicle types
  static const bus = Color(0xFFE9B949); // warm yellow bus
  static const busSoft = Color(0xFFFFF3D6);
  static const ev = Color(0xFF5FA58C);

  // Status
  static const onTime = Color(0xFF3F9A6B);
  static const delayed = Color(0xFFD08A2E);
  static const cancelled = Color(0xFFD64545);
  static const offline = Color(0xFF9AA5A0);
  static const live = Color(0xFFE0745C);
  static const success = Color(0xFF7BC47F); // driver "Start"
  static const danger = Color(0xFFDC2F2F); // driver "End duty"

  // Neutrals (light)
  static const ink = Color(0xFF191C1B);
  static const inkMuted = Color(0xFF5B6560);
  static const surface = Color(0xFFF8FAF7);
  static const card = Color(0xFFFFFFFF);
  static const field = Color(0xFFF2F4F1);
  static const border = Color(0xFFE1E6E2);

  // Neutrals (dark)
  static const darkSurface = Color(0xFF101413);
  static const darkCard = Color(0xFF1A201E);
  static const darkField = Color(0xFF222A27);
  static const darkBorder = Color(0xFF2B3532);

  static Color forVehicle(VehicleType type) => type == VehicleType.bus ? bus : ev;

  /// Pale background behind a vehicle icon ("soft-background" icon style).
  static Color softForVehicle(VehicleType type) => type == VehicleType.bus ? busSoft : sageSoft;

  static Color muted(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? const Color(0xFF9DABA5) : inkMuted;

  static Color borderOf(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? darkBorder : border;

  static Color fieldOf(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? darkField : field;

  /// Soft ambient shadow tinted with the primary colour, per the design system.
  static List<BoxShadow> podShadow({bool raised = false}) => [
    BoxShadow(
      color: primary.withValues(alpha: raised ? 0.10 : 0.06),
      blurRadius: raised ? 30 : 20,
      offset: Offset(0, raised ? 12 : 8),
    ),
  ];

  static Color parseHex(String? hex, {Color fallback = primary}) {
    if (hex == null || hex.isEmpty) return fallback;
    final cleaned = hex.replaceFirst('#', '');
    final value = int.tryParse(cleaned.length == 6 ? 'FF$cleaned' : cleaned, radix: 16);
    return value == null ? fallback : Color(value);
  }
}
