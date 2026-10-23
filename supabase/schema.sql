-- KIIT Transit — Supabase schema (V1)
-- Run in the Supabase SQL editor, then run seed.sql.

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------- tables

create table if not exists public.profiles (
  id          uuid primary key references auth.users (id) on delete cascade,
  name        text not null default '',
  email       text not null unique,
  role        text not null default 'student' check (role in ('student', 'driver', 'admin')),
  phone       text,
  created_at  timestamptz not null default now()
);

create table if not exists public.routes (
  id          uuid primary key default gen_random_uuid(),
  route_name  text not null,
  route_type  text not null default 'bus' check (route_type in ('ev', 'bus')),
  color       text,
  is_loop     boolean not null default false,
  stops       jsonb not null default '[]'::jsonb   -- [{name, lat, lng}, ...] in order
);

create table if not exists public.vehicles (
  id              uuid primary key default gen_random_uuid(),
  vehicle_number  text not null unique,
  vehicle_type    text not null check (vehicle_type in ('ev', 'bus')),
  driver_id       uuid references public.profiles (id) on delete set null,
  route_id        uuid references public.routes (id) on delete set null,
  latitude        float8,
  longitude       float8,
  heading         float4 not null default 0,
  status          text not null default 'offline' check (status in ('active', 'idle', 'offline')),
  last_updated    timestamptz
);

create table if not exists public.schedules (
  id              uuid primary key default gen_random_uuid(),
  route_id        uuid not null references public.routes (id) on delete cascade,
  departure_time  time not null,
  arrival_time    time not null,
  delay_minutes   int not null default 0,
  is_cancelled    boolean not null default false
);

create table if not exists public.requests (
  id                 uuid primary key default gen_random_uuid(),
  location_name      text not null,
  latitude           float8 not null,
  longitude          float8 not null,
  student_count      int not null default 1,
  created_at         timestamptz not null default now(),
  last_requested_at  timestamptz not null default now()
);

-- One row per student per signal, so counts cannot be inflated.
create table if not exists public.request_votes (
  request_id  uuid not null references public.requests (id) on delete cascade,
  student_id  uuid not null references public.profiles (id) on delete cascade,
  voted_at    timestamptz not null default now(),
  primary key (request_id, student_id)
);

create index if not exists vehicles_status_idx on public.vehicles (status);
create index if not exists schedules_route_idx on public.schedules (route_id, departure_time);
create index if not exists requests_location_idx on public.requests (location_name, last_requested_at desc);

-- ---------------------------------------------------------------- helpers

create or replace function public.current_role_name()
returns text language sql stable security definer set search_path = public as $$
  select role from public.profiles where id = auth.uid();
$$;

-- Creates the profile on sign-up and enforces the KIIT email domain.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if lower(new.email) not like '%@kiit.ac.in' then
    raise exception 'Registration is limited to kiit.ac.in email domain';
  end if;
  insert into public.profiles (id, name, email, phone)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'name', split_part(new.email, '@', 1)),
    lower(new.email),
    nullif(new.raw_user_meta_data ->> 'phone', '')
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Aggregates a student's "I'm waiting here" signal into one row per location.
create or replace function public.submit_demand_request(
  p_location_name text,
  p_latitude float8,
  p_longitude float8
) returns public.requests
language plpgsql security definer set search_path = public as $$
declare
  r public.requests;
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;

  select * into r from public.requests
   where location_name = p_location_name
     and last_requested_at > now() - interval '30 minutes'
   order by last_requested_at desc
   limit 1
   for update;

  if r.id is null then
    insert into public.requests (location_name, latitude, longitude)
    values (p_location_name, p_latitude, p_longitude)
    returning * into r;
    insert into public.request_votes (request_id, student_id) values (r.id, auth.uid());
    return r;
  end if;

  if exists (
    select 1 from public.request_votes
     where request_id = r.id and student_id = auth.uid()
       and voted_at > now() - interval '5 minutes'
  ) then
    raise exception 'cooldown: already signalled this location';
  end if;

  insert into public.request_votes (request_id, student_id) values (r.id, auth.uid())
  on conflict (request_id, student_id) do update set voted_at = now();

  update public.requests
     set student_count = (select count(*) from public.request_votes where request_id = r.id),
         last_requested_at = now()
   where id = r.id
  returning * into r;
  return r;
