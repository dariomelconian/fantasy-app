# Fantasy Hockey App - Context & Vision

## Project Overview
A fantasy sports iOS app inspired by Sleeper, focusing on private leagues with competitive gameplay. Starting with NHL hockey, with MLB baseball expansion planned for future phases.

## Tech Stack
- **iOS Frontend**: SwiftUI with MVVM architecture
- **Backend**: Supabase (Postgres + Auth + Realtime)
- **Data Source**: NHL Public API (api-web.nhle.com)
- **AI Integration**: Claude API for enhanced features
- **Theme**: Carbon & Ember dark mode

## Design System
### Colors (Carbon & Ember Theme)
- **Background**: #0D0D0F
- **Cards**: #1A1A1F
- **Border**: #2C2C35
- **Accent Orange**: #F4642A (Ember)
- **Accent Amber**: #F7A325 (Amber)
- **Text**: #F0EFE9
- **Muted Text**: #8B8B9A
- **Win Green**: #3DDC84
- **Loss Red**: #FF4757

## Phase 1 Scope (Hockey MVP)
### Core Features
- **Private Leagues**: Invite-only leagues with customizable settings
- **Snake Draft**: Live drafting with real-time updates
- **Weekly Matchups**: Head-to-head scoring competitions
- **Waiver Wire**: Free agent claims with priority system
- **Roster Management**: Starter/Bench/IR with drag-and-drop
- **Standings**: League rankings and statistics

### Technical Implementation
- **Supabase Schema**: Complete database design with RLS policies
- **NHL API Integration**: Player data, stats, schedules, box scores
- **SwiftUI App**: Tab-based navigation with rich UX
- **Real-time Updates**: Live draft and waiver processing
- **Scoring Engine**: Fantasy points calculation from NHL stats

## Database Schema
### Core Tables
- `users` - User accounts and profiles
- `leagues` - League configuration and settings
- `league_members` - League participation
- `teams` - Fantasy teams within leagues
- `players` - NHL player data (synced from API)
- `roster_entries` - Team rosters with lineup slots
- `draft_picks` - Draft history and selections
- `waiver_transactions` - Waiver claims and processing
- `weekly_matchups` - Head-to-head results
- `standings` - League rankings
- `league_settings` - Customizable league rules

### Key Relationships
- Leagues contain Teams (many-to-one)
- Teams have Roster Entries (one-to-many)
- Roster Entries reference Players (many-to-one)
- Weekly Matchups pair Teams for scoring
- Waiver Transactions affect Roster Entries

## Architecture Patterns
- **MVVM**: ViewModels handle business logic and API calls
- **Service Layer**: SupabaseClient, NHLAPI, FantasyEngine
- **Observable Objects**: Reactive UI updates
- **Async/Await**: Modern concurrency for API operations
- **Row Level Security**: Private league data protection

## Development Roadmap
### Phase 1 (Current): Hockey MVP
- [x] Project structure and Supabase schema
- [x] iOS app scaffold with tab navigation
- [x] NHL API integration and data sync
- [x] League creation and management
- [x] Snake draft implementation
- [x] Roster management with lineup slots
- [x] Weekly matchup scoring
- [x] Waiver wire processing
- [x] Standings and league rankings
- [ ] Testing and polish
- [ ] App Store submission

### Phase 2: Enhanced Features
- AI-powered trade suggestions
- Advanced statistics and analytics
- Push notifications
- Social features (messages, polls)
- Custom scoring categories

### Phase 3: MLB Expansion
- Baseball player data and stats
- Multi-sport leagues
- Cross-sport drafts
- Sport-specific scoring rules

## Success Metrics
- User engagement with weekly matchups
- League retention and growth
- Positive App Store reviews
- Feature adoption rates
- Technical performance (load times, reliability)

## Development Principles
- **User-First Design**: Intuitive UX matching Sleeper's polish
- **Performance**: Fast loading and smooth interactions
- **Security**: Private leagues with proper data isolation
- **Scalability**: Architecture supporting future sports/features
- **Maintainability**: Clean code with comprehensive documentation