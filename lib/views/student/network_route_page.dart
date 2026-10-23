import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/route_paths.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/network_model.dart';
import '../../viewmodels/network_viewmodel.dart';
import '../../widgets/common.dart';
import '../../widgets/network_map.dart';
import '../../widgets/network_widgets.dart';

/// One KIIT or Mo Bus route traced on the map with its full stop list.
class NetworkRoutePage extends StatefulWidget {
  const NetworkRoutePage({super.key, required this.routeId});

  final String routeId;

  @override
  State<NetworkRoutePage> createState() => _NetworkRoutePageState();
}

class _NetworkRoutePageState extends State<NetworkRoutePage> {
  @override
  void initState() {
    super.initState();
    context.read<NetworkViewModel>().load();
  }

  void _planWith(NetworkStop stop, {required bool asStart}) {
    final vm = context.read<NetworkViewModel>();
    asStart ? vm.setFrom(stop) : vm.setTo(stop);
    context.push(RoutePaths.studentPlanner);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NetworkViewModel>();
    final route = vm.routeById(widget.routeId);
    if (route == null) {
      return Scaffold(
        appBar: AppBar(),
        body: vm.loading
            ? const Center(child: CircularProgressIndicator())
            : const EmptyState(icon: Icons.route_rounded, title: 'Route not found'),
      );
    }
    final stops = vm.stopsOf(route);
    final color = AppColors.parseHex(route.color);
    final origin = route.originId == null ? null : vm.network!.stop(route.originId!);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: NetworkMap(
              lines: [NetworkLine(points: route.geometry, color: color)],
              stops: stops,
              highlightStops: {stops.first.id, stops.last.id},
              padding: EdgeInsets.fromLTRB(40, 110, 40, MediaQuery.sizeOf(context).height * 0.45),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  MapFab(icon: Icons.arrow_back_rounded, onPressed: () => Navigator.of(context).maybePop()),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Pod(
                      raised: true,
                      radius: 18,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          RouteBadge(route: route, large: true),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              route.operator.label,
                              style: Theme.of(
                                context,
                              ).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.42,
            minChildSize: 0.18,
            maxChildSize: 0.88,
            builder: (context, scroll) => Material(
              color: Theme.of(context).colorScheme.surface,
              elevation: 8,
              shadowColor: AppColors.primary.withValues(alpha: 0.3),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 32),
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(color: AppColors.borderOf(context), borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(route.name, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      StatusPill(label: '${stops.length} stops', color: AppColors.secondary),
                      const StatusPill(label: 'Runs both ways', color: AppColors.secondary, icon: Icons.sync_alt_rounded),
                      StatusPill(label: route.mode.label, color: AppColors.tertiary),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _ServiceNote(route: route, origin: origin),
                  const SizedBox(height: 18),
                  const SectionHeader(title: 'Stops', subtitle: 'Tap a stop to plan a trip from or to it'),
                  const SizedBox(height: 8),
                  for (var i = 0; i < stops.length; i++)
                    _StopRow(
                      stop: stops[i],
                      color: color,
                      first: i == 0,
                      last: i == stops.length - 1,
                      isOrigin: stops[i].id == route.originId,
                      onFrom: () => _planWith(stops[i], asStart: true),
                      onTo: () => _planWith(stops[i], asStart: false),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceNote extends StatelessWidget {
  const _ServiceNote({required this.route, this.origin});

  final NetworkRoute route;
  final NetworkStop? origin;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: route.isKiit ? AppColors.sageSoft.withValues(alpha: 0.7) : AppColors.peachSoft,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          route.isKiit ? Icons.hourglass_bottom_rounded : Icons.info_outline_rounded,
          color: route.isKiit ? AppColors.primary : AppColors.tertiary,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            route.isKiit
                ? 'No fixed timetable. Vehicles are based at ${origin?.name ?? 'the first campus'} and leave when '
                      'seats fill, usually after 2 to 30+ minutes (student field research).'
                : 'From the CRUT Mo Bus network map. The map lists stops but no departure times. '
                      'Call CRUT on 1800 345 0061 for timings.',
            style: TextStyle(fontSize: 13, height: 1.4, color: route.isKiit ? AppColors.primaryDark : AppColors.tertiary),
          ),
        ),
      ],
    ),
  );
}

class _StopRow extends StatelessWidget {
  const _StopRow({
    required this.stop,
    required this.color,
    required this.first,
    required this.last,
    required this.isOrigin,
    required this.onFrom,
    required this.onTo,
  });

  final NetworkStop stop;
  final Color color;
  final bool first;
  final bool last;
  final bool isOrigin;
  final VoidCallback onFrom;
  final VoidCallback onTo;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: () => showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(stop.name, style: Theme.of(context).textTheme.titleLarge),
            if (stop.approximate)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Map position is approximate', style: TextStyle(color: AppColors.muted(context))),
              ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.trip_origin_rounded),
              title: const Text('Plan a trip from here'),
              onTap: () {
                Navigator.pop(context);
                onFrom();
              },
            ),
            ListTile(
              leading: const Icon(Icons.place_rounded),
              title: const Text('Plan a trip to here'),
              onTap: () {
                Navigator.pop(context);
                onTo();
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    ),
    child: IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 22,
            child: Column(
              children: [
                Expanded(child: Container(width: 4, color: first ? Colors.transparent : color.withValues(alpha: 0.5))),
                Container(
                  width: first || last ? 15 : 11,
                  height: first || last ? 15 : 11,
                  decoration: BoxDecoration(
                    color: first || last ? color : Theme.of(context).colorScheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 3),
                  ),
                ),
                Expanded(child: Container(width: 4, color: last ? Colors.transparent : color.withValues(alpha: 0.5))),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      stop.name,
                      style: TextStyle(fontWeight: first || last ? FontWeight.w700 : FontWeight.w500, fontSize: 14.5),
                    ),
                  ),
                  if (stop.isCampus) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.school_outlined, size: 15, color: AppColors.primary),
                  ],
                  if (isOrigin) ...[const SizedBox(width: 8), const StatusPill(label: 'Depot', color: AppColors.primary)],
                ],
              ),
            ),
          ),
          Icon(Icons.more_horiz_rounded, color: AppColors.muted(context), size: 18),
        ],
      ),
    ),
  );
}
