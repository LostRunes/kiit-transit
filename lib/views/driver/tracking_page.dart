import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../viewmodels/request_viewmodel.dart';
import '../../viewmodels/vehicle_viewmodel.dart';
import '../../widgets/campus_map.dart';
import '../../widgets/common.dart';
import '../../widgets/vehicle_marker.dart';

/// Active duty screen: follows the driver's own position while broadcasting.
class TrackingPage extends StatefulWidget {
  const TrackingPage({super.key});

  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  final _map = MapController();
  bool _follow = true;
  bool _mapReady = false;

  Future<void> _endDuty() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End duty?'),
        content: const Text('Students will stop seeing your vehicle on the map.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep driving')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger, minimumSize: const Size(0, 48)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('End duty'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await context.read<VehicleViewModel>().stopDuty();
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<VehicleViewModel>();
    final requests = context.watch<RequestViewModel>().requests;
    final vehicle = vm.myVehicle;
    final fix = vm.lastFix;

    if (_follow && _mapReady && fix != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _map.move(fix.position, _map.camera.zoom);
      });
    }

    final sentAgo = vm.lastSentAt == null ? null : DateTime.now().difference(vm.lastSentAt!);
    final healthy = vm.onDuty && sentAgo != null && sentAgo < AppConstants.gpsBroadcastInterval * 3;

    return PopScope(
      canPop: true,
      child: Scaffold(
        body: Stack(
          children: [
            FlutterMapReadyListener(
              onReady: () => setState(() => _mapReady = true),
              child: CampusMap(
                controller: _map,
                initialCenter: fix?.position,
                initialZoom: 17,
                showLandmarks: true,
                children: [
                  DemandLayer(requests: requests),
                  if (fix != null && vehicle != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: fix.position,
                          width: VehicleMarkerIcon.size + 24,
                          height: VehicleMarkerIcon.size + 22,
                          alignment: const Alignment(0, 0.25),
                          child: VehicleMarkerIcon(
                            type: vehicle.type,
                            heading: fix.heading,
                            label: vehicle.vehicleNumber,
                            selected: true,
                          ),
                        ),
                      ],
                    ),
                ],
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
                      child: Material(
                        color: healthy ? AppColors.primary : (vm.onDuty ? AppColors.delayed : AppColors.offline),
                        borderRadius: BorderRadius.circular(18),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              if (vm.onDuty)
                                const LiveDot(color: Colors.white, size: 9)
                              else
                                const Icon(Icons.pause_circle, color: Colors.white),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  !vm.onDuty
                                      ? 'Not broadcasting'
                                      : healthy
                                      ? 'Broadcasting ${vehicle?.vehicleNumber ?? ''} live'
                                      : (fix == null ? 'Waiting for GPS fix…' : 'Weak connection — retrying'),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 16,
              bottom: 300,
              child: MapFab(
                icon: _follow ? Icons.gps_fixed_rounded : Icons.gps_not_fixed_rounded,
                active: _follow,
                tooltip: 'Follow my position',
                onPressed: () => setState(() => _follow = !_follow),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: AppColors.podShadow(raised: true),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          _Stat(label: 'Speed', value: fix == null ? '—' : '${(fix.speed * 3.6).round()} km/h'),
                          _Stat(label: 'Accuracy', value: fix == null ? '—' : '±${fix.accuracy.round()} m'),
                          _Stat(label: 'Last sent', value: vm.lastSentAt == null ? '—' : timeAgo(vm.lastSentAt!)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _Stat(label: 'Updates', value: '${vm.updatesSent}'),
                          _Stat(label: 'Distance', value: formatDistance(vm.distanceCoveredMeters)),
                          _Stat(label: 'Waiting', value: '${requests.fold<int>(0, (s, r) => s + r.studentCount)} students'),
                        ],
                      ),
                      if (vm.failedUpdates > 0) ...[
                        const SizedBox(height: 8),
                        Text(
                          '${vm.failedUpdates} updates failed — will keep retrying',
                          style: const TextStyle(color: AppColors.delayed, fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                      ],
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.danger,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(60),
                        ),
                        onPressed: vm.onDuty ? _endDuty : () => Navigator.of(context).maybePop(),
                        icon: Icon(vm.onDuty ? Icons.power_settings_new_rounded : Icons.arrow_back_rounded),
                        label: Text(vm.onDuty ? 'END DUTY' : 'Back to dashboard', style: const TextStyle(letterSpacing: 1.2)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Calls [onReady] after the first frame so the MapController can be used.
class FlutterMapReadyListener extends StatefulWidget {
  const FlutterMapReadyListener({super.key, required this.child, required this.onReady});
  final Widget child;
  final VoidCallback onReady;

  @override
  State<FlutterMapReadyListener> createState() => _FlutterMapReadyListenerState();
}

class _FlutterMapReadyListenerState extends State<FlutterMapReadyListener> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onReady());
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: AppColors.muted(context), fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Theme.of(context).colorScheme.primary),
        ),
      ],
    ),
  );
}
