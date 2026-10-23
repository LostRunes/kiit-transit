import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/route_paths.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/route_model.dart';
import '../../data/models/schedule_model.dart';
import '../../viewmodels/map_viewmodel.dart';
import '../../viewmodels/route_viewmodel.dart';
import '../../widgets/common.dart';
import '../../widgets/route_card.dart';

Color scheduleColor(ScheduleStatus s) => switch (s) {
  ScheduleStatus.onTime => AppColors.onTime,
  ScheduleStatus.delayed => AppColors.delayed,
  ScheduleStatus.cancelled => AppColors.cancelled,
};

/// Digitized bus timetables with live on-time / delayed / cancelled status.
class SchedulePage extends StatelessWidget {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RouteViewModel>();
    final map = context.watch<MapViewModel>();
    final routes = vm.visibleRoutes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedules'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                formatClock(vm.nowMinutes()),
                style: TextStyle(color: AppColors.muted(context), fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => vm.load(refresh: true),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chip(context, 'All routes', null, vm),
                  for (final r in vm.busRoutes) _chip(context, r.shortName, r.id, vm),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (vm.loading && vm.routes.isEmpty)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (vm.error != null && vm.routes.isEmpty)
              EmptyState(
                icon: Icons.cloud_off_rounded,
                title: vm.error!,
                action: FilledButton.tonal(onPressed: () => vm.load(refresh: true), child: const Text('Retry')),
              )
            else if (routes.isEmpty)
              const EmptyState(icon: Icons.event_busy_rounded, title: 'No bus routes yet')
            else
              for (final r in routes) ...[
                _RouteSchedule(route: r, vm: vm, liveVehicles: map.vehiclesOnRoute(r.id).map((v) => v.vehicleNumber).toList()),
                const SizedBox(height: 28),
              ],
          ],
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, String label, String? id, RouteViewModel vm) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      label: Text(label),
      selected: vm.selectedRouteId == id,
      showCheckmark: false,
      onSelected: (_) => vm.selectRoute(id),
    ),
  );
}

class _RouteSchedule extends StatelessWidget {
  const _RouteSchedule({required this.route, required this.vm, required this.liveVehicles});

  final RouteModel route;
  final RouteViewModel vm;
  final List<String> liveVehicles;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.parseHex(route.color);
    final next = vm.nextDeparture(route.id);
    final upcoming = vm.upcoming(route.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Pod(
          raised: true,
          onTap: () => context.push('${RoutePaths.routeDetail}/${route.id}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          route.shortName,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          route.name.split('--').last.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                  if (liveVehicles.isNotEmpty) _LivePill(label: liveVehicles.join(', ')),
                ],
              ),
              const SizedBox(height: 20),
              if (next == null)
                Text(
                  'No more departures today',
                  style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.muted(context)),
                )
              else ...[
                Text(
                  vm.minutesUntil(next) <= 0 ? 'Departing' : 'Departure in',
                  style: TextStyle(color: AppColors.muted(context), fontSize: 15),
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      vm.minutesUntil(next) <= 0 ? 'now' : formatEta(vm.minutesUntil(next)),
                      style: Theme.of(
                        context,
                      ).textTheme.displaySmall?.copyWith(color: Theme.of(context).colorScheme.primary, fontSize: 38),
                    ),
                    const SizedBox(width: 10),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'at ${formatClock(next.expectedDepartureMinutes)}',
                        style: TextStyle(color: AppColors.muted(context), fontWeight: FontWeight.w600),
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: StatusPill(
                        label: next.status == ScheduleStatus.delayed ? '+${next.delayMinutes} min' : next.status.label,
                        color: scheduleColor(next.status),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              StopStrip(stops: route.stops, color: color),
            ],
          ),
        ),
        if (upcoming.isNotEmpty) ...[
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'UPCOMING DEPARTURES',
              style: TextStyle(letterSpacing: 1.2, fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.muted(context)),
            ),
          ),
          for (final s in upcoming) ...[
            _DepartureRow(schedule: s, routeName: route.name.split('--').last.trim()),
            const SizedBox(height: 10),
          ],
        ],
      ],
    );
  }
}

class _LivePill extends StatelessWidget {
  const _LivePill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(color: AppColors.fieldOf(context), borderRadius: BorderRadius.circular(999)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const LiveDot(color: AppColors.sage, size: 8),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ],
    ),
  );
}

class _DepartureRow extends StatelessWidget {
  const _DepartureRow({required this.schedule, required this.routeName});
  final ScheduleModel schedule;
  final String routeName;

  @override
  Widget build(BuildContext context) {
    final s = schedule;
    final color = scheduleColor(s.status);
    final cancelled = s.status == ScheduleStatus.cancelled;
    final late = s.delayMinutes > 0;
    return Pod(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      radius: 20,
      child: Row(
        children: [
          const SoftIcon(icon: Icons.directions_bus_rounded, color: AppColors.bus, background: AppColors.busSoft, circle: false),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  routeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    StatusPill(
                      label: s.status == ScheduleStatus.delayed ? 'Delayed ${s.delayMinutes}m' : s.status.label,
                      color: color,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'arr. ${formatClock(s.arrivalMinutes + s.delayMinutes)}',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: AppColors.muted(context), fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatClock(s.expectedDepartureMinutes),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  decoration: cancelled ? TextDecoration.lineThrough : null,
                  color: cancelled ? AppColors.muted(context) : null,
                ),
              ),
              if (late && !cancelled)
                Text(
                  formatClock(s.departureMinutes),
                  style: TextStyle(fontSize: 12, color: AppColors.muted(context), decoration: TextDecoration.lineThrough),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
