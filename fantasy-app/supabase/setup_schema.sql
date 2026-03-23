-- Supabase schema for private fantasy leagues (NHL + MLB)

-- USERS: track Supabase auth UIDs
create table if not exists users (
  id uuid primary key default gen_random_uuid(),
  auth_uid uuid not null unique,
  display_name text,
  email text,
  created_at timestamp with time zone default now()
);

-- LEAGUES
create table if not exists leagues (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  sport text not null check(sport in ('NHL','MLB')),
  owner_id uuid references users(id) on delete cascade,
  roster_size int not null default 15,
  draft_rounds int not null default 15,
  season_year int not null,
  draft_started boolean default false,
  draft_completed boolean default false,
  waiver_period_hours int not null default 72,
  invite_code text unique,
  matchup_week_start date,
  matchup_week_end date,
  created_at timestamp with time zone default now()
);

-- LEAGUE MEMBERSHIP
create table if not exists league_members (
  id uuid primary key default gen_random_uuid(),
  league_id uuid references leagues(id) on delete cascade,
  user_id uuid references users(id) on delete cascade,
  joined_at timestamp with time zone default now(),
  unique (league_id, user_id)
);

-- TEAMS
create table if not exists teams (
  id uuid primary key default gen_random_uuid(),
  league_id uuid references leagues(id) on delete cascade,
  name text not null,
  manager_user_id uuid references users(id),
  draft_position int,
  created_at timestamp with time zone default now(),
  unique (league_id, draft_position)
);

-- PLAYERS: NHL/MLB players cached with external ids for lookup
create table if not exists players (
  id uuid primary key default gen_random_uuid(),
  external_id text not null,
  sport text not null check(sport in ('NHL','MLB')),
  full_name text,
  position text,
  team text,
  active boolean default true,
  updated_at timestamp with time zone default now(),
  unique (external_id, sport)
);

-- ROSTER ENTRIES
create table if not exists roster_entries (
  id uuid primary key default gen_random_uuid(),
  team_id uuid references teams(id) on delete cascade,
  player_id uuid references players(id),
  slot text not null,
  acquired_at timestamp with time zone default now(),
  dropped_at timestamp with time zone,
  unique (team_id, player_id, dropped_at) -- each player active only once per team
);

-- SNAKE DRAFT PICKS
create table if not exists draft_picks (
  id uuid primary key default gen_random_uuid(),
  league_id uuid references leagues(id) on delete cascade,
  team_id uuid references teams(id),
  round int not null,
  pick int not null,
  player_id uuid references players(id),
  picked_at timestamp with time zone,
  unique (league_id, round, pick),
  unique (league_id, team_id, round)
);

-- WAIVER TRANSACTIONS
create table if not exists waiver_transactions (
  id uuid primary key default gen_random_uuid(),
  league_id uuid references leagues(id) on delete cascade,
  team_id uuid references teams(id) on delete cascade,
  player_added_id uuid references players(id),
  player_dropped_id uuid references players(id),
  priority int,
  status text not null check(status in ('pending','approved','rejected')) default 'pending',
  requested_at timestamp with time zone default now(),
  resolved_at timestamp with time zone
);

-- MATCHUPS AND SCORES
create table if not exists weekly_matchups (
  id uuid primary key default gen_random_uuid(),
  league_id uuid references leagues(id) on delete cascade,
  week int not null,
  team_a_id uuid references teams(id) on delete cascade,
  team_b_id uuid references teams(id) on delete cascade,
  score_a numeric,
  score_b numeric,
  winner_team_id uuid references teams(id),
  played_at timestamp with time zone,
  unique (league_id, week, team_a_id, team_b_id)
);

-- STANDINGS snapshot by week
create table if not exists standings (
  id uuid primary key default gen_random_uuid(),
  league_id uuid references leagues(id) on delete cascade,
  team_id uuid references teams(id) on delete cascade,
  week int not null,
  wins int default 0,
  losses int default 0,
  ties int default 0,
  points numeric default 0,
  created_at timestamp with time zone default now(),
  unique (league_id, team_id, week)
);

-- Triggers and support functions (example for roster update after draft pick)
create function public.track_draft_to_roster() returns trigger as $$
begin
  if new.player_id is not null and new.picked_at is not null then
    insert into roster_entries(team_id, player_id, slot, acquired_at)
    values (new.team_id, new.player_id, 'N/A', now())
    on conflict do nothing;
  end if;
  return new;
end;
$$ language plpgsql;

create trigger trg_track_draft_to_roster
after update on draft_picks
for each row
when (new.player_id is not null and new.picked_at is not null)
execute function public.track_draft_to_roster();
