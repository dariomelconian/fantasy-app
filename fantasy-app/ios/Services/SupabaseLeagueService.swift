import Foundation

public struct SupabaseLeagueService {
    private let supabase: SupabaseClient

    public init(supabaseClient: SupabaseClient) {
        self.supabase = supabaseClient
    }

    public func fetchUserLeagues(userId: UUID) async throws -> [FantasyLeague] {
        let path = "rest/v1/leagues?select=*&league_members.user_id=eq.\(userId.uuidString)"
        return try await supabase.fetch(path, type: [FantasyLeague].self)
    }

    public func fetchLeagueByInviteCode(_ inviteCode: String) async throws -> FantasyLeague? {
        let path = "rest/v1/leagues?invite_code=eq.\(inviteCode)&select=*"
        let result = try await supabase.fetch(path, type: [FantasyLeague].self)
        return result.first
    }

    public func createLeague(input: CreateLeagueInput) async throws -> FantasyLeague {
        let path = "rest/v1/leagues"
        return try await supabase.post(path, payload: input, type: FantasyLeague.self)
    }

    public func addTeam(to leagueId: UUID, teamName: String, managerUserId: UUID, draftPosition: Int) async throws -> FantasyTeam {
        let path = "rest/v1/teams"
        let payload = CreateTeamInput(league_id: leagueId, name: teamName, manager_user_id: managerUserId, draft_position: draftPosition)
        return try await supabase.post(path, payload: payload, type: FantasyTeam.self)
    }

    public func createDraftPick(leagueId: UUID, teamId: UUID, round: Int, pick: Int, playerId: UUID) async throws -> DraftPickResponse {
        let path = "rest/v1/draft_picks"
        let payload = CreateDraftPickInput(league_id: leagueId, team_id: teamId, round: round, pick: pick, player_id: playerId, picked_at: Date())
        return try await supabase.post(path, payload: payload, type: DraftPickResponse.self)
    }

    public func joinLeague(leagueId: UUID, userId: UUID) async throws -> LeagueMemberResponse {
        let path = "rest/v1/league_members"
        let payload = CreateLeagueMemberInput(league_id: leagueId, user_id: userId)
        return try await supabase.post(path, payload: payload, type: LeagueMemberResponse.self)
    }

    public struct LeagueStatusUpdateInput: Encodable {
        public let draft_started: Bool?
        public let draft_completed: Bool?
        public init(draft_started: Bool? = nil, draft_completed: Bool? = nil) {
            self.draft_started = draft_started
            self.draft_completed = draft_completed
        }
    }

