import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/campus_locations.dart';
import '../../core/constants/route_paths.dart';
import '../../core/services/location_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/vehicle_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/map_viewmodel.dart';
import '../../widgets/campus_map.dart';
import '../../widgets/common.dart';
import '../../widgets/eta_widget.dart';
import '../../widgets/route_card.dart';
import '../../widgets/vehicle_marker.dart';

/// Live campus map with a sheet of nearby vehicles and routes.
class LiveMapPage extends StatefulWidget {
  const LiveMapPage({super.key});

  @override
  State<LiveMapPage> createState() => _LiveMapPageState();
}

class _LiveMapPageState extends State<LiveMapPage> {
  final _map = MapController();
  final _sheet = DraggableScrollableController();

  void _focus(VehicleModel v) {
    final vm = context.read<MapViewModel>();
    vm.selectVehicle(v.id);
    _map.move(v.position!, 16.8);
    if (_sheet.isAttached) {
      _sheet.animateTo(0.42, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  void _locate() {
    final vm = context.read<MapViewModel>();
    final ref = vm.referencePoint;
    if (ref != null) {
      _map.move(ref, 16.5);
    } else {
      vm.refreshLocation();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MapViewModel>();
    final user = context.watch<AuthViewModel>().user;
    final selected = vm.selectedVehicle;

    return Scaffold(
      body: Stack(
        children: [
          CampusMap(
            controller: _map,
            routes: vm.routes,
            highlightedRouteId: vm.highlightedRouteId,
            userLocation: vm.userLocation,
            onTap: () => vm.selectVehicle(null),
            children: [AnimatedVehicleLayer(vehicles: vm.liveVehicles, selectedId: vm.selectedVehicleId, onTap: _focus)],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                children: [
                  _Header(name: user?.name ?? '', liveCount: vm.liveCount),
                  const SizedBox(height: 10),
                  _FilterBar(vm: vm),
                  if (vm.error != null) ...[
                    const SizedBox(height: 8),
                    StatusPill(label: vm.error!, color: AppColors.delayed, icon: Icons.wifi_off_rounded),
                  ],
                ],
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: MediaQuery.sizeOf(context).height * 0.3 + 16,
            child: Column(
              children: [
                MapFab(
                  icon: Icons.crop_free_rounded,
                  tooltip: 'Show campus',
                  onPressed: () => _map.move(CampusLocations.center, CampusLocations.initialZoom),
                ),
                const SizedBox(height: 10),
                MapFab(
                  icon: vm.userLocation != null ? Icons.my_location_rounded : Icons.location_searching_rounded,
                  tooltip: 'My location',
                  active: vm.userLocation != null,
                  onPressed: _locate,
                ),
              ],
            ),
          ),
          DraggableScrollableSheet(
            controller: _sheet,
            initialChildSize: 0.3,
            minChildSize: 0.14,
            maxChildSize: 0.86,
            snap: true,
            snapSizes: const [0.3, 0.55],
            builder: (context, scroll) => _Sheet(scroll: scroll, vm: vm, selected: selected, onVehicleTap: _focus),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.name, required this.liveCount});

  final String name;
  final int liveCount;

  @override
  Widget build(BuildContext context) {
    return Pod(
      raised: true,
      radius: 24,
      padding: const EdgeInsets.fromLTRB(18, 10, 6, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KIIT Transit',
                  maxLines: 1,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.primary),
                ),
                Row(
                  children: [
                    const LiveDot(size: 7, color: AppColors.sage),
                    const SizedBox(width: 6),
                    Text(
                      '$liveCount vehicles live${AppConstants.isDemoMode ? ' · demo' : ''}',
                      style: TextStyle(color: AppColors.muted(context), fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Profile',
            onPressed: () => context.push(RoutePaths.profile),
            icon: UserAvatar(name: name.isEmpty ? 'K' : name, radius: 20),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.vm});
  final MapViewModel vm;

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, VehicleType? type, int count, IconData icon, Color color) {
      final selected = vm.typeFilter == type;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: FilterChip(
          selected: selected,
          showCheckmark: false,
          avatar: Icon(icon, size: 17, color: selected ? Colors.white : color),
          label: Text('$label  $count'),
          labelStyle: TextStyle(color: selected ? Colors.white : null, fontWeight: FontWeight.w600),
          selectedColor: AppColors.primary,
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 3,
          shadowColor: AppColors.primary.withValues(alpha: 0.25),
          onSelected: (_) => vm.setTypeFilter(selected ? null : type),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip('All', null, vm.liveCount, Icons.layers_outlined, AppColors.primary),
          chip('EV carts', VehicleType.ev, vm.liveCountOf(VehicleType.ev), Icons.electric_rickshaw_rounded, AppColors.ev),
          chip('Buses', VehicleType.bus, vm.liveCountOf(VehicleType.bus), Icons.directions_bus_rounded, AppColors.bus),
        ],
      ),
    );
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet({required this.scroll, required this.vm, required this.selected, required this.onVehicleTap});

  final ScrollController scroll;
  final MapViewModel vm;
  final VehicleModel? selected;
  final ValueChanged<VehicleModel> onVehicleTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final vehicles = vm.liveVehicles;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.12), blurRadius: 30, offset: const Offset(0, -6))],
      ),
      child: Material(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: CustomScrollView(
          controller: scroll,
          slivers: [
            SliverToBoxAdapter(
              child: Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(color: AppColors.borderOf(context), borderRadius: BorderRadius.circular(4)),
                ),
              ),
            ),
            if (selected != null)
              SliverToBoxAdapter(
                child: _VehicleDetail(vehicle: selected!, vm: vm),
              )
            else ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 8, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: SectionHeader(
                    title: 'Nearby vehicles',
                    subtitle: vm.referencePoint == null ? 'Enable location for ETAs' : 'ETA from ${vm.referenceLabel}',
                    trailing: vm.userLocation == null ? _ReferencePicker(vm: vm) : null,
                  ),
                ),
              ),
              if (vm.locationAccess != null && vm.locationAccess != LocationAccess.granted && vm.referenceLandmark == null)
                SliverToBoxAdapter(child: _LocationPrompt(vm: vm)),
              if (vm.loading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              else if (vehicles.isEmpty)
                const SliverToBoxAdapter(
                  child: EmptyState(
                    icon: Icons.nights_stay_rounded,
                    title: 'No vehicles on duty',
                    message: 'Vehicles appear here as soon as a driver starts their shift.',
                  ),
                )
              else
                SliverList.separated(
                  itemCount: vehicles.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 2),
                  itemBuilder: (context, i) => _VehicleTile(
                    vehicle: vehicles[i],
                    routeName: vm.routeById(vehicles[i].routeId)?.shortName,
                    driver: vm.driverName(vehicles[i]),
                    onTap: () => onVehicleTap(vehicles[i]),
                  ),
                ),
              if (vm.routes.isNotEmpty) ...[
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(24, 24, 20, 12),
                  sliver: SliverToBoxAdapter(
                    child: SectionHeader(title: 'Routes', subtitle: 'Tap to see stops and live vehicles'),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList.separated(
                    itemCount: vm.routes.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) => RouteCard(
                      route: vm.routes[i],
                      liveCount: vm.vehiclesOnRoute(vm.routes[i].id).length,
                      onTap: () => context.push('${RoutePaths.routeDetail}/${vm.routes[i].id}'),
                    ),
                  ),
                ),
              ],
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

class _VehicleTile extends StatelessWidget {
  const _VehicleTile({required this.vehicle, this.routeName, this.driver, required this.onTap});

  final VehicleModel vehicle;
  final String? routeName;
  final String? driver;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.forVehicle(vehicle.type);
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: SoftIcon(icon: vehicleIcon(vehicle.type), color: color, background: AppColors.softForVehicle(vehicle.type)),
      title: Row(
        children: [
          Text(vehicle.vehicleNumber, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(width: 8),
          if (routeName != null)
            Flexible(
              child: Text(
                routeName!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.muted(context), fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
      subtitle: Text(
        [if (vehicle.distanceMeters != null) formatDistance(vehicle.distanceMeters!), vehicle.type.label, ?driver].join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: EtaBadge(minutes: vehicle.etaMinutes),
    );
  }
}

class _VehicleDetail extends StatelessWidget {
  const _VehicleDetail({required this.vehicle, required this.vm});

  final VehicleModel vehicle;
  final MapViewModel vm;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.forVehicle(vehicle.type);
    final route = vm.routeById(vehicle.routeId);
    final upcoming = vm.upcomingStops(vehicle).take(5).toList();
    final driver = vm.driverName(vehicle);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SoftIcon(
                icon: vehicleIcon(vehicle.type),
                color: color,
                background: AppColors.softForVehicle(vehicle.type),
                size: 56,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(vehicle.vehicleNumber, style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(width: 8),
                        StatusPill(label: vehicle.type == VehicleType.ev ? 'ELECTRIC' : 'BUS', color: AppColors.secondary),
                      ],
                    ),
                    Text(
                      [route?.shortName ?? vehicle.type.label, ?driver].join(' · '),
                      style: TextStyle(color: AppColors.muted(context), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => vm.selectVehicle(null),
                icon: const Icon(Icons.close_rounded),
                style: IconButton.styleFrom(backgroundColor: AppColors.borderOf(context)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              EtaBadge(minutes: vehicle.etaMinutes, large: true),
              const SizedBox(width: 12),
              Expanded(
                child: _Stat(
                  label: 'Distance',
                  value: vehicle.distanceMeters == null ? '—' : formatDistance(vehicle.distanceMeters!),
                ),
              ),
              Expanded(
                child: _Stat(label: 'Updated', value: vehicle.lastUpdated == null ? '—' : timeAgo(vehicle.lastUpdated!)),
              ),
            ],
          ),
          if (upcoming.isNotEmpty) ...[
            const SizedBox(height: 18),
            const SectionHeader(title: 'Upcoming stops'),
            const SizedBox(height: 6),
            StopTimeline(stops: upcoming, color: route == null ? color : AppColors.parseHex(route.color)),
          ],
          if (route != null) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () => context.push('${RoutePaths.routeDetail}/${route.id}'),
              icon: const Icon(Icons.route_rounded),
              label: Text('View full ${route.shortName}'),
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(color: AppColors.muted(context), fontSize: 12, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 2),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
    ],
  );
}

class _LocationPrompt extends StatelessWidget {
  const _LocationPrompt({required this.vm});
  final MapViewModel vm;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.sageSoft.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Icon(Icons.location_off_rounded, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Turn on location to see how far each vehicle is — or pick where you are.',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          TextButton(onPressed: vm.refreshLocation, child: const Text('Enable')),
        ],
      ),
    ),
  );
}

class _ReferencePicker extends StatelessWidget {
  const _ReferencePicker({required this.vm});
  final MapViewModel vm;

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
    tooltip: 'I am at…',
    initialValue: vm.referenceLandmark?.name,
    onSelected: (name) => vm.setReferenceLandmark(CampusLocations.byName(name)),
    itemBuilder: (_) => [for (final l in CampusLocations.all) PopupMenuItem(value: l.name, child: Text(l.name))],
    child: Chip(avatar: const Icon(Icons.place_rounded, size: 16), label: Text(vm.referenceLandmark?.name ?? 'I am at…')),
  );
}
