import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/route_paths.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/vehicle_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/request_viewmodel.dart';
import '../../viewmodels/vehicle_viewmodel.dart';
import '../../widgets/campus_map.dart';
import '../../widgets/common.dart';
import '../../widgets/request_card.dart';

/// Driver home: assigned vehicle, duty control and student demand signals.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    context.read<VehicleViewModel>().start();
    context.read<RequestViewModel>().start();
  }

  Future<void> _startDuty() async {
    final vm = context.read<VehicleViewModel>();
    if (await vm.startDuty()) {
      if (mounted) context.push(RoutePaths.driverTracking);
    } else if (mounted && vm.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(vm.error!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().user;
    final vm = context.watch<VehicleViewModel>();
    final requests = context.watch<RequestViewModel>();
    final vehicle = vm.myVehicle;
    final near = requests.nearby(vm.lastFix?.position ?? vehicle?.position);

    return Scaffold(
      appBar: BrandBar(
        title: 'KIIT Transit Driver',
        actions: [
          IconButton(
            tooltip: 'Profile',
            onPressed: () => context.push(RoutePaths.profile),
            icon: UserAvatar(name: user?.name ?? 'D', radius: 20),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 14),
            child: Text(
              '${greeting()}, ${user?.name.split(' ').first ?? ''}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.muted(context)),
            ),
          ),
          if (AppConstants.isDemoMode) ...[const DemoBanner(compact: true), const SizedBox(height: 14)],
          _DutyCard(
            vehicle: vehicle,
            vm: vm,
            onSelect: () => context.push(RoutePaths.driverVehicles),
            onStart: _startDuty,
            onOpenTracking: () => context.push(RoutePaths.driverTracking),
          ),
          const SizedBox(height: 28),
          SectionHeader(
            title: 'Nearby demand requests',
            subtitle: near.isEmpty
                ? 'No students are signalling right now'
                : '${requests.totalWaiting} students waiting across campus',
          ),
          const SizedBox(height: 10),
          if (near.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: SizedBox(
                height: 190,
                child: CampusMap(
                  showLandmarks: false,
                  initialZoom: 15,
                  userLocation: vm.lastFix?.position,
                  children: [DemandLayer(requests: near.map((e) => e.request).toList())],
                ),
              ),
            ),
            const SizedBox(height: 12),
            for (final e in near) ...[
              RequestCard(request: e.request, distanceMeters: e.distance, onServe: () => requests.resolve(e.request)),
              const SizedBox(height: 10),
            ],
          ] else
            const EmptyState(
              icon: Icons.check_circle_outline_rounded,
              title: 'All clear',
              message: 'Demand signals from students will show up here.',
            ),
        ],
      ),
    );
  }
}

class _DutyCard extends StatelessWidget {
  const _DutyCard({
    required this.vehicle,
    required this.vm,
    required this.onSelect,
    required this.onStart,
    required this.onOpenTracking,
  });

  final VehicleModel? vehicle;
  final VehicleViewModel vm;
  final VoidCallback onSelect;
  final VoidCallback onStart;
  final VoidCallback onOpenTracking;

  @override
  Widget build(BuildContext context) {
    final v = vehicle;
    final onDuty = vm.onDuty;
    final primary = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Pod(
          raised: true,
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      v?.vehicleNumber ?? 'No vehicle',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(color: primary, fontSize: v == null ? 30 : 40),
                    ),
                  ),
                  if (v != null && !onDuty) TextButton(onPressed: onSelect, child: const Text('Change')),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                v == null ? 'Pick the vehicle you are driving today.' : v.type.label,
                style: TextStyle(color: AppColors.muted(context), fontSize: 15),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: onDuty ? AppColors.primary : AppColors.fieldOf(context),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      onDuty ? 'ACTIVE' : 'OFF DUTY',
                      style: TextStyle(
                        color: onDuty ? Colors.white : AppColors.muted(context),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  if (onDuty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(color: AppColors.fieldOf(context), borderRadius: BorderRadius.circular(999)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          LiveDot(color: primary, size: 8),
                          const SizedBox(width: 8),
                          Text(
                            'Visible to students',
                            style: TextStyle(color: primary, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              if (onDuty && vm.dutyStartedAt != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 20, color: AppColors.muted(context)),
                    const SizedBox(width: 8),
                    Text(
                      'Shift start: ${formatClock(vm.dutyStartedAt!.hour * 60 + vm.dutyStartedAt!.minute)}',
                      style: TextStyle(color: AppColors.muted(context), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 22),
              FilledButton.icon(
                style: onDuty || v == null
                    ? null
                    : FilledButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
                onPressed: vm.busy ? null : (v == null ? onSelect : (onDuty ? onOpenTracking : onStart)),
                icon: Icon(
                  v == null ? Icons.directions_car_rounded : (onDuty ? Icons.navigation_rounded : Icons.play_arrow_rounded),
                ),
                label: Text(v == null ? 'Select vehicle' : (onDuty ? 'Open live tracking' : 'Start duty')),
              ),
            ],
          ),
        ),
        if (onDuty) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: StatTile(icon: Icons.timer_outlined, label: 'On duty', value: _duration(vm.dutyStartedAt)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatTile(icon: Icons.sync_rounded, label: 'Updates', value: '${vm.updatesSent}'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatTile(icon: Icons.route_rounded, label: 'Distance', value: formatDistance(vm.distanceCoveredMeters)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatTile(
                  icon: Icons.location_on_outlined,
                  label: 'GPS',
                  value: vm.lastFix == null ? 'Waiting' : 'Connected',
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  static String _duration(DateTime? since) {
    if (since == null) return '—';
    final d = DateTime.now().difference(since);
    return d.inHours > 0 ? '${d.inHours}h ${d.inMinutes % 60}m' : '${d.inMinutes}m';
  }
}

/// Small status tile: duotone icon, caps label and value.
class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Pod(
    padding: const EdgeInsets.all(14),
    child: Row(
      children: [
        SoftIcon(icon: icon, color: AppColors.primary, background: AppColors.sage.withValues(alpha: 0.35), size: 44),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(fontSize: 11, letterSpacing: 0.8, fontWeight: FontWeight.w600, color: AppColors.muted(context)),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Theme.of(context).colorScheme.primary),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
