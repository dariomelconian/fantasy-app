import Foundation

public struct SupabaseLeagueService {
    private let supabase: SupabaseClient

    public init(supabaseClient: SupabaseClient) {
        self.supabase = supabaseClient
    }

    public func fetchUserLeagues(userId: UUID) async throws -> [FantasyLeague] {
        let path = "rest/v1/leagues?select=*&league_members.user_id=eq.
\(userId.uuidString)"
        return try await supabase.fetch(path, type: [FantasyLeague].self)
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
