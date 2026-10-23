# KIIT Transit — Project Status & Handoff

_Last updated: 2026-10-10_

Use this file to pick the work back up. Setup and architecture details live in [README.md](README.md). The original spec is in `KIIT_Transit_Documentation.pdf` / `KIIT TRANSIT-draft2.pdf`; the two are near-identical.

## Where things stand

The V1 app is built and working in demo mode:
- `flutter analyze` finds no issues.
- `flutter test` passes 11 of 11 tests.
- The web build was clicked through in headless Chrome: login, live map, vehicle detail, route page, schedule, requests, driver directory, and the driver flow (select vehicle → start duty → live broadcast).

| Area | Status |
|---|---|
| Student app: live map, animated markers, EV/bus filter, ETA, upcoming stops | Done |
| Route detail with per-stop ETA | Done |
| Bus schedule (on time / delayed / cancelled, next 5 departures) | Done |
| High-demand requests (aggregated, cooldown) | Done |
| Driver directory with call button | Done |
| Driver app: vehicle selection, duty on/off, GPS broadcast every 4 s (Android foreground service), demand signals | Done |
| Auth: @kiit.ac.in only, role-based routing | Done |
| Demo backend (simulated vehicles, no setup needed) | Done |
| Supabase schema, access rules (RLS), realtime, `submit_demand_request` RPC, seed data | Written; **not yet run against a real project** |
| Android APK build | Not tried yet. About 27 GB is free now (2026-10-10) |
| City-wide network: 38 KIIT campus links + 27 Mo Bus routes, traced on the map | **Done** (2026-10-10). About 2 in 3 Mo Bus stop positions are estimated (see below) |
| Trip planner: from / to / optional via, direct vs 1–2 changes, walking changes, KIIT/Mo Bus filter | **Done** (2026-10-10) |
| Match the Google Stitch design ("Campus Pulse") | **Done** (2026-10-02): theme, all screens, new Home + Routes tabs. Checked in headless Chrome, light and dark |

## Next steps (in order)

1. Run `flutter build apk --debug` or `flutter run` on a phone. Disk space is no longer the blocker.
2. **Check network stop positions.** Open the Routes tab, walk through each Mo Bus route on the map, and fix wrong stops by adding exact coordinates to `FIXED` in [tool/network_data.py](tool/network_data.py). Then run `python tool/build_network.py`. Fix the KIIT campus coordinates (`CAMPUSES`, all except 3, 6 and 15 are estimates) the same way.
3. **Stitch design follow-ups (optional):** the design also has Onboarding, Role Selection, Notifications and Student Profile & Stats screens. They aren't built because they need features V1 doesn't have (push notifications, ride stats). Route colours in `seed_data.dart` / `seed.sql` are still the original bright hues; soften them to the palette if wanted, keeping both files in sync.
4. **Supabase:**
   1. Create a project.
   2. Run [supabase/schema.sql](supabase/schema.sql), then [supabase/seed.sql](supabase/seed.sql).
   3. Enable Email auth.
   4. Run the app with `--dart-define=SUPABASE_URL=… --dart-define=SUPABASE_ANON_KEY=…`.
   5. Promote drivers: `update profiles set role='driver', phone='+91…' where email='…@kiit.ac.in';`
5. **Test on real devices:** two phones, one driver and one student. Check that broadcasting continues with the screen off.
6. **Verify campus coordinates** marked `// approx` in [lib/core/constants/campus_locations.dart](lib/core/constants/campus_locations.dart): Campus 14, 17, 25, Food Court, Queens Hostels. Keep [supabase/seed.sql](supabase/seed.sql) in sync (same stops and IDs as [seed_data.dart](lib/data/datasources/seed_data.dart)).

## Design (Stitch "Campus Pulse")

- Project 6481982968610420949, read through the `stitch` MCP server. The active design system is "Campus Pulse": sage `#2D6957` / `#7CB8A3`, muted teal `#B0EEE8`, peach `#F6B89E`, warm yellow buses. Headlines use Plus Jakarta Sans; body text uses Inter.
- Tokens are in [app_colors.dart](lib/core/theme/app_colors.dart) and [app_theme.dart](lib/core/theme/app_theme.dart). The shared building blocks in [common.dart](lib/widgets/common.dart) are `Pod` (a white 24 px card with a tinted shadow), `SoftIcon` (a duotone icon), `BrandBar`, and a rounded-square `MapFab`.
- Student nav is Home / Map / Routes / Schedule / Request. Drivers is a pushed page at `/student/drivers`, opened from Home. Profile opens from the avatar.