end;
$$;

grant execute on function public.submit_demand_request(text, float8, float8) to authenticated;

-- ---------------------------------------------------------------- RLS

alter table public.profiles      enable row level security;
alter table public.routes        enable row level security;
alter table public.vehicles      enable row level security;
alter table public.schedules     enable row level security;
alter table public.requests      enable row level security;
alter table public.request_votes enable row level security;

-- profiles: everyone signed in can read (driver directory); users edit only
-- their own name/phone — role changes are admin-only via column grants.
drop policy if exists profiles_read on public.profiles;
create policy profiles_read on public.profiles for select to authenticated using (true);
drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own on public.profiles for update to authenticated
  using (id = auth.uid() or public.current_role_name() = 'admin');
revoke update on public.profiles from authenticated;
grant update (name, phone) on public.profiles to authenticated;

-- routes & schedules: read for all; admins manage; drivers may post delays.
drop policy if exists routes_read on public.routes;
create policy routes_read on public.routes for select to authenticated using (true);
drop policy if exists routes_admin on public.routes;
create policy routes_admin on public.routes for all to authenticated
  using (public.current_role_name() = 'admin') with check (public.current_role_name() = 'admin');

drop policy if exists schedules_read on public.schedules;
create policy schedules_read on public.schedules for select to authenticated using (true);
drop policy if exists schedules_staff_update on public.schedules;
create policy schedules_staff_update on public.schedules for update to authenticated
  using (public.current_role_name() in ('driver', 'admin'));
drop policy if exists schedules_admin on public.schedules;
create policy schedules_admin on public.schedules for all to authenticated
  using (public.current_role_name() = 'admin') with check (public.current_role_name() = 'admin');

-- vehicles: read for all; a driver may claim a free vehicle and update only
-- the one assigned to them.
drop policy if exists vehicles_read on public.vehicles;
create policy vehicles_read on public.vehicles for select to authenticated using (true);
drop policy if exists vehicles_driver_update on public.vehicles;
create policy vehicles_driver_update on public.vehicles for update to authenticated
  using (
    public.current_role_name() = 'admin'
    or (public.current_role_name() = 'driver'
        and (driver_id is null or driver_id = auth.uid() or status <> 'active'))
  )
  with check (
    public.current_role_name() = 'admin'
    or (public.current_role_name() = 'driver' and (driver_id = auth.uid() or driver_id is null))
  );
drop policy if exists vehicles_admin on public.vehicles;
create policy vehicles_admin on public.vehicles for all to authenticated
  using (public.current_role_name() = 'admin') with check (public.current_role_name() = 'admin');

-- requests: read for all; inserts go through submit_demand_request();
-- drivers/admins clear a signal once served.
drop policy if exists requests_read on public.requests;
create policy requests_read on public.requests for select to authenticated using (true);
drop policy if exists requests_staff_delete on public.requests;
create policy requests_staff_delete on public.requests for delete to authenticated
  using (public.current_role_name() in ('driver', 'admin'));

-- request_votes: private; only the security-definer RPC touches them.

-- ---------------------------------------------------------------- realtime

do $$
begin
  begin alter publication supabase_realtime add table public.vehicles;  exception when duplicate_object then null; end;
  begin alter publication supabase_realtime add table public.requests;  exception when duplicate_object then null; end;
  begin alter publication supabase_realtime add table public.schedules; exception when duplicate_object then null; end;
end $$;

-- Deletes are delivered with the full row so clients can drop them.
alter table public.requests replica identity full;

-- Optional housekeeping (needs the pg_cron extension):
-- select cron.schedule('expire-requests', '*/10 * * * *',
--   $$delete from public.requests where last_requested_at < now() - interval '45 minutes'$$);
-- select cron.schedule('offline-stale-vehicles', '* * * * *',
--   $$update public.vehicles set status = 'offline'
--     where status = 'active' and last_updated < now() - interval '5 minutes'$$);
