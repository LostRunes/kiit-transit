import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/formatters.dart';

/// ETA pill, e.g. "3 min". Turns urgent green when the vehicle is close.
class EtaBadge extends StatelessWidget {
  const EtaBadge({super.key, required this.minutes, this.large = false});

  final int? minutes;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final m = minutes;
    final arriving = m != null && m <= 1;
    final color = m == null ? AppColors.offline : (m <= 3 ? AppColors.onTime : AppColors.secondary);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = arriving ? Colors.white : (isDark && color == AppColors.secondary ? Colors.white : color);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: large ? 14 : 10, vertical: large ? 8 : 5),
      decoration: BoxDecoration(
        color: arriving ? AppColors.onTime : color.withValues(alpha: isDark ? 0.25 : 0.1),
        borderRadius: BorderRadius.circular(large ? 14 : 10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            m == null ? '—' : formatEta(m),
            style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: large ? 20 : 13, height: 1.1),
          ),
          if (large && m != null && !arriving)
            Text(
              'away',
              style: TextStyle(color: fg.withValues(alpha: 0.8), fontSize: 11, fontWeight: FontWeight.w600),
            ),
        ],
      ),
    );
  }
}
