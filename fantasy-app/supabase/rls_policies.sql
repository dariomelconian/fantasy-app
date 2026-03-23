-- Supabase row-level security policies for private leagues app

-- Enable RLS on all main tables
alter table users enable row level security;
alter table leagues enable row level security;
alter table league_members enable row level security;
alter table teams enable row level security;
alter table draft_picks enable row level security;
alter table roster_entries enable row level security;
alter table waiver_transactions enable row level security;
alter table weekly_matchups enable row level security;
alter table standings enable row level security;
alter table league_settings enable row level security;

-- User table: only user can select own row
create policy "Users can view own profile"
  on users
  for select
  using (auth.uid()::uuid = auth_uid);

create policy "Users can manage own row"
  on users
  for all
  using (auth.uid()::uuid = auth_uid)
  with check (auth.uid()::uuid = auth_uid);

-- Leagues: owner or member can read (and owner can write)
create policy "Leagues read for member or invite"
  on leagues
  for select
  using (
    (
      exists (
        select 1
        from league_members lm
        where lm.league_id = leagues.id
          and lm.user_id = (auth.uid()::uuid)
      )
    )
    or owner_id = auth.uid()::uuid
    or invite_code is not null
  );

create policy "League insert by owner"
  on leagues
  for insert
  with check (owner_id = auth.uid()::uuid);

create policy "League update/delete by owner"
  on leagues
  for update, delete
  using (owner_id = auth.uid()::uuid)
  with check (owner_id = auth.uid()::uuid);

-- League members: only members can see their own membership and owners can add
create policy "League_members select for member"
  on league_members
  for select
  using (user_id = auth.uid()::uuid);

create policy "League_members insert by owner or self-join"
  on league_members
  for insert
  using (
    (
      exists (
        select 1 from leagues l where l.id = league_id and l.owner_id = auth.uid()::uuid
      )
    )
    or (
      exists (
        select 1 from leagues l where l.id = league_id and l.invite_code is not null
      )
      and user_id = auth.uid()::uuid
    )
  )
  with check (user_id = auth.uid()::uuid);

-- Teams: member of league can select; owner can insert/update/delete
create policy "Teams select for member"
  on teams
  for select
  using (
    exists (
      select 1 from league_members lm where lm.league_id = teams.league_id and lm.user_id = auth.uid()::uuid
    )
  );

create policy "Teams insert/update/delete for owner"
  on teams
  for insert, update, delete
  using (
    exists (
      select 1 from leagues l where l.id = teams.league_id and l.owner_id = auth.uid()::uuid
    )
  )
  with check (
    exists (
      select 1 from leagues l where l.id = teams.league_id and l.owner_id = auth.uid()::uuid
    )
  );

-- Draft picks, roster, waivers, matchups, standings are league-specific; allow member access
create policy "League objects allow member select"
  on draft_picks
  for select
  using (
    exists (
      select 1 from league_members lm where lm.league_id = draft_picks.league_id and lm.user_id = auth.uid()::uuid
    )
  );

create policy "League objects insert/update/delete owner"
  on draft_picks
  for insert, update, delete
  using (
    exists (
      select 1 from leagues l where l.id = draft_picks.league_id and l.owner_id = auth.uid()::uuid
    )
  )
  with check (
    exists (
      select 1 from leagues l where l.id = draft_picks.league_id and l.owner_id = auth.uid()::uuid
    )
  );

-- Duplicate for roster_entries, waiver_transactions, weekly_matchups, standings
create policy "Roster entries select for member"
  on roster_entries
  for select
  using (
    exists (
      select 1 from teams t join league_members lm on t.league_id = lm.league_id where roster_entries.team_id = t.id and lm.user_id = auth.uid()::uuid
    )
  );

create policy "Waiver select for member"
  on waiver_transactions
  for select
  using (
    exists (
      select 1 from league_members lm where lm.league_id = waiver_transactions.league_id and lm.user_id = auth.uid()::uuid
    )
  );

create policy "Matchups select for member"
  on weekly_matchups
  for select
  using (
    exists (
      select 1 from league_members lm where lm.league_id = weekly_matchups.league_id and lm.user_id = auth.uid()::uuid
    )
  );

create policy "Standings select for member"
  on standings
  for select
  using (
    exists (
      select 1 from league_members lm where lm.league_id = standings.league_id and lm.user_id = auth.uid()::uuid
    )
  );

create policy "League settings select for member"
  on league_settings
  for select
  using (
    exists (
      select 1 from league_members lm where lm.league_id = league_settings.league_id and lm.user_id = auth.uid()::uuid
    )
  );

create policy "League settings insert/update/delete by owner"
  on league_settings
  for all
  using (
    exists (
      select 1 from leagues l where l.id = league_settings.league_id and l.owner_id = auth.uid()::uuid
    )
  )
  with check (
    exists (
      select 1 from leagues l where l.id = league_settings.league_id and l.owner_id = auth.uid()::uuid
    )
  );