    public func updateLeagueStatus(leagueId: UUID, draftStarted: Bool? = nil, draftCompleted: Bool? = nil) async throws -> FantasyLeague {
        let path = "rest/v1/leagues?id=eq.\(leagueId.uuidString)"
        let payload = LeagueStatusUpdateInput(draft_started: draftStarted, draft_completed: draftCompleted)
        let response: [FantasyLeague] = try await supabase.patch(path, payload: payload, type: [FantasyLeague].self)
        guard let league = response.first else { throw NSError(domain: "SupabaseLeagueService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Update failed"]) }
        return league
    }

    public func fetchWaiverTransactions(leagueId: UUID) async throws -> [WaiverTransaction] {
        let path = "rest/v1/waiver_transactions?league_id=eq.\(leagueId.uuidString)&order=priority.desc,requested_at.asc"
        return try await supabase.fetch(path, type: [WaiverTransaction].self)
    }

    public func submitWaiverRequest(_ input: WaiverRequestInput) async throws -> WaiverTransaction {
        let path = "rest/v1/waiver_transactions"
        return try await supabase.post(path, payload: input, type: WaiverTransaction.self)
    }

    public func fetchStandings(leagueId: UUID, week: Int) async throws -> [StandingRow] {
        let path = "rest/v1/standings?league_id=eq.\(leagueId.uuidString)&week=eq.\(week)"
        return try await supabase.fetch(path, type: [StandingRow].self)
    }

    public func fetchPlayers(playerIds: [UUID]) async throws -> [FantasyPlayer] {
        let ids = playerIds.map { $0.uuidString }.joined(separator: ",")
        let path = "rest/v1/players?id=in.(\(ids))"
        return try await supabase.fetch(path, type: [FantasyPlayer].self)
    }

    public func calculateWeeklyMatchups(leagueId: UUID, week: Int, season: String) async throws -> [WeeklyMatchupResultInput] {
        let teams = try await fetchTeams(leagueId: leagueId)
        var teamScores = [UUID: Double]()

        for team in teams {
            let rosterEntries = try await fetchRosterEntries(teamId: team.id)
            let playerUUIDs = rosterEntries.map { $0.playerId }
            let players = try await fetchPlayers(playerIds: playerUUIDs)

            var playerPoints = [UUID: Double]()
            let nhl = NHLAPI()
            for player in players {
                if let playerId = Int(player.externalId) {
                    let statsResponse = try await nhl.getPlayerStats(playerId: playerId, season: season)
                    if let split = statsResponse.stats.first?.splits.first {
                        playerPoints[player.id] = FantasyEngine.calculateFantasyPoints(from: split.stat)
                    }
                }
            }

            let teamScore = FantasyEngine.aggregateTeamPoints(playerPoints: playerPoints, roster: rosterEntries)
            teamScores[team.id] = teamScore
        }

        var results: [WeeklyMatchupResultInput] = []
        let sortedTeams = teams.sorted(by: { $0.draftPosition ?? 0 < $1.draftPosition ?? 0 })
        for idx in stride(from: 0, to: sortedTeams.count - 1, by: 2) {
            let a = sortedTeams[idx]
            let b = sortedTeams[idx + 1]
            results.append(WeeklyMatchupResultInput(
                league_id: leagueId,
                week: week,
                teamAId: a.id,
                teamBId: b.id,
                scoreA: teamScores[a.id] ?? 0.0,
                scoreB: teamScores[b.id] ?? 0.0
            ))
        }

        // write results into weekly_matchups
await insertWeeklyMatchups(results)
        return results
    }

    public func insertWeeklyMatchups(_ results: [WeeklyMatchupResultInput]) async throws -> [WeeklyMatchup] {
        let path = "rest/v1/weekly_matchups"
        return try await supabase.post(path, payload: results, type: [WeeklyMatchup].self)
    }
        let path = "rest/v1/teams?league_id=eq.\(leagueId.uuidString)&order=draft_position.asc"
        return try await supabase.fetch(path, type: [FantasyTeam].self)
    }

    public func fetchRosterEntries(teamId: UUID) async throws -> [RosterEntry] {
        let path = "rest/v1/roster_entries?team_id=eq.\(teamId.uuidString)&dropped_at=is.null"
        return try await supabase.fetch(path, type: [RosterEntry].self)
    }

    public struct PickPlayerInput: Encodable {
        public let team_id: UUID
        public let player_id: UUID
        public let slot: String
    }

    public struct DropRosterEntryInput: Encodable {
        public let dropped_at: Date
    }

    public struct WaiverDecisionInput: Encodable {
        public let status: String
        public let resolved_at: Date
    }

    public struct UpdateLineupSlotInput: Encodable {
        public let lineup_slot: String
    }

    public struct WeeklyMatchupResultInput: Encodable {
        public let league_id: UUID
        public let week: Int
        public let teamAId: UUID
        public let teamBId: UUID
        public let scoreA: Double
        public let scoreB: Double
    }

    public func pickPlayer(teamId: UUID, playerId: UUID, slot: String = "N/A") async throws -> RosterEntry {
        let path = "rest/v1/roster_entries"
        let payload = PickPlayerInput(team_id: teamId, player_id: playerId, slot: slot)
        return try await supabase.post(path, payload: payload, type: RosterEntry.self)
    }

    public func dropPlayer(rosterEntryId: UUID) async throws -> RosterEntry {
        let path = "rest/v1/roster_entries?id=eq.\(rosterEntryId.uuidString)"
        let payload = DropRosterEntryInput(dropped_at: Date())
        let response: [RosterEntry] = try await supabase.patch(path, payload: payload, type: [RosterEntry].self)
        guard let first = response.first else { throw NSError(domain: "SupabaseLeagueService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Drop failed"]) }
        return first
    }

    public func processWaiverDecision(waiverId: UUID, status: String) async throws -> WaiverTransaction {
        let path = "rest/v1/waiver_transactions?id=eq.\(waiverId.uuidString)"
        let payload = WaiverDecisionInput(status: status, resolved_at: Date())
        let result: [WaiverTransaction] = try await supabase.patch(path, payload: payload, type: [WaiverTransaction].self)
        guard let first = result.first else { throw NSError(domain: "SupabaseLeagueService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Waiver update failed"]) }
        return first
    }

    public func fetchLeagueSettings(leagueId: UUID) async throws -> LeagueSettings {
        let path = "rest/v1/league_settings?league_id=eq.\(leagueId.uuidString)"
        let result = try await supabase.fetch(path, type: [LeagueSettings].self)
        guard let settings = result.first else { throw NSError(domain: "SupabaseLeagueService", code: 4, userInfo: [NSLocalizedDescriptionKey: "No settings found for league"]) }
        return settings
    }

    public func fetchWeeklyMatchups(leagueId: UUID, week: Int) async throws -> [WeeklyMatchup] {
        let path = "rest/v1/weekly_matchups?league_id=eq.\(leagueId.uuidString)&week=eq.\(week)"
        return try await supabase.fetch(path, type: [WeeklyMatchup].self)
    }

    public func updateLineupSlot(rosterEntryId: UUID, lineupSlot: String) async throws -> RosterEntry {
        let path = "rest/v1/roster_entries?id=eq.\(rosterEntryId.uuidString)"
        let payload = UpdateLineupSlotInput(lineup_slot: lineupSlot)
        let response: [RosterEntry] = try await supabase.patch(path, payload: payload, type: [RosterEntry].self)
        guard let first = response.first else { throw NSError(domain: "SupabaseLeagueService", code: 5, userInfo: [NSLocalizedDescriptionKey: "Update lineup slot failed"]) }
        return first
    }

    // Convenience method to import NHL roster into players table and returns inserted players
    public func importNHLTeamRoster(teamId: Int, sport: String = "NHL") async throws -> [FantasyPlayer] {
        let api = NHLAPI()
        let roster = try await api.getTeamRoster(teamId: teamId)

        var imported: [FantasyPlayer] = []
        for player in roster {
            let input = CreatePlayerInput(
                external_id: String(player.id),
                sport: sport,
                full_name: player.fullName,
                position: player.primaryPosition.code,
                team: "",
                active: true
            )
            let created: FantasyPlayer = try await supabase.post("rest/v1/players", payload: input, type: FantasyPlayer.self)
            imported.append(created)
        }

        return imported
    }
}

