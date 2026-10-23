import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/route_paths.dart';
import '../../core/services/journey_planner.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/network_model.dart';
import '../../viewmodels/map_viewmodel.dart';
import '../../viewmodels/network_viewmodel.dart';
import '../../widgets/common.dart';
import '../../widgets/network_widgets.dart';

/// Trip planner across KIIT buses/shuttles and Mo Bus: pick where you are,
/// where you're going and optionally a stop to pass through.
class PlannerPage extends StatefulWidget {
  const PlannerPage({super.key});

  @override
  State<PlannerPage> createState() => _PlannerPageState();
}

class _PlannerPageState extends State<PlannerPage> {
  bool _showVia = false;

  @override
  void initState() {
    super.initState();
    context.read<NetworkViewModel>().load();
  }

  Future<void> _pick(String title, ValueChanged<NetworkStop?> set) async {
    final vm = context.read<NetworkViewModel>();
    final me = context.read<MapViewModel>().userLocation;
    final stop = await pickStop(
      context,
      stops: vm.network!.servedStops,
      title: title,
      nearest: me == null ? null : vm.nearestStop(me),
    );
    if (stop != null) set(stop);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NetworkViewModel>();
    final ready = vm.network != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan a Trip'),
        actions: [
          if (vm.from != null || vm.to != null)
            TextButton(
              onPressed: () {
                vm.clear();
                setState(() => _showVia = false);
              },
              child: const Text('Clear'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: !ready
          ? (vm.error != null
                ? EmptyState(icon: Icons.cloud_off_rounded, title: vm.error!)
                : const Center(child: CircularProgressIndicator()))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              children: [
                Pod(
                  raised: true,
                  padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                _StopField(
                                  icon: Icons.trip_origin_rounded,
                                  label: 'From',
                                  stop: vm.from,
                                  onTap: () => _pick('Where are you?', vm.setFrom),
                                ),
                                if (_showVia || vm.via != null) ...[
                                  const SizedBox(height: 8),
                                  _StopField(
                                    icon: Icons.more_vert_rounded,
                                    label: 'Via (optional)',
                                    stop: vm.via,
                                    onTap: () => _pick('Pass through', vm.setVia),
                                    onClear: () {
                                      vm.setVia(null);
                                      setState(() => _showVia = false);
                                    },
                                  ),
                                ],
                                const SizedBox(height: 8),
                                _StopField(
                                  icon: Icons.place_rounded,
                                  label: 'To',
                                  stop: vm.to,
                                  onTap: () => _pick('Where to?', vm.setTo),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Swap',
                            onPressed: vm.swap,
                            icon: const Icon(Icons.swap_vert_rounded),
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                      if (!_showVia && vm.via == null)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => setState(() => _showVia = true),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Add a stop on the way'),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final f in NetworkFilter.values)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(f.label),
                            selected: vm.filter == f,
                            showCheckmark: false,
                            selectedColor: AppColors.teal,
                            onSelected: (_) => vm.setFilter(f),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                ..._results(context, vm),
              ],
            ),
    );
  }

  List<Widget> _results(BuildContext context, NetworkViewModel vm) {
    final results = vm.results;
    if (vm.from == null || vm.to == null) {
      return const [
        EmptyState(
          icon: Icons.alt_route_rounded,
          title: 'Where are you headed?',
          message: 'Pick a campus or stop for both ends. You will see direct rides first, then trips with a change.',
        ),
      ];
    }
    if (vm.from == vm.to) {
      return const [EmptyState(icon: Icons.check_circle_outline_rounded, title: 'You are already there')];
    }
    if (results == null || results.isEmpty) {
      return [
        EmptyState(
          icon: Icons.wrong_location_outlined,
          title: 'No connection found',
          message: vm.filter == NetworkFilter.all
              ? 'No route links these stops within two changes. Try a nearby stop.'
              : 'Nothing on ${vm.filter.label} alone. Try "All".',
        ),
      ];
    }
    final direct = results.where((j) => j.isDirect).length;
    return [
      SectionHeader(
        title: direct > 0 ? '$direct direct ${direct == 1 ? 'option' : 'options'}' : 'No direct ride',
        subtitle: direct > 0 ? 'Change-free rides first' : 'These trips need a change',
      ),
      const SizedBox(height: 12),
      for (final j in results) ...[
        JourneyCard(
          journey: j,
          onTap: () => context.push(RoutePaths.studentJourney, extra: j),
        ),
        const SizedBox(height: 12),
      ],
      const SizedBox(height: 4),
      Text(
        'Times are estimates from distance. KIIT vehicles leave when full; Mo Bus timings are not part of the network map.',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.muted(context), fontSize: 12),
      ),
    ];
  }
}

class _StopField extends StatelessWidget {
  const _StopField({required this.icon, required this.label, required this.stop, required this.onTap, this.onClear});

  final IconData icon;
  final String label;
  final NetworkStop? stop;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.fieldOf(context),
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(color: AppColors.muted(context), fontSize: 12)),
                  Text(
                    stop?.name ?? 'Choose a stop',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: stop == null ? AppColors.muted(context) : null,
                    ),
                  ),
                ],
              ),
            ),
            if (onClear != null)
              IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded, size: 18),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
      ),
    ),
  );
}

/// Summary of one trip: change count, total time, legs and availability.
class JourneyCard extends StatelessWidget {
  const JourneyCard({super.key, required this.journey, this.onTap});

  final Journey journey;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final j = journey;
    final (label, color) = switch (j.changes) {
      0 => ('Direct', AppColors.primary),
      1 => ('1 change', AppColors.tertiary),
      _ => ('${j.changes} changes', AppColors.cancelled),
    };
    return Pod(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusPill(label: label, color: color),
              const SizedBox(width: 8),
              if (j.usesKiit && j.usesMobus) const StatusPill(label: 'KIIT + Mo Bus', color: AppColors.secondary),
              const Spacer(),
              Text(
                '~${formatEta(j.rideMinutes + j.walkMinutes)}',
                style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (var i = 0; i < j.legs.length; i++) ...[
                if (i > 0) Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.muted(context)),
                if (j.legs[i].isWalk)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.directions_walk_rounded, size: 16, color: AppColors.muted(context)),
                      Text('${j.legs[i].walkMeters.round()} m', style: TextStyle(fontSize: 12, color: AppColors.muted(context))),
                    ],
                  )
                else
                  RouteBadge(route: j.legs[i].route!),
              ],
            ],
          ),
          const SizedBox(height: 12),
          for (final leg in j.legs) _LegLine(leg: leg),
        ],
      ),
    );
  }
}

class _LegLine extends StatelessWidget {
  const _LegLine({required this.leg});
  final JourneyLeg leg;

  @override
  Widget build(BuildContext context) {
    final muted = AppColors.muted(context);
    if (leg.isWalk) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          'Walk ${leg.walkMeters.round()} m to ${leg.to.name} (~${leg.minutes} min)',
          style: TextStyle(color: muted, fontSize: 13),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${leg.route!.label}  ',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(text: '${leg.from.name} → ${leg.to.name}'),
              ],
            ),
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            '${leg.stopCount} ${leg.stopCount == 1 ? 'stop' : 'stops'} · ~${leg.minutes} min',
            style: TextStyle(color: muted, fontSize: 12.5),
          ),
          const SizedBox(height: 3),
          Availability(route: leg.route!, stop: leg.from, compact: true),
        ],
      ),
    );
  }
}
