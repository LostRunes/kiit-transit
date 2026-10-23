import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/user_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../views/auth/login_page.dart';
import '../../views/auth/signup_page.dart';
import '../../views/common/profile_page.dart';
import '../../views/common/splash_page.dart';
import '../../views/driver/dashboard_page.dart';
import '../../views/driver/tracking_page.dart';
import '../../views/driver/vehicle_selection_page.dart';
import '../../views/student/drivers_page.dart';
import '../../views/student/home_page.dart';
import '../../views/student/journey_page.dart';
import '../../views/student/network_route_page.dart';
import '../../views/student/planner_page.dart';
import '../../views/student/live_map_page.dart';
import '../../views/student/map_page.dart';
import '../../views/student/request_page.dart';
import '../../views/student/routes_page.dart';
import '../../views/student/schedule_page.dart';
import '../../views/student/student_shell.dart';
import '../constants/route_paths.dart';
import '../services/journey_planner.dart';

/// Declarative routing with role-based guards: signed-out users only see
/// auth screens, drivers only the driver console, students (and admins,
/// until the Phase 2 dashboard) the student app.
GoRouter createRouter(AuthViewModel auth) => GoRouter(
  initialLocation: RoutePaths.splash,
  refreshListenable: auth,
  redirect: (context, state) {
    final loc = state.matchedLocation;
    final onAuth = loc == RoutePaths.login || loc == RoutePaths.signup;

    // Remember deep links while the session is restored.
    if (auth.status == AuthStatus.unknown) {
      if (loc == RoutePaths.splash) return null;
      return Uri(path: RoutePaths.splash, queryParameters: {'from': state.uri.toString()}).toString();
    }
    if (!auth.isSignedIn) return onAuth ? null : RoutePaths.login;

    final home = homeFor(auth.user!.role);
    if (loc == RoutePaths.splash) {
      final from = state.uri.queryParameters['from'];
      return from == null || from == RoutePaths.splash ? home : from;
    }
    if (onAuth) return home;
    if (loc == RoutePaths.profile) return null;

    final isDriverArea = loc.startsWith(RoutePaths.driverDashboard);
    if (auth.user!.role == UserRole.driver && !isDriverArea) return home;
    if (auth.user!.role != UserRole.driver && isDriverArea) return home;
    return null;
  },
  routes: [
    GoRoute(path: RoutePaths.splash, builder: (_, _) => const SplashPage()),
    GoRoute(path: RoutePaths.login, builder: (_, _) => const LoginPage()),
    GoRoute(path: RoutePaths.signup, builder: (_, _) => const SignupPage()),
    GoRoute(path: RoutePaths.profile, builder: (_, _) => const ProfilePage()),
    GoRoute(path: RoutePaths.studentDrivers, builder: (_, _) => const DriversPage()),
    GoRoute(path: RoutePaths.studentPlanner, builder: (_, _) => const PlannerPage()),
    GoRoute(
      path: RoutePaths.studentJourney,
      builder: (_, state) => JourneyPage(journey: state.extra as Journey?),
    ),
    GoRoute(
      path: '${RoutePaths.networkRoute}/:id',
      builder: (_, state) => NetworkRoutePage(routeId: state.pathParameters['id']!),
    ),
    StatefulShellRoute.indexedStack(
      builder: (_, _, shell) => StudentShell(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [GoRoute(path: RoutePaths.studentHome, builder: (_, _) => const HomePage())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: RoutePaths.studentMap, builder: (_, _) => const LiveMapPage())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: RoutePaths.studentRoutes, builder: (_, _) => const RoutesPage())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: RoutePaths.studentSchedule, builder: (_, _) => const SchedulePage())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: RoutePaths.studentRequest, builder: (_, _) => const RequestPage())],
        ),
      ],
    ),
    GoRoute(
      path: '${RoutePaths.routeDetail}/:id',
      builder: (_, state) => MapPage(routeId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: RoutePaths.driverDashboard,
      builder: (_, _) => const DashboardPage(),
      routes: [
        GoRoute(path: 'vehicles', builder: (_, _) => const VehicleSelectionPage()),
        GoRoute(path: 'tracking', builder: (_, _) => const TrackingPage()),
      ],
    ),
  ],
  errorBuilder: (_, state) => Scaffold(body: Center(child: Text('Page not found: ${state.uri}'))),
);

String homeFor(UserRole role) => role == UserRole.driver ? RoutePaths.driverDashboard : RoutePaths.studentHome;
