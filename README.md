# KIIT Transit — Smart Campus Mobility

Real-time visibility for KIIT campus buses and EV carts. Drivers' phones broadcast GPS while on duty, and students see every live vehicle on a campus map with ETAs, routes, schedules and demand signals.

Flutter · Supabase (Postgres, Auth, Realtime, RLS) · flutter_map with MapTiler/OpenStreetMap tiles · MVVM with repositories (Provider + GoRouter).

## Run it

```bash
flutter pub get
cp .env.example .env      # then put your MapTiler key in .env

# Demo mode (Supabase values in .env left empty): vehicles are simulated along the seeded routes.
flutter run --dart-define-from-file=.env
```

For live mode, fill in `SUPABASE_URL` and `SUPABASE_ANON_KEY` in `.env` and run the same command.

Keys are kept in `.env`, which git ignores. Never commit it. `tool/build_network.py` reads the same file. Without a MapTiler key the map falls back to plain OpenStreetMap tiles.

Demo logins take any password of 6+ characters. `driver@kiit.ac.in` opens the driver app, `admin@kiit.ac.in` is an admin, and any other `@kiit.ac.in` address is a student. The login screen also has one-tap **Student** / **Driver** buttons.

## Supabase setup

1. Create a project, then run [supabase/schema.sql](supabase/schema.sql) followed by [supabase/seed.sql](supabase/seed.sql) in the SQL editor.
2. Auth → Providers: enable Email. The `handle_new_user` trigger rejects any address outside `kiit.ac.in` on the server, so the restriction does not rely on the app alone.
3. Transport staff sign up like everyone else. Promote them in SQL:
   `update profiles set role = 'driver', phone = '+91…' where email = '…@kiit.ac.in';`
4. Realtime is enabled for `vehicles`, `requests` and `schedules` by the schema script.

Security model (RLS):
- Everyone signed in can read the fleet, routes, schedules and demand signals.
- A driver can claim only a vehicle that nobody else is actively driving, and can update only their own vehicle.
- Demand requests go through the `submit_demand_request` RPC. It merges requests per location within 30 minutes and counts each student once, with a 5-minute cooldown.
- Users can edit only their own name and phone. Roles change only through SQL/admin.

## Features (V1 scope from the spec)

| Feature | Where |
|---|---|
| Student home: nearest vehicle + ETA, quick actions, activity feed | [home_page.dart](lib/views/student/home_page.dart) |
| Live vehicle map, animated markers with heading arrows, EV/bus filters | [live_map_page.dart](lib/views/student/live_map_page.dart), [vehicle_marker.dart](lib/widgets/vehicle_marker.dart) |
| Routes: KIIT campus links, Mo Bus network, live loops; traced route maps | [routes_page.dart](lib/views/student/routes_page.dart), [network_route_page.dart](lib/views/student/network_route_page.dart) |
| Trip planner: from/to/via, direct vs changes, walking transfers | [planner_page.dart](lib/views/student/planner_page.dart), [journey_planner.dart](lib/core/services/journey_planner.dart) |
| Network data (regenerate with `python tool/build_network.py`) | [tool/network_data.py](tool/network_data.py) → [assets/network/network.json](assets/network/network.json) |
| ETA = distance ÷ 250 m/min | [geo_utils.dart](lib/core/utils/geo_utils.dart), [map_viewmodel.dart](lib/viewmodels/map_viewmodel.dart) |
| Upcoming stops inferred from heading | `MapViewModel.upcomingStops` |
| Route polylines + per-stop ETA | [map_page.dart](lib/views/student/map_page.dart) |
| Schedules: next departure, on time / delayed / cancelled, next 5 | [schedule_page.dart](lib/views/student/schedule_page.dart) |
| High-demand requests (aggregated, not booking) | [request_page.dart](lib/views/student/request_page.dart) |
| Driver directory with call button | [drivers_page.dart](lib/views/student/drivers_page.dart) |
| Driver: vehicle selection, duty on/off, GPS broadcast every 4 s, demand signals | [lib/views/driver/](lib/views/driver/), [vehicle_viewmodel.dart](lib/viewmodels/vehicle_viewmodel.dart) |
| KIIT-domain auth, role-based routing | [app_router.dart](lib/core/routing/app_router.dart) |

On Android, driver broadcasting runs as a location **foreground service**, with a persistent "on duty" notification. It keeps working when the screen is off. Vehicles that have not reported for 2 minutes disappear from the student map.

## Project layout

```
lib/
  core/        constants (campus landmarks, config), theme, utils (ETA, geo), services, routing
  data/        models, datasources (supabase_source, demo_source, location_source), repositories
  viewmodels/  auth, map, vehicle (driver), route (schedules), request
  views/       auth/, student/, driver/, common/
  widgets/     campus_map, vehicle_marker, eta_widget, route_card, request_card, common
supabase/      schema.sql, seed.sql
```

## Known limitations

- Landmarks tagged `// approx` in [campus_locations.dart](lib/core/constants/campus_locations.dart) were placed by hand. Verify them on site, then update `seed.sql` to match.
- Route polylines connect stops with straight lines instead of following roads. Add intermediate points to `stops` for road-accurate lines.
- The ETA is straight-line distance ÷ average speed, as specified for V1. Road-network and ML ETAs are Phase 3.
- Push notifications, the admin dashboard and Google sign-in are out of V1 scope.

## Tests

```bash
flutter analyze
flutter test
```
