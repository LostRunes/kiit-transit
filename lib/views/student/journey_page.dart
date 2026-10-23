import 'package:flutter/material.dart';

import '../../core/services/journey_planner.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/common.dart';
import '../../widgets/network_map.dart';
import '../../widgets/network_widgets.dart';

/// One planned trip traced on the map, with step-by-step directions.
class JourneyPage extends StatelessWidget {
  const JourneyPage({super.key, required this.journey});

  final Journey? journey;

  @override
  Widget build(BuildContext context) {
    final j = journey;
    if (j == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(icon: Icons.alt_route_rounded, title: 'Plan the trip again to see it here'),
      );
    }
    final lines = [
      for (final leg in j.legs)
        NetworkLine(
          points: legPath(leg),
          color: leg.isWalk ? AppColors.inkMuted : AppColors.parseHex(leg.route!.color),
          dashed: leg.isWalk,
          width: leg.isWalk ? 3.5 : 5.5,
        ),
    ];
    final stops = {
      for (final leg in j.legs) ...leg.stops,
      for (final leg in j.legs) ...[leg.from, leg.to],
    }.toList();
    final key = {
      for (final leg in j.legs) ...[leg.from.id, leg.to.id],
    };

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: NetworkMap(
              lines: lines,
              stops: stops,
              highlightStops: key,
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Text(
                        '${j.legs.first.from.name} → ${j.legs.last.to.name}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall,
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
                  Row(
                    children: [
                      Text(
                        j.isDirect ? 'Direct' : '${j.changes} ${j.changes == 1 ? 'change' : 'changes'}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      Text(
                        '~${formatEta(j.rideMinutes + j.walkMinutes)} on the move',
                        style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  for (var i = 0; i < j.legs.length; i++) _Step(leg: j.legs[i], index: i, last: i == j.legs.length - 1),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.leg, required this.index, required this.last});

  final JourneyLeg leg;
  final int index;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final color = leg.isWalk ? AppColors.inkMuted : AppColors.parseHex(leg.route!.color);
    final muted = AppColors.muted(context);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.surface,
                    border: Border.all(color: color, width: 4),
                  ),
                ),
                Expanded(
                  child: Container(width: 4, color: color.withValues(alpha: leg.isWalk ? 0.3 : 0.6)),
                ),
                if (last)
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(leg.from.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 6),
                  if (leg.isWalk)
                    Text('Walk ${leg.walkMeters.round()} m (~${leg.minutes} min)', style: TextStyle(color: muted))
                  else ...[
                    Row(
                      children: [
                        RouteBadge(route: leg.route!),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'towards ${leg.to.name}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: muted),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${leg.stopCount} ${leg.stopCount == 1 ? 'stop' : 'stops'} · ~${leg.minutes} min',
                      style: TextStyle(color: muted, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Availability(route: leg.route!, stop: leg.from),
                    if (leg.stops.length > 2) ...[
                      const SizedBox(height: 6),
                      Text(
                        leg.stops.sublist(1, leg.stops.length - 1).map((s) => s.name).join(' · '),
                        style: TextStyle(color: muted, fontSize: 12),
                      ),
                    ],
                  ],
                  if (last) ...[
                    const SizedBox(height: 14),
                    Text(leg.to.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
