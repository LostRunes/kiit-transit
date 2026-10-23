import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/vehicle_model.dart';
import '../../viewmodels/vehicle_viewmodel.dart';
import '../../widgets/common.dart';
import '../../widgets/vehicle_marker.dart';

class VehicleSelectionPage extends StatelessWidget {
  const VehicleSelectionPage({super.key});

  Future<void> _claim(BuildContext context, VehicleModel v) async {
    final vm = context.read<VehicleViewModel>();
    if (vm.onDuty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('End your current duty before switching vehicles.')));
      return;
    }
    if (await vm.claim(v)) {
      if (context.mounted) context.pop();
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(vm.error ?? 'Could not select vehicle')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<VehicleViewModel>();
    final mine = vm.myVehicle;
    final groups = {
      VehicleType.ev: vm.vehicles.where((v) => v.type == VehicleType.ev).toList(),
      VehicleType.bus: vm.vehicles.where((v) => v.type == VehicleType.bus).toList(),
    };

    return Scaffold(
      appBar: const BrandBar(title: 'KIIT Transit Driver'),
      body: vm.loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                Text('Select Your Vehicle', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 6),
                Text(
                  'Choose the vehicle you are operating today. Students see it on the map once you start duty.',
                  style: TextStyle(color: AppColors.muted(context), fontSize: 15, height: 1.4),
                ),
                for (final entry in groups.entries)
                  if (entry.value.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    SectionHeader(title: entry.key == VehicleType.ev ? 'EV carts' : 'Buses'),
                    const SizedBox(height: 12),
                    for (final v in entry.value) ...[
                      _VehicleTile(
                        vehicle: v,
                        selected: mine?.id == v.id,
                        taken: vm.isTaken(v),
                        onTap: vm.busy ? null : () => _claim(context, v),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
              ],
            ),
    );
  }
}

class _VehicleTile extends StatelessWidget {
  const _VehicleTile({required this.vehicle, required this.selected, required this.taken, this.onTap});

  final VehicleModel vehicle;
  final bool selected;
  final bool taken;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.forVehicle(vehicle.type);
    return Opacity(
      opacity: taken ? 0.5 : 1,
      child: Pod(
        raised: selected,
        onTap: taken ? null : onTap,
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        border: selected ? Border.all(color: AppColors.sage, width: 2) : null,
        child: Row(
          children: [
            SoftIcon(
              icon: vehicleIcon(vehicle.type),
              color: selected ? AppColors.onTeal : AppColors.muted(context),
              background: selected ? AppColors.teal : AppColors.fieldOf(context),
              size: 72,
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(vehicle.vehicleNumber, style: Theme.of(context).textTheme.titleLarge),
                  Text(
                    vehicle.type == VehicleType.ev ? 'Electric cart' : 'Campus bus',
                    style: TextStyle(color: AppColors.muted(context)),
                  ),
                  const SizedBox(height: 8),
                  StatusPill(
                    label: taken ? 'In use' : (selected ? 'Yours' : 'Available'),
                    color: taken ? AppColors.offline : (selected ? color : AppColors.secondary),
                    icon: Icons.circle,
                  ),
                ],
              ),
            ),
            if (selected) const Icon(Icons.check_circle_outline_rounded, color: AppColors.primary, size: 28),
          ],
        ),
      ),
    );
  }
}
