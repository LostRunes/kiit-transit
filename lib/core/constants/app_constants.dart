/// App-wide configuration.
///
/// Keys are injected at build time so they never live in source control.
/// Put them in `.env` (copy `.env.example`) and run:
///
///   flutter run --dart-define-from-file=.env
///
/// When they are absent the app runs in **demo mode** with an in-memory
/// backend and simulated vehicles, so the UI can be explored without setup.
class AppConstants {
  AppConstants._();

  static const appName = 'KIIT Transit';
  static const tagline = 'Smart Campus Mobility';

  // Backend
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static bool get isDemoMode => supabaseUrl.isEmpty || supabaseAnonKey.isEmpty;

  // Maps (MapTiler raster tiles on top of OpenStreetMap data). Without a key
  // the map falls back to the standard OpenStreetMap tiles.
  static const mapTilerKey = String.fromEnvironment('MAPTILER_KEY');
  static const userAgentPackageName = 'com.kiit.transit';

  // Auth
  static const allowedEmailDomain = 'kiit.ac.in';
  static const minPasswordLength = 6;

  // Tracking
  /// Average campus speed used by the V1 ETA formula: ~15 km/h.
  static const campusSpeedMetersPerMinute = 250.0;
  static const gpsBroadcastInterval = Duration(seconds: 4);

  /// Vehicles that have not reported within this window are shown as offline.
  static const vehicleStaleAfter = Duration(minutes: 2);

  // Demand requests
  /// A request at the same location is merged into one signal within this window.
  static const requestWindow = Duration(minutes: 30);

  /// Students can re-signal the same spot only after this cooldown.
  static const requestCooldown = Duration(minutes: 5);

  /// Whether students can see driver phone numbers (otherwise admin-only).
  static const showDriverPhonesToStudents = true;
}
