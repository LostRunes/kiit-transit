import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/formatters.dart';
import '../data/models/request_model.dart';
import 'campus_map.dart';
import 'common.dart';

/// Demand signal card: "12 students waiting at Campus 14".
class RequestCard extends StatelessWidget {
  const RequestCard({super.key, required this.request, this.distanceMeters, this.onServe, this.onTap});

  final RequestModel request;
  final double? distanceMeters;
  final VoidCallback? onServe;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = DemandLayer.colorFor(request);
    return Pod(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(16, 16, 10, 16),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(18)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${request.studentCount}',
                  style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 19, height: 1),
                ),
                Icon(Icons.groups_rounded, size: 15, color: color),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(request.locationName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 3),
                Text(
                  [
                    '${request.studentCount} ${request.studentCount == 1 ? 'student' : 'students'} waiting',
                    if (distanceMeters != null && distanceMeters! > 0) formatDistance(distanceMeters!),
                    'since ${timeAgo(request.createdAt)}',
                  ].join(' · '),
                  style: TextStyle(color: AppColors.muted(context), fontSize: 12.5),
                ),
              ],
            ),
          ),
          if (onServe != null) TextButton(onPressed: onServe, child: const Text('Served')),
        ],
      ),
    );
  }
}
