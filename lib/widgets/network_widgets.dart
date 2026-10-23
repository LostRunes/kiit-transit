import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/geo_utils.dart';
import '../data/models/network_model.dart';
import '../data/models/vehicle_model.dart';
import '../viewmodels/map_viewmodel.dart';
import 'common.dart';

/// Coloured route code, e.g. "12" or "B-4".
class RouteBadge extends StatelessWidget {
  const RouteBadge({super.key, required this.route, this.large = false});

  final NetworkRoute route;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.parseHex(route.color);
    final onColor = color.computeLuminance() > 0.55 ? AppColors.ink : Colors.white;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: large ? 12 : 8, vertical: large ? 6 : 3),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(large ? 12 : 8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(networkIcon(route), size: large ? 16 : 13, color: onColor),
          const SizedBox(width: 4),
          Text(
            route.ref,
            style: TextStyle(color: onColor, fontWeight: FontWeight.w800, fontSize: large ? 15 : 12),
          ),
        ],
      ),
    );
  }
}

IconData networkIcon(NetworkRoute r) => switch ((r.operator, r.mode)) {
  (NetworkOperator.mobus, _) => Icons.directions_bus_filled_rounded,
  (NetworkOperator.kiit, NetworkMode.bus) => Icons.directions_bus_rounded,
  (NetworkOperator.kiit, NetworkMode.shuttle) => Icons.electric_rickshaw_rounded,
};

/// What a student can expect when boarding [route] at [stop]. KIIT data
/// comes from field research (vehicles leave when full); Mo Bus timetables
/// are not part of the network map, so only the service pattern is shown.
class Availability extends StatelessWidget {
  const Availability({super.key, required this.route, required this.stop, this.compact = false});

  final NetworkRoute route;
  final NetworkStop stop;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final muted = AppColors.muted(context);
    if (!route.isKiit) {
      return _line(Icons.info_outline_rounded, 'Mo Bus · runs both ways · timings not in the network map', muted);
    }
    final map = context.watch<MapViewModel>();
    final type = route.mode == NetworkMode.shuttle ? VehicleType.ev : VehicleType.bus;
    final live = map.liveVehicles
        .where((v) => v.type == type && v.position != null && distanceMeters(v.position!, stop.position) <= 700)
        .length;
    final startsHere = route.originId == stop.id;
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (live > 0)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const LiveDot(color: AppColors.onTime, size: 7),
              const SizedBox(width: 5),
              Text(
                '$live live nearby',
                style: const TextStyle(color: AppColors.onTime, fontWeight: FontWeight.w700, fontSize: 12.5),
              ),
            ],
          ),
        _line(
          Icons.hourglass_bottom_rounded,
          startsHere ? 'Starts here · leaves when full (2–30 min)' : 'Leaves when full · usually 2–30 min wait',
          muted,
        ),
      ],
    );
  }

  Widget _line(IconData icon, String text, Color color) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 5),
      Flexible(
        child: Text(
          text,
          style: TextStyle(color: color, fontSize: compact ? 12 : 12.5),
        ),
      ),
    ],
  );
}

/// Searchable list of stops; returns the chosen stop.
Future<NetworkStop?> pickStop(
  BuildContext context, {
  required List<NetworkStop> stops,
  required String title,
  NetworkStop? nearest,
}) => showModalBottomSheet<NetworkStop>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (context) => _StopPicker(stops: stops, title: title, nearest: nearest),
);

class _StopPicker extends StatefulWidget {
  const _StopPicker({required this.stops, required this.title, this.nearest});

  final List<NetworkStop> stops;
  final String title;
  final NetworkStop? nearest;

  @override
  State<_StopPicker> createState() => _StopPickerState();
}

class _StopPickerState extends State<_StopPicker> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final q = _q.toLowerCase().trim();
    final list = q.isEmpty
        ? widget.stops
        : widget.stops.where((s) => s.name.toLowerCase().contains(q) || (s.isCampus && 'c${s.id.substring(1)}' == q)).toList();
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.82,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              autofocus: true,
              onChanged: (v) => setState(() => _q = v),
              decoration: const InputDecoration(hintText: 'Campus, square or stop name', prefixIcon: Icon(Icons.search_rounded)),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              children: [
                if (widget.nearest != null && q.isEmpty)
                  ListTile(
                    leading: const SoftIcon(icon: Icons.my_location_rounded, color: AppColors.primary, size: 40),
                    title: Text(widget.nearest!.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Nearest stop to you'),
                    onTap: () => Navigator.pop(context, widget.nearest),
                  ),
                for (final s in list)
                  ListTile(
                    leading: SoftIcon(
                      icon: s.isCampus ? Icons.school_outlined : Icons.signpost_outlined,
                      color: s.isCampus ? AppColors.primary : AppColors.tertiary,
                      background: s.isCampus ? AppColors.sageSoft : AppColors.peachSoft,
                      size: 40,
                    ),
                    title: Text(s.name),
                    subtitle: Text(s.isCampus ? 'KIIT campus' : 'Mo Bus stop'),
                    onTap: () => Navigator.pop(context, s),
                  ),
                if (list.isEmpty) const EmptyState(icon: Icons.search_off_rounded, title: 'No stop matches that name'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
