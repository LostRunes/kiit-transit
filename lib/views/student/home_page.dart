import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/campus_locations.dart';
import '../../core/constants/route_paths.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/vehicle_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/map_viewmodel.dart';
import '../../viewmodels/request_viewmodel.dart';
import '../../widgets/common.dart';
import '../../widgets/vehicle_marker.dart';

/// Student dashboard: greeting, nearest vehicle with ETA, quick actions and
/// a live activity feed built from the fleet and demand signals.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final Timer _clock;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 30), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _clock.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MapViewModel>();
    final requests = context.watch<RequestViewModel>().requests;
    final user = context.watch<AuthViewModel>().user;
    final name = user?.name ?? '';
    final nearest = vm.nearest;
    final now = TimeOfDay.now();

    return Scaffold(
      appBar: BrandBar(
        actions: [
          IconButton(
            tooltip: 'Profile',
            onPressed: () => context.push(RoutePaths.profile),
            icon: UserAvatar(name: name.isEmpty ? 'K' : name, radius: 20),
          ),
        ],
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: Theme.of(context).brightness == Brightness.dark
              ? null
              : LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.center,
                  colors: [AppColors.peachSoft.withValues(alpha: 0.45), AppColors.surface],
                ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${greeting()}${name.isEmpty ? '' : ', ${name.split(' ').first}'}',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 26, height: 1.2),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.place_outlined, size: 18, color: AppColors.muted(context)),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              vm.userLocation != null
                                  ? 'Near ${CampusLocations.nearest(vm.userLocation!).name}'
                                  : (vm.referenceLandmark?.name ?? 'KIIT campus'),
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: AppColors.muted(context), fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: AppColors.sageSoft, borderRadius: BorderRadius.circular(999)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const LiveDot(size: 7, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            '${vm.liveCount} live',
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      now.format(context),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Theme.of(context).colorScheme.primary),
                    ),
                  ],
                ),
              ],
            ),
            if (AppConstants.isDemoMode) ...[const SizedBox(height: 16), const DemoBanner(compact: true)],
            const SizedBox(height: 24),
            _NearestCard(
              vehicle: nearest,
              loading: vm.loading,
              hasReference: vm.referencePoint != null,
              onEnableLocation: vm.refreshLocation,
              onTap: nearest == null
                  ? null
                  : () {
                      vm.selectVehicle(nearest.id);
                      context.go(RoutePaths.studentMap);
                    },
            ),
            const SizedBox(height: 16),
            Pod(
              onTap: () => context.push(RoutePaths.studentPlanner),
              color: AppColors.primary,
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
              child: const Row(
                children: [
                  SoftIcon(icon: Icons.alt_route_rounded, color: Colors.white, background: Color(0x33FFFFFF), size: 48),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Plan a trip',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Campus to campus or across the city by Mo Bus',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_rounded, color: Colors.white),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.25,
              children: [
                _ActionTile(
                  icon: Icons.map_outlined,
                  label: 'Live Map',
                  color: AppColors.primary,
                  background: AppColors.sageSoft,
                  onTap: () => context.go(RoutePaths.studentMap),
                ),
                _ActionTile(
                  icon: Icons.calendar_month_outlined,
                  label: 'Schedules',
                  color: AppColors.onTeal,
                  background: AppColors.teal.withValues(alpha: 0.45),
                  onTap: () => context.go(RoutePaths.studentSchedule),
                ),
                _ActionTile(
                  icon: Icons.alt_route_rounded,
                  label: 'Routes',
                  color: AppColors.tertiary,
                  background: AppColors.peachSoft,
                  onTap: () => context.go(RoutePaths.studentRoutes),
                ),
                _ActionTile(
                  icon: Icons.electric_rickshaw_outlined,
                  label: 'Request EV',
                  color: AppColors.primary,
                  background: AppColors.sageSoft,
                  onTap: () => context.go(RoutePaths.studentRequest),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Pod(
              onTap: () => context.push(RoutePaths.studentDrivers),
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(
                children: [
                  const SoftIcon(
                    icon: Icons.contact_phone_outlined,
                    color: AppColors.onTeal,
                    background: AppColors.teal,
                    size: 44,
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text('Driver directory', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  ),
                  Icon(Icons.chevron_right_rounded, color: AppColors.muted(context)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SectionHeader(
              title: 'Activity Feed',
              trailing: TextButton(onPressed: () => context.go(RoutePaths.studentMap), child: const Text('See all')),
            ),
            const SizedBox(height: 12),
            ..._feed(context, vm, requests.map((r) => (r.locationName, r.studentCount, r.createdAt)).toList()),
          ],
        ),
      ),
    );
  }

  List<Widget> _feed(BuildContext context, MapViewModel vm, List<(String, int, DateTime)> requests) {
    final items = <Widget>[
      for (final v in vm.liveVehicles.take(3))
        _FeedItem(
          icon: vehicleIcon(v.type),
          color: AppColors.onSage,
          background: AppColors.sage,
          text: '${v.vehicleNumber} is near ${CampusLocations.nearest(v.position!).name}.',
          time: v.lastUpdated == null ? '' : timeAgo(v.lastUpdated!),
        ),
      for (final r in requests.take(2))
        _FeedItem(
          icon: Icons.groups_outlined,
          color: AppColors.tertiary,
          background: AppColors.peach,
          text: '${r.$2} ${r.$2 == 1 ? 'student is' : 'students are'} waiting at ${r.$1}.',
          time: timeAgo(r.$3),
        ),
    ];
    if (items.isEmpty) {
      return const [
        EmptyState(
          icon: Icons.nights_stay_outlined,
          title: 'All quiet on campus',
          message: 'Vehicle and demand updates will show up here.',
        ),
      ];
    }
    return [
      for (final i in items) ...[i, const SizedBox(height: 12)],
    ];
  }
}

class _NearestCard extends StatelessWidget {
  const _NearestCard({
    required this.vehicle,
    required this.loading,
    required this.hasReference,
    required this.onEnableLocation,
    this.onTap,
  });

  final VehicleModel? vehicle;
  final bool loading;
  final bool hasReference;
  final VoidCallback onEnableLocation;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final v = vehicle;
    final primary = Theme.of(context).colorScheme.primary;
    return Pod(
      raised: true,
      radius: 32,
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
      child: v == null
          ? Column(
              children: [
                const SizedBox(height: 8),
                if (loading)
                  const CircularProgressIndicator()
                else ...[
                  const SoftIcon(
                    icon: Icons.nights_stay_outlined,
                    color: AppColors.primary,
                    background: AppColors.sageSoft,
                    size: 64,
                  ),
                  const SizedBox(height: 14),
                  Text('No vehicles on duty', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    'Vehicles appear as soon as a driver starts their shift.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted(context)),
                  ),
                ],
                const SizedBox(height: 8),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.teal, borderRadius: BorderRadius.circular(999)),
                      child: Text(
                        v.type == VehicleType.ev ? 'ELECTRIC' : 'BUS',
                        style: const TextStyle(
                          color: AppColors.onTeal,
                          fontWeight: FontWeight.w700,
                          fontSize: 11.5,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'In transit',
                      style: TextStyle(color: AppColors.muted(context), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Nearest vehicle: ${v.vehicleNumber}', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.share_location_rounded, size: 20, color: AppColors.muted(context)),
                    const SizedBox(width: 6),
                    Text(
                      v.distanceMeters == null
                          ? 'Near ${CampusLocations.nearest(v.position!).name}'
                          : '${formatDistance(v.distanceMeters!)} away',
                      style: TextStyle(color: AppColors.muted(context), fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Center(
                  child: hasReference
                      ? _EtaRing(minutes: v.etaMinutes)
                      : OutlinedButton.icon(
                          onPressed: onEnableLocation,
                          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
                          icon: const Icon(Icons.my_location_rounded),
                          label: const Text('Enable location for ETA'),
                        ),
                ),
                if (hasReference) ...[
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      'Tap to track on the map',
                      style: TextStyle(color: primary.withValues(alpha: 0.7), fontSize: 12.5, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

/// Large circular ETA readout: "3 MINS".
class _EtaRing extends StatelessWidget {
  const _EtaRing({required this.minutes});
  final int? minutes;

  @override
  Widget build(BuildContext context) {
    final m = minutes;
    final arriving = m != null && m <= 1;
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.sageSoft, width: 4),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            m == null ? '—' : (arriving ? 'Now' : '$m'),
            style: Theme.of(
              context,
            ).textTheme.displaySmall?.copyWith(color: AppColors.sage, fontSize: arriving ? 34 : 44, height: 1),
          ),
          const SizedBox(height: 4),
          Text(
            arriving ? 'ARRIVING' : (m == 1 ? 'MIN' : 'MINS'),
            style: TextStyle(color: AppColors.muted(context), fontSize: 12, letterSpacing: 1, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pod(
    onTap: onTap,
    padding: const EdgeInsets.all(12),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SoftIcon(icon: icon, color: color, background: background, size: 60),
        const SizedBox(height: 14),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
      ],
    ),
  );
}

class _FeedItem extends StatelessWidget {
  const _FeedItem({required this.icon, required this.color, required this.background, required this.text, required this.time});

  final IconData icon;
  final Color color;
  final Color background;
  final String text;
  final String time;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: AppColors.fieldOf(context), borderRadius: BorderRadius.circular(24)),
    child: Row(
      children: [
        SoftIcon(icon: icon, color: color, background: background, circle: false, size: 52),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(text, style: const TextStyle(fontSize: 15.5, height: 1.35)),
              if (time.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(time, style: TextStyle(color: AppColors.muted(context), fontSize: 13)),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}
