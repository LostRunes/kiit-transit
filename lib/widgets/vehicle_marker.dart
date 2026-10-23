import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' show LatLng;

import '../core/theme/app_colors.dart';
import '../core/utils/geo_utils.dart';
import '../data/models/vehicle_model.dart';

IconData vehicleIcon(VehicleType type) =>
    type == VehicleType.bus ? Icons.directions_bus_rounded : Icons.electric_rickshaw_rounded;

/// Bus/EV badge with a heading arrow orbiting its rim.
class VehicleMarkerIcon extends StatelessWidget {
  const VehicleMarkerIcon({
    super.key,
    required this.type,
    required this.heading,
    this.label,
    this.selected = false,
    this.dimmed = false,
  });

  final VehicleType type;
  final double heading;
  final String? label;
  final bool selected;
  final bool dimmed;

  static const size = 54.0;

  @override
  Widget build(BuildContext context) {
    final color = dimmed ? AppColors.offline : AppColors.forVehicle(type);
    final badge = selected ? 44.0 : 36.0;
    return SizedBox(
      width: size + 24,
      height: size + 22,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: selected ? size : badge + 10,
                  height: selected ? size : badge + 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: selected ? 0.28 : 0.2),
                  ),
                ),
                Transform.rotate(
                  angle: heading * math.pi / 180,
                  child: SizedBox(
                    width: badge + 16,
                    height: badge + 16,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: CustomPaint(size: const Size(12, 9), painter: _ArrowPainter(color)),
                    ),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: badge,
                  height: badge,
                  decoration: BoxDecoration(
                    color: selected ? color : (dimmed ? Colors.white : AppColors.softForVehicle(type)),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(color: AppColors.primary.withValues(alpha: 0.18), blurRadius: 12, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Icon(vehicleIcon(type), color: selected ? Colors.white : color, size: badge * 0.54),
                ),
              ],
            ),
          ),
          if (label != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Text(
                label!,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: selected ? Colors.white : AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  _ArrowPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width / 2, size.height * 0.7)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(_ArrowPainter old) => old.color != color;
}

/// Marker layer that glides vehicles to each new GPS fix instead of jumping.
class AnimatedVehicleLayer extends StatefulWidget {
  const AnimatedVehicleLayer({
    super.key,
    required this.vehicles,
    this.selectedId,
    this.onTap,
    this.showLabels = true,
    this.duration = const Duration(milliseconds: 2000),
  });

  final List<VehicleModel> vehicles;
  final String? selectedId;
  final ValueChanged<VehicleModel>? onTap;
  final bool showLabels;
  final Duration duration;

  @override
  State<AnimatedVehicleLayer> createState() => _AnimatedVehicleLayerState();
}

class _Track {
  _Track(this.from, this.to, this.fromHeading, this.toHeading, this.start);

  final LatLng from;
  final LatLng to;
  final double fromHeading;
  final double toHeading;
  final DateTime start;

  double progress(DateTime now, Duration d) => (now.difference(start).inMicroseconds / d.inMicroseconds).clamp(0.0, 1.0);

  ({LatLng pos, double heading}) at(DateTime now, Duration d) {
    final t = Curves.easeOutCubic.transform(progress(now, d));
    return (pos: lerpLatLng(from, to, t), heading: lerpHeading(fromHeading, toHeading, t));
  }
}

class _AnimatedVehicleLayerState extends State<AnimatedVehicleLayer> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _tracks = <String, _Track>{};

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) => _onTick());
    _sync();
  }

  @override
  void didUpdateWidget(covariant AnimatedVehicleLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final now = DateTime.now();
    final ids = <String>{};
    for (final v in widget.vehicles) {
      final target = v.position;
      if (target == null) continue;
      ids.add(v.id);
      final existing = _tracks[v.id];
      if (existing == null) {
        _tracks[v.id] = _Track(target, target, v.heading, v.heading, now);
      } else if (existing.to != target || existing.toHeading != v.heading) {
        final current = existing.at(now, widget.duration);
        _tracks[v.id] = _Track(current.pos, target, current.heading, v.heading, now);
      }
    }
    _tracks.removeWhere((id, _) => !ids.contains(id));
    if (_animating(now) && !_ticker.isActive) _ticker.start();
  }

  bool _animating(DateTime now) => _tracks.values.any((t) => t.progress(now, widget.duration) < 1);

  void _onTick() {
    if (!mounted) return;
    setState(() {});
    if (!_animating(DateTime.now())) _ticker.stop();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final vehicles = [...widget.vehicles]
      ..sort((a, b) => (a.id == widget.selectedId ? 1 : 0) - (b.id == widget.selectedId ? 1 : 0));
    return MarkerLayer(
      markers: [
        for (final v in vehicles)
          if (_tracks[v.id] != null)
            () {
              final s = _tracks[v.id]!.at(now, widget.duration);
              return Marker(
                key: ValueKey(v.id),
                point: s.pos,
                width: VehicleMarkerIcon.size + 24,
                height: VehicleMarkerIcon.size + 22,
                alignment: const Alignment(0, 0.25),
                child: GestureDetector(
                  onTap: widget.onTap == null ? null : () => widget.onTap!(v),
                  child: VehicleMarkerIcon(
                    type: v.type,
                    heading: s.heading,
                    label: widget.showLabels ? v.vehicleNumber : null,
                    selected: v.id == widget.selectedId,
                  ),
                ),
              );
            }(),
      ],
    );
  }
}
