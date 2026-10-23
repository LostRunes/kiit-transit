import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../viewmodels/map_viewmodel.dart';
import '../../viewmodels/request_viewmodel.dart';
import '../../viewmodels/route_viewmodel.dart';

/// Bottom navigation for the student app. Starts the shared live streams
/// once so every tab sees the same data.
class StudentShell extends StatefulWidget {
  const StudentShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  @override
  void initState() {
    super.initState();
    context.read<MapViewModel>().start();
    context.read<RouteViewModel>().start();
    context.read<RequestViewModel>().start();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: widget.shell,
    bottomNavigationBar: DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, -6))],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: NavigationBar(
          selectedIndex: widget.shell.currentIndex,
          onDestinationSelected: (i) => widget.shell.goBranch(i, initialLocation: i == widget.shell.currentIndex),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map_rounded), label: 'Map'),
            NavigationDestination(
              icon: Icon(Icons.directions_bus_outlined),
              selectedIcon: Icon(Icons.directions_bus_rounded),
              label: 'Routes',
            ),
            NavigationDestination(
              icon: Icon(Icons.schedule_outlined),
              selectedIcon: Icon(Icons.schedule_rounded),
              label: 'Schedule',
            ),
            NavigationDestination(
              icon: Icon(Icons.electric_rickshaw_outlined),
              selectedIcon: Icon(Icons.electric_rickshaw_rounded),
              label: 'Request',
            ),
          ],
        ),
      ),
    ),
  );
}