## City-wide network and trip planner

- **Sources.**
  - KIIT campus links come from the student field research at codedex.io: 22 campuses, 38 two-way bus and shuttle links. That research has no timetables because vehicles leave when seats fill (2 to 30+ minutes).
  - The Mo Bus routes come from the CRUT map `MO_BUS_Full_Network_Final_1.pdf`: 27 routes, including 29E. The map has no departure times either.
  - The app shows these facts in place of a schedule. If real Mo Bus timings are found, they can be added later.
- **Data pipeline.** [tool/network_data.py](tool/network_data.py) holds the hand-transcribed stop sequences and is the file to edit. [tool/build_network.py](tool/build_network.py) does the rest:
  1. Geocodes stops with MapTiler, falling back to Nominatim, and caches the results in `tool/geocode_cache.json`.
  2. Drops matches that make a route zigzag.
  3. Interpolates the dropped and unknown stops between their placed neighbours.
  4. Snaps every route to roads with the public OSRM server.
  5. Writes [assets/network/network.json](assets/network/network.json).
- **Accuracy.** Only about 120 of 383 Mo Bus stops were placed by a geocoder or a pinned anchor. The rest sit on a straight line between placed neighbours and are flagged `approx` (the stop sheet says so). Stop order follows the PDF, but positions can be off by a few hundred metres. Large OpenStreetMap queries (Overpass) failed or were skipped. A careful pass with OSM bus-stop data would improve this a lot.
- **Planner.** [journey_planner.dart](lib/core/services/journey_planner.dart) treats every route as two-way and allows up to two changes. A change can include a walk of up to 450 m between nearby stops. Results show direct options first. Times are estimates from road distance: about 21 km/h in the city, 36 km/h beyond 12 km, and slower for KIIT shuttles.
- **Availability per leg.**
  - KIIT: live vehicles of the same type within 700 m of the boarding stop (from the live feed), plus the research note that vehicles leave when full.
  - Mo Bus: the service pattern only, because timings aren't in the source.
- **Screens.**
  - Home → "Plan a trip".
  - Routes tab: KIIT / Mo Bus / Live loops. Each route opens a traced map and its stop list, and any stop can be set as the trip's From or To.
  - Planner → results → a journey map with each leg traced.

## Key facts

- **Keys live in `.env`** (git-ignored). Copy [.env.example](.env.example) to `.env`, fill in `MAPTILER_KEY` (and the Supabase values when ready), then run `flutter run --dart-define-from-file=.env`. `tool/build_network.py` reads the same file. Without a MapTiler key the map falls back to OpenStreetMap tiles. The old key was in the first commit pushed to the public repo, so rotate it in the MapTiler dashboard.
- **Demo logins:** any password of 6+ characters.
  - `driver@kiit.ac.in` opens the driver app.
  - `admin@kiit.ac.in` is an admin.
  - Any other `@kiit.ac.in` address is a student.
- **Demo mode** turns on automatically when the Supabase dart-defines are missing.
- **Stack:** Flutter 3.38, flutter_map 8, supabase_flutter 2, provider, go_router, geolocator, google_fonts.
- **Architecture:** MVVM. Views → ViewModels (ChangeNotifier) → Repositories → `TransitSource` (either `SupabaseSource` or `DemoSource`).

## Known limitations

- Route lines run straight between stops, not along roads. Add intermediate points to `stops` to fix.
- ETA is straight-line distance ÷ 250 m/min, per the V1 spec.
- Out of V1 scope: push notifications, admin dashboard, Google sign-in.
- Vehicles are hidden from students after 2 minutes without an update. Requests expire after 30 minutes.

## Open idea: Cell-ID / tower triangulation (undecided)

- **What:** estimate position from nearby tower IDs (MCC, MNC, LAC/TAC, CID) and signal strength, using a tower database.
- **Feasibility:** Android only, through a native plugin that reads tower info (`TelephonyManager.getAllCellInfo()`). iOS and web don't expose tower data.
- **Accuracy:** roughly 200 m to 2 km, while the campus is about 2 km across. Too coarse for ETAs.
- **Tower data:** OpenCelliD (free API key). Mozilla's location service shut down in 2024.
- **Recommendation:** don't replace GPS. It could be an experimental fallback when GPS is lost, or a separate "tower lab" screen for signal-strength-weighted triangulation experiments.
