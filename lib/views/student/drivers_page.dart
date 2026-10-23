import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/driver_contact.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/vehicle_repository.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/common.dart';
import '../../widgets/vehicle_marker.dart';

/// Directory of transport staff and their vehicles.
class DriversPage extends StatefulWidget {
  const DriversPage({super.key});

  @override
  State<DriversPage> createState() => _DriversPageState();
}

class _DriversPageState extends State<DriversPage> {
  late Future<List<DriverContact>> _future = _load();
  String _query = '';

  Future<List<DriverContact>> _load() => context.read<VehicleRepository>().fetchDrivers();

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (!await launchUrl(uri) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open the dialer for $phone')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthViewModel>().user?.role;
    final canSeePhones = AppConstants.showDriverPhonesToStudents || role == UserRole.admin;

    return Scaffold(
      appBar: AppBar(title: const Text('Driver Directory')),
      body: FutureBuilder<List<DriverContact>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return EmptyState(
              icon: Icons.cloud_off_rounded,
              title: 'Could not load drivers',
              action: FilledButton.tonal(onPressed: _refresh, child: const Text('Retry')),
            );
          }
          final q = _query.toLowerCase();
          final drivers =
              (snap.data ?? const [])
                  .where(
                    (d) =>
                        q.isEmpty ||
                        d.name.toLowerCase().contains(q) ||
                        (d.vehicle?.vehicleNumber.toLowerCase().contains(q) ?? false),
                  )
                  .toList()
                ..sort((a, b) => (b.isOnDuty ? 1 : 0) - (a.isOnDuty ? 1 : 0));

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: const InputDecoration(
                    hintText: 'Search driver or vehicle (e.g. EV-03)',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
                const SizedBox(height: 14),
                if (drivers.isEmpty)
                  const EmptyState(icon: Icons.person_search_rounded, title: 'No drivers found')
                else
                  Column(
                    children: [
                      for (var i = 0; i < drivers.length; i++) ...[
                        if (i > 0) const SizedBox(height: 12),
                        Pod(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: _DriverTile(
                            driver: drivers[i],
                            showPhone: canSeePhones,
                            onCall: drivers[i].phone == null ? null : () => _call(drivers[i].phone!),
                          ),
                        ),
                      ],
                    ],
                  ),
                const SizedBox(height: 14),
                Text(
                  'Use this to report an issue or reach a specific driver. Please call only when needed — drivers may be on the road.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted(context), fontSize: 12),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DriverTile extends StatelessWidget {
  const _DriverTile({required this.driver, required this.showPhone, this.onCall});

  final DriverContact driver;
  final bool showPhone;
  final VoidCallback? onCall;

  @override
  Widget build(BuildContext context) {
    final v = driver.vehicle;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          UserAvatar(name: driver.name, radius: 22, color: AppColors.secondary),
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: 13,
              height: 13,
              decoration: BoxDecoration(
                color: driver.isOnDuty ? AppColors.onTime : AppColors.offline,
                shape: BoxShape.circle,
                border: Border.all(color: Theme.of(context).colorScheme.surface, width: 2),
              ),
            ),
          ),
        ],
      ),
      title: Text(driver.name, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            if (v != null) ...[
              Icon(vehicleIcon(v.type), size: 15, color: AppColors.forVehicle(v.type)),
              const SizedBox(width: 4),
              Text(v.vehicleNumber, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                driver.isOnDuty ? 'On duty' : (v == null ? 'No vehicle assigned' : 'Off duty'),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: driver.isOnDuty ? AppColors.onTime : AppColors.muted(context)),
              ),
            ),
          ],
        ),
      ),
      trailing: showPhone && onCall != null
          ? IconButton.filled(
              onPressed: onCall,
              style: IconButton.styleFrom(backgroundColor: AppColors.sageSoft, foregroundColor: AppColors.primary),
              icon: const Icon(Icons.call_rounded),
              tooltip: driver.phone,
            )
          : null,
    );
  }
}
