# Fantasy Sports App (NHL + MLB)

## Stack
- SwiftUI iOS frontend
- Supabase (Postgres + Auth + Realtime)
- NHL public API
- Claude API for AI features
- Dark theme: charcoal + amber/orange (Carbon/Ember style)

## Scope v1
- Private leagues only
- Snake drafts
- Weekly matchup scoring
- Waiver wire
- Standings + leaderboard

## Quick start
1. Create Supabase project and get `SUPABASE_URL` + `SUPABASE_KEY`
2. Run `supabase/setup_schema.sql` and `supabase/rls_policies.sql` in SQL editor
3. Configure iOS env in `ios/Services/SupabaseClient.swift`
4. Build and run the SwiftUI app from Xcode

## Supabase flow
- League operations in `ios/Services/SupabaseLeagueService.swift`
- Draft + waiver + standings logic in `ios/Services/FantasyEngine.swift`
- League + roster management UIs in `ios/Views/LeagueManagementView.swift`, `ios/Views/TeamRosterView.swift`, `ios/Views/WaiverWireView.swift`, `ios/Views/StandingsView.swift`
- Sample state in `ios/ViewModels/FantasyViewModel.swift`

## Pivot plan
1. Add MLB data feed (same architecture as NHL client)
2. Add user invitation + league join flow
3. Add playoff bracket (post-regular season)
4. Add in-app push notifications for waiver deadlines + matchup results
