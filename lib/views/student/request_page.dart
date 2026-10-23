import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/campus_locations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../viewmodels/map_viewmodel.dart';
import '../../viewmodels/request_viewmodel.dart';
import '../../widgets/common.dart';
import '../../widgets/request_card.dart';

/// High-demand request: tell nearby drivers a crowd is waiting. Not a booking.
class RequestPage extends StatefulWidget {
  const RequestPage({super.key});

  @override
  State<RequestPage> createState() => _RequestPageState();
}

class _RequestPageState extends State<RequestPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RequestViewModel>().suggestFrom(context.read<MapViewModel>().userLocation);
    });
  }

  Future<void> _submit() async {
    final vm = context.read<RequestViewModel>();
    final ok = await vm.submit();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Signal sent. Nearby drivers can now see you are waiting.' : vm.error ?? 'Could not send.'),
        backgroundColor: ok ? AppColors.primary : AppColors.cancelled,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RequestViewModel>();
    final selected = vm.selectedLandmark;
    final existing = selected == null ? null : vm.requestAt(selected.name);
    final justSent = vm.lastSubmittedAt != null && DateTime.now().difference(vm.lastSubmittedAt!).inMinutes < 5;

    return Scaffold(
      appBar: const BrandBar(title: 'Request EV'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Pod(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
            raised: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SoftIcon(icon: Icons.campaign_rounded, color: AppColors.tertiary, background: AppColors.peachSoft),
                    const SizedBox(width: 12),
                    Text(
                      'Demand Signal',
                      style: TextStyle(color: AppColors.tertiary, fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Need a ride nearby?', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  'Signal where you are. Requests are grouped by location, and nearby drivers see how many students are waiting.',
                  style: TextStyle(color: AppColors.muted(context), fontSize: 15, height: 1.5),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: AppColors.teal, borderRadius: BorderRadius.circular(999)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const LiveDot(color: AppColors.onTeal, size: 8),
                      const SizedBox(width: 8),
                      Text(
                        '${vm.totalWaiting} students waiting on campus',
                        style: const TextStyle(color: AppColors.onTeal, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: 'Where are you waiting?'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final l in CampusLocations.all)
                ChoiceChip(
                  avatar: Icon(l.type.icon, size: 16),
                  label: Text(l.name),
                  selected: selected == l,
                  showCheckmark: false,
                  onSelected: (_) => vm.selectLandmark(l),
                ),
            ],
          ),
          const SizedBox(height: 18),
          if (existing != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '${existing.studentCount} ${existing.studentCount == 1 ? 'student is' : 'students are'} already waiting at ${existing.locationName}. Your signal adds to the count.',
                style: TextStyle(color: AppColors.muted(context), fontWeight: FontWeight.w600),
              ),
            ),
          FilledButton.icon(
            onPressed: vm.submitting || selected == null ? null : _submit,
            style: FilledButton.styleFrom(backgroundColor: AppColors.sage, foregroundColor: AppColors.onSage),
            icon: vm.submitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4))
                : const Icon(Icons.send_rounded),
            label: Text(selected == null ? 'Choose a location' : 'Signal demand at ${selected.name}'),
          ),
          if (justSent) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.onTime, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Sent from ${vm.lastSubmittedLocation} ${timeAgo(vm.lastSubmittedAt!)}',
                    style: const TextStyle(color: AppColors.onTime, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'This is not a booking — drivers choose whether to serve a location.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted(context), fontSize: 12),
          ),
          const SizedBox(height: 24),
          SectionHeader(title: 'Active signals', subtitle: 'Requests expire after 30 minutes'),
          const SizedBox(height: 10),
          if (vm.requests.isEmpty)
            const EmptyState(icon: Icons.sentiment_satisfied_rounded, title: 'Nobody is stranded right now')
          else
            for (final r in vm.requests) ...[
              RequestCard(request: r, onTap: () => vm.selectLandmark(CampusLocations.byName(r.locationName))),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}