// MARK: - Request payloads
public struct CreateLeagueInput: Encodable {
    public let name: String
    public let sport: String
    public let owner_id: UUID
    public let roster_size: Int
    public let draft_rounds: Int
    public let season_year: Int
    public let waiver_period_hours: Int
    public let invite_code: String?
}

public struct CreateTeamInput: Encodable {
    public let league_id: UUID
    public let name: String
    public let manager_user_id: UUID
    public let draft_position: Int
}

public struct CreateDraftPickInput: Encodable {
    public let league_id: UUID
    public let team_id: UUID
    public let round: Int
    public let pick: Int
    public let player_id: UUID
    public let picked_at: Date
}

public struct CreatePlayerInput: Encodable {
    public let external_id: String
    public let sport: String
    public let full_name: String
    public let position: String
    public let team: String
    public let active: Bool
}

public struct CreateLeagueMemberInput: Encodable {
    public let league_id: UUID
    public let user_id: UUID
}

public struct LeagueMemberResponse: Codable, Identifiable {
    public let id: UUID
    public let league_id: UUID
    public let user_id: UUID
    public let joined_at: Date
}

// Response placeholder for insert-returns
public struct DraftPickResponse: Codable, Identifiable {
    public let id: UUID
    public let league_id: UUID
    public let team_id: UUID
    public let round: Int
    public let pick: Int
    public let player_id: UUID
    public let picked_at: Date
}
