import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/formatters.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 56, this.onDark = false});

  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: onDark ? Colors.white : AppColors.primary,
      borderRadius: BorderRadius.circular(size * 0.3),
      boxShadow: [
        BoxShadow(color: AppColors.primary.withValues(alpha: 0.22), blurRadius: size * 0.4, offset: Offset(0, size * 0.14)),
      ],
    ),
    child: Icon(Icons.directions_bus_rounded, size: size * 0.5, color: onDark ? AppColors.primary : Colors.white),
  );
}

/// White rounded "pod" card with the soft tinted shadow from the design.
class Pod extends StatelessWidget {
  const Pod({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 24,
    this.color,
    this.onTap,
    this.raised = false,
    this.border,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final VoidCallback? onTap;
  final bool raised;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shape = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: shape,
        boxShadow: isDark || color != null ? null : AppColors.podShadow(raised: raised),
      ),
      child: Material(
        color: color ?? Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: shape,
          side: isDark && color == null ? const BorderSide(color: AppColors.darkBorder) : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: padding,
            decoration: border == null ? null : BoxDecoration(border: border, borderRadius: shape),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Duotone icon: coloured glyph on a 15% tint of the same colour.
class SoftIcon extends StatelessWidget {
  const SoftIcon({super.key, required this.icon, required this.color, this.size = 48, this.background, this.circle = true});

  final IconData icon;
  final Color color;
  final double size;
  final Color? background;
  final bool circle;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: background ?? color.withValues(alpha: 0.15),
      shape: circle ? BoxShape.circle : BoxShape.rectangle,
      borderRadius: circle ? null : BorderRadius.circular(size * 0.3),
    ),
    child: Icon(icon, color: color, size: size * 0.5),
  );
}

/// Top bar used across the app: brand title on the left, actions on the right.
class BrandBar extends StatelessWidget implements PreferredSizeWidget {
  const BrandBar({super.key, this.title = 'KIIT Transit', this.actions = const [], this.leading});

  final String title;
  final List<Widget> actions;
  final Widget? leading;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) => AppBar(
    toolbarHeight: 64,
    leading: leading,
    titleSpacing: leading == null ? 24 : 4,
    title: Text(title),
    actions: [...actions, const SizedBox(width: 12)],
  );
}

/// Small coloured pill: "On time", "Delayed", "Live"...
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.color, this.icon, this.solid = false});

  final String label;
  final Color color;
  final IconData? icon;
  final bool solid;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: solid ? color : color.withValues(alpha: isDark ? 0.22 : 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 13, color: solid ? Colors.white : color), const SizedBox(width: 4)],
          Text(
            label,
            style: TextStyle(
              color: solid ? Colors.white : color,
              fontWeight: FontWeight.w700,
              fontSize: 11.5,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Blinking dot used to signal live data.
class LiveDot extends StatefulWidget {
  const LiveDot({super.key, this.color = AppColors.live, this.size = 8});
  final Color color;
  final double size;

  @override
  State<LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<LiveDot> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: Tween(begin: 0.35, end: 1.0).animate(_c),
    child: Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
    ),
  );
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.trailing, this.subtitle});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20)),
            if (subtitle != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(subtitle!, style: TextStyle(color: AppColors.muted(context), fontSize: 13)),
              ),
          ],
        ),
      ),
      ?trailing,
    ],
  );
}

class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.name, this.radius = 20, this.color});

  final String name;
  final double radius;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.sage, width: 2),
      ),
      child: CircleAvatar(
        radius: radius - 2,
        backgroundColor: AppColors.sageSoft,
        child: Text(
          initials(name),
          style: TextStyle(color: c, fontWeight: FontWeight.w800, fontSize: radius * 0.66),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.message, this.action});

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: AppColors.sageSoft, shape: BoxShape.circle),
          child: Icon(icon, size: 34, color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        if (message != null) ...[
          const SizedBox(height: 6),
          Text(
            message!,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted(context)),
          ),
        ],
        if (action != null) ...[const SizedBox(height: 16), action!],
      ],
    ),
  );
}

/// Rounded-square floating button used over maps.
class MapFab extends StatelessWidget {
  const MapFab({super.key, required this.icon, required this.onPressed, this.tooltip, this.active = false});

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), boxShadow: AppColors.podShadow(raised: true)),
      child: Material(
        color: active ? scheme.primary : scheme.surface,
        borderRadius: BorderRadius.circular(18),
        child: IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          iconSize: 24,
          constraints: const BoxConstraints.tightFor(width: 56, height: 56),
          icon: Icon(icon, color: active ? scheme.onPrimary : scheme.primary),
        ),
      ),
    );
  }
}

/// Banner shown when demo mode is active.
class DemoBanner extends StatelessWidget {
  const DemoBanner({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: compact ? 6 : 10),
    decoration: BoxDecoration(color: AppColors.peachSoft, borderRadius: BorderRadius.circular(16)),
    child: Row(
      children: [
        const Icon(Icons.science_rounded, size: 18, color: AppColors.tertiary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            compact
                ? 'Demo mode — simulated vehicles'
                : 'Demo mode: Supabase is not configured, so vehicles are simulated. '
                      'Sign in with any @kiit.ac.in email; use driver@kiit.ac.in for the driver app.',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.tertiary),
          ),
        ),
      ],
    ),
  );
}
