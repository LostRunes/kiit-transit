-- KIIT Transit — reference data. Mirrors lib/data/datasources/seed_data.dart
-- (same IDs) so the app shows the same network in demo and live mode.

insert into public.routes (id, route_name, route_type, color, is_loop, stops) values
('a0000000-0000-4000-8000-000000000001', 'Route A -- Hostels to Campus 15', 'ev', '#10B981', false, '[
  {"name":"KP-8","lat":20.35959,"lng":85.82411},
  {"name":"KP-15","lat":20.35613,"lng":85.82061},
  {"name":"KP-5","lat":20.35638,"lng":85.81994},
  {"name":"Campus 6 (Main)","lat":20.35307,"lng":85.82015},
  {"name":"Food Court","lat":20.35480,"lng":85.81880},
  {"name":"Central Library","lat":20.35428,"lng":85.81618},
  {"name":"Campus 3","lat":20.35324,"lng":85.81712},
  {"name":"KP-7","lat":20.35113,"lng":85.81706},
  {"name":"KP-6","lat":20.34891,"lng":85.81609},
  {"name":"Campus 15","lat":20.34821,"lng":85.81595}]'),
('a0000000-0000-4000-8000-000000000002', 'Route B -- Campus 25 Express', 'bus', '#F59E0B', false, '[
  {"name":"Campus 25","lat":20.36450,"lng":85.81700},
  {"name":"Queens Hostels","lat":20.36100,"lng":85.81900},
  {"name":"Cricket Ground","lat":20.35735,"lng":85.81782},
  {"name":"Campus 14","lat":20.35590,"lng":85.81560},
  {"name":"Central Library","lat":20.35428,"lng":85.81618},
  {"name":"KIIT Square Gate","lat":20.35393,"lng":85.81560},
  {"name":"Campus 15","lat":20.34821,"lng":85.81595}]'),
('a0000000-0000-4000-8000-000000000003', 'Route C -- Day Scholar Shuttle', 'bus', '#3B82F6', false, '[
  {"name":"Patia Day Scholar Pickup","lat":20.35491,"lng":85.82933},
  {"name":"KP-8","lat":20.35959,"lng":85.82411},
  {"name":"KP-15","lat":20.35613,"lng":85.82061},
  {"name":"Campus 6 (Main)","lat":20.35307,"lng":85.82015},
  {"name":"Campus 17","lat":20.34960,"lng":85.81950},
  {"name":"Campus 15","lat":20.34821,"lng":85.81595}]'),
('a0000000-0000-4000-8000-000000000004', 'Route D -- Campus Loop', 'ev', '#8B5CF6', true, '[
  {"name":"Campus 6 (Main)","lat":20.35307,"lng":85.82015},
  {"name":"Campus 17","lat":20.34960,"lng":85.81950},
  {"name":"KP-7","lat":20.35113,"lng":85.81706},
  {"name":"Campus 3","lat":20.35324,"lng":85.81712},
  {"name":"Central Library","lat":20.35428,"lng":85.81618},
  {"name":"Campus 14","lat":20.35590,"lng":85.81560},
  {"name":"KP-5","lat":20.35638,"lng":85.81994},
  {"name":"KP-15","lat":20.35613,"lng":85.82061}]')
on conflict (id) do update set
  route_name = excluded.route_name, route_type = excluded.route_type,
  color = excluded.color, is_loop = excluded.is_loop, stops = excluded.stops;

insert into public.vehicles (id, vehicle_number, vehicle_type, route_id, status) values
('b0000000-0000-4000-8000-000000000001', 'EV-01',  'ev',  'a0000000-0000-4000-8000-000000000001', 'offline'),
('b0000000-0000-4000-8000-000000000002', 'EV-02',  'ev',  'a0000000-0000-4000-8000-000000000001', 'offline'),
('b0000000-0000-4000-8000-000000000003', 'EV-03',  'ev',  'a0000000-0000-4000-8000-000000000004', 'offline'),
('b0000000-0000-4000-8000-000000000004', 'EV-04',  'ev',  'a0000000-0000-4000-8000-000000000004', 'offline'),
('b0000000-0000-4000-8000-000000000005', 'BUS-01', 'bus', 'a0000000-0000-4000-8000-000000000002', 'offline'),
('b0000000-0000-4000-8000-000000000006', 'BUS-02', 'bus', 'a0000000-0000-4000-8000-000000000003', 'offline'),
('b0000000-0000-4000-8000-000000000007', 'BUS-03', 'bus', 'a0000000-0000-4000-8000-000000000002', 'offline'),
('b0000000-0000-4000-8000-000000000008', 'EV-05',  'ev',  'a0000000-0000-4000-8000-000000000001', 'offline')
on conflict (id) do nothing;

-- Timetables: Route B every 30 min 07:30–20:00 (25 min trip),
--             Route C every 45 min 07:00–19:30 (30 min trip).
delete from public.schedules
 where route_id in ('a0000000-0000-4000-8000-000000000002', 'a0000000-0000-4000-8000-000000000003');

insert into public.schedules (route_id, departure_time, arrival_time)
select 'a0000000-0000-4000-8000-000000000002', t::time, (t + interval '25 minutes')::time
  from generate_series('2000-01-01 07:30'::timestamp, '2000-01-01 20:00', interval '30 minutes') t;

insert into public.schedules (route_id, departure_time, arrival_time)
select 'a0000000-0000-4000-8000-000000000003', t::time, (t + interval '30 minutes')::time
  from generate_series('2000-01-01 07:00'::timestamp, '2000-01-01 19:30', interval '45 minutes') t;

-- Promote transport staff after they sign up with their KIIT email:
-- update public.profiles set role = 'driver', phone = '+91XXXXXXXXXX' where email = 'driver.name@kiit.ac.in';
-- update public.profiles set role = 'admin' where email = 'transport.office@kiit.ac.in';
