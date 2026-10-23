import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/route_paths.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/network_model.dart';
import '../../viewmodels/map_viewmodel.dart';
import '../../viewmodels/network_viewmodel.dart';
import '../../widgets/common.dart';
import '../../widgets/network_widgets.dart';
import '../../widgets/route_card.dart';

/// Every route students can use: KIIT inter-campus buses and shuttles, the
/// Mo Bus city network, and the live-tracked campus loops.
class RoutesPage extends StatefulWidget {
  const RoutesPage({super.key});

  @override
  State<RoutesPage> createState() => _RoutesPageState();
}

class _RoutesPageState extends State<RoutesPage> {
  @override
  void initState() {
    super.initState();
    context.read<NetworkViewModel>().load();
  }

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 3,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Routes'),
        actions: [
          IconButton(
            tooltip: 'Plan a trip',
            onPressed: () => context.push(RoutePaths.studentPlanner),
            icon: const Icon(Icons.alt_route_rounded),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: 'KIIT'),
            Tab(text: 'Mo Bus'),
            Tab(text: 'Live loops'),
          ],
        ),
      ),
      body: TabBarView(
        children: [
          const _NetworkList(operator: NetworkOperator.kiit),
          const _NetworkList(operator: NetworkOperator.mobus),
          const _LiveLoops(),
        ],
      ),
    ),
  );
}

class _NetworkList extends StatefulWidget {
  const _NetworkList({required this.operator});

  final NetworkOperator operator;

  @override
  State<_NetworkList> createState() => _NetworkListState();
}

class _NetworkListState extends State<_NetworkList> with AutomaticKeepAliveClientMixin {
  String query = '';

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final operator = widget.operator;
    final vm = context.watch<NetworkViewModel>();
    if (vm.network == null) {
      return vm.error != null
          ? EmptyState(icon: Icons.cloud_off_rounded, title: vm.error!)
          : const Center(child: CircularProgressIndicator());
    }
    final q = query.toLowerCase().trim();
    final routes = vm.network!.routes.where((r) => r.operator == operator).where((r) {
      if (q.isEmpty) return true;
      return r.ref.toLowerCase() == q ||
          r.name.toLowerCase().contains(q) ||
          vm.stopsOf(r).any((s) => s.name.toLowerCase().contains(q));
    }).toList();
    final isKiit = operator == NetworkOperator.kiit;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        TextField(
          onChanged: (q) => setState(() => query = q),
          decoration: InputDecoration(
            hintText: isKiit ? 'Search a campus or route (e.g. Campus 15)' : 'Search a stop or route (e.g. Patia, 12)',
            prefixIcon: const Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: 14),
        Pod(
          onTap: () => context.push(RoutePaths.studentPlanner),
          color: AppColors.sageSoft.withValues(alpha: 0.7),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const SoftIcon(icon: Icons.alt_route_rounded, color: AppColors.primary, background: Colors.white, size: 44),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Plan a trip', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    Text(
                      'Direct rides and changes across KIIT and Mo Bus',
                      style: TextStyle(color: AppColors.muted(context), fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SectionHeader(
          title: isKiit ? '${routes.length} campus links' : '${routes.length} Mo Bus routes',
          subtitle: isKiit
              ? 'Student-mapped. No timetable: vehicles leave when full.'
              : 'From the CRUT network map. Both directions.',
        ),
        const SizedBox(height: 12),
        if (routes.isEmpty) const EmptyState(icon: Icons.search_off_rounded, title: 'No route matches'),
        for (final r in routes) ...[_NetworkRouteTile(route: r, stops: vm.stopsOf(r)), const SizedBox(height: 10)],
      ],
    );
  }
}

class _NetworkRouteTile extends StatelessWidget {
  const _NetworkRouteTile({required this.route, required this.stops});

  final NetworkRoute route;
  final List<NetworkStop> stops;

  @override
  Widget build(BuildContext context) {
    return Pod(
      onTap: () => context.push('${RoutePaths.networkRoute}/${route.id}'),
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      child: Row(
        children: [
          RouteBadge(route: route, large: true),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  route.isKiit ? stops.map((s) => s.name.split(' (').first).join(' ↔ ') : route.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
                ),
                const SizedBox(height: 4),
                Text(
                  route.isKiit
                      ? '${route.mode.label} · ${stops.length} campuses'
                      : '${stops.length} stops · ${stops.first.name} ↔ ${stops.last.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.muted(context), fontSize: 12.5),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: AppColors.muted(context)),
        ],
      ),
    );
  }
}

/// The live-tracked campus loops from the transport backend.
class _LiveLoops extends StatelessWidget {
  const _LiveLoops();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MapViewModel>();
    if (vm.routes.isEmpty) {
      return vm.loading
          ? const Center(child: CircularProgressIndicator())
          : const EmptyState(icon: Icons.alt_route_rounded, title: 'No live routes yet');
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        const SectionHeader(title: 'Live-tracked loops', subtitle: 'Vehicles on these show on the live map'),
        const SizedBox(height: 12),
        for (final r in vm.routes) ...[
          RouteCard(
            route: r,
            liveCount: vm.vehiclesOnRoute(r.id).length,
            onTap: () => context.push('${RoutePaths.routeDetail}/${r.id}'),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
