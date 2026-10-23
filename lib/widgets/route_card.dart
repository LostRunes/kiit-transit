import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../data/models/route_model.dart';
import 'common.dart';
import 'vehicle_marker.dart';

/// Route list item with a compact stop preview.
class RouteCard extends StatelessWidget {
  const RouteCard({super.key, required this.route, this.liveCount = 0, this.onTap});

  final RouteModel route;
  final int liveCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.parseHex(route.color);
    return Pod(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          SoftIcon(icon: vehicleIcon(route.type), color: color, circle: false),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(route.shortName, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  route.name.contains('--') ? route.name.split('--').last.trim() : route.summary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.muted(context), fontSize: 12.5),
                ),
                const SizedBox(height: 8),
                StopStrip(stops: route.stops, color: color),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              Text(
                '$liveCount',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: liveCount > 0 ? color : AppColors.offline),
              ),
              Text('live', style: TextStyle(fontSize: 11, color: AppColors.muted(context))),
            ],
          ),
        ],
      ),
    );
  }
}

/// Dots-and-line preview of a route: first stop · N stops · last stop.
class StopStrip extends StatelessWidget {
  const StopStrip({super.key, required this.stops, required this.color});

  final List<RouteStop> stops;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (stops.isEmpty) return const SizedBox.shrink();
    final style = TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.muted(context));
    return Row(
      children: [
        _dot(),
        const SizedBox(width: 4),
        Flexible(
          child: Text(stops.first.name, style: style, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: [
                Expanded(child: Container(height: 2, color: color.withValues(alpha: 0.35))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text('${stops.length} stops', style: style.copyWith(fontSize: 10)),
                ),
                Expanded(child: Container(height: 2, color: color.withValues(alpha: 0.35))),
              ],
            ),
          ),
        ),
        Flexible(
          child: Text(stops.last.name, style: style, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(width: 4),
        _dot(),
      ],
    );
  }

  Widget _dot() => Container(
    width: 8,
    height: 8,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: color, width: 2),
    ),
  );
}

/// Vertical timeline of stops, e.g. for a vehicle's upcoming stops.
class StopTimeline extends StatelessWidget {
  const StopTimeline({super.key, required this.stops, required this.color, this.trailing});

  final List<RouteStop> stops;
  final Color color;

  /// Optional right-hand text per stop (e.g. an ETA).
  final String? Function(RouteStop stop, int index)? trailing;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var i = 0; i < stops.length; i++)
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 22,
                child: Column(
                  children: [
                    Expanded(child: Container(width: 3, color: i == 0 ? Colors.transparent : color.withValues(alpha: 0.35))),
                    Container(
                      width: i == 0 ? 14 : 11,
                      height: i == 0 ? 14 : 11,
                      decoration: BoxDecoration(
                        color: i == 0 ? color : Theme.of(context).colorScheme.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: color, width: 3),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        width: 3,
                        color: i == stops.length - 1 ? Colors.transparent : color.withValues(alpha: 0.35),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: Text(
                    stops[i].name,
                    style: TextStyle(fontWeight: i == 0 ? FontWeight.w800 : FontWeight.w600, fontSize: 14),
                  ),
                ),
              ),
              if (trailing?.call(stops[i], i) case final t?)
                Center(
                  child: Text(
                    t,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                      color: i == 0 ? color : AppColors.muted(context),
                    ),
                  ),
                ),
            ],
          ),
        ),
    ],
  );
}
