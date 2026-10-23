import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/app_constants.dart';
import 'core/routing/app_router.dart';
import 'core/services/location_service.dart';
import 'core/theme/app_theme.dart';
import 'data/datasources/demo_source.dart';
import 'data/datasources/location_source.dart';
import 'data/datasources/supabase_source.dart';
import 'data/datasources/transit_source.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/network_repository.dart';
import 'data/repositories/request_repository.dart';
import 'data/repositories/route_repository.dart';
import 'data/repositories/vehicle_repository.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/map_viewmodel.dart';
import 'viewmodels/network_viewmodel.dart';
import 'viewmodels/request_viewmodel.dart';
import 'viewmodels/route_viewmodel.dart';
import 'viewmodels/vehicle_viewmodel.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarColor: Colors.transparent));

  // Each font weight is a separate download; fetch them before the first
  // frame so text is not laid out with a fallback font (cached afterwards).
  try {
    await GoogleFonts.pendingFonts([
      for (final w in [FontWeight.w400, FontWeight.w500, FontWeight.w600, FontWeight.w700, FontWeight.w800, FontWeight.w900])
        GoogleFonts.plusJakartaSans(fontWeight: w),
    ]).timeout(const Duration(seconds: 4));
  } catch (_) {
    // Offline or slow network: continue with the fallback font.
  }

  final TransitSource source;
  if (AppConstants.isDemoMode) {
    source = DemoSource();
  } else {
    await Supabase.initialize(url: AppConstants.supabaseUrl, publishableKey: AppConstants.supabaseAnonKey);
    source = SupabaseSource(Supabase.instance.client);
  }

  runApp(KiitTransitApp(source: source));
}

class KiitTransitApp extends StatefulWidget {
  const KiitTransitApp({super.key, required this.source});

  final TransitSource source;

  @override
  State<KiitTransitApp> createState() => _KiitTransitAppState();
}

class _KiitTransitAppState extends State<KiitTransitApp> {
  late final authRepo = AuthRepository(widget.source);
  late final vehicleRepo = VehicleRepository(widget.source);
  late final routeRepo = RouteRepository(widget.source);
  late final requestRepo = RequestRepository(widget.source);
  late final networkRepo = NetworkRepository();
  late final location = LocationSource(LocationService());
  late final auth = AuthViewModel(authRepo);
  late final GoRouter router = createRouter(auth);

  @override
  void dispose() {
    router.dispose();
    widget.source.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      Provider.value(value: authRepo),
      Provider.value(value: vehicleRepo),
      Provider.value(value: routeRepo),
      Provider.value(value: requestRepo),
      Provider.value(value: location),
      ChangeNotifierProvider.value(value: auth),
      ChangeNotifierProvider(create: (_) => MapViewModel(vehicleRepo, routeRepo, location)),
      ChangeNotifierProvider(create: (_) => RouteViewModel(routeRepo)),
      ChangeNotifierProvider(create: (_) => RequestViewModel(requestRepo)),
      ChangeNotifierProvider(create: (_) => NetworkViewModel(networkRepo)),
      ChangeNotifierProvider(create: (_) => VehicleViewModel(vehicleRepo, authRepo, location)),
    ],
    child: MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: router,
    ),
  );
}
