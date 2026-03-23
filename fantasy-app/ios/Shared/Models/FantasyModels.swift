import Foundation

public struct FantasyUser: Codable, Identifiable {
    public let id: UUID
    public let displayName: String?
    public let email: String?
}

public struct FantasyLeague: Codable, Identifiable {
    public let id: UUID
    public let name: String
    public let sport: String
    public let ownerId: UUID
    public let rosterSize: Int
    public let draftRounds: Int
    public let seasonYear: Int
    public let draftStarted: Bool
    public let draftCompleted: Bool
    public let waiverPeriodHours: Int
}

public struct FantasyTeam: Codable, Identifiable {
    public let id: UUID
    public let leagueId: UUID
    public let name: String
    public let managerUserId: UUID
    public let draftPosition: Int?
}

public struct FantasyPlayer: Codable, Identifiable {
    public let id: UUID
    public let externalId: String
    public let sport: String
    public let fullName: String
    public let position: String?
    public let team: String?
    public let active: Bool
}

public struct RosterEntry: Codable, Identifiable {
    public let id: UUID
    public let teamId: UUID
    public let playerId: UUID
    public let slot: String
    public let acquiredAt: Date
    public let droppedAt: Date?
}

public struct WaiverTransaction: Codable, Identifiable {
    public let id: UUID
    public let leagueId: UUID
    public let teamId: UUID
    public let playerAddedId: UUID
    public let playerDroppedId: UUID?
    public let priority: Int
    public let status: String
    public let requestedAt: Date
    public let resolvedAt: Date?
}

public struct WeeklyMatchup: Codable, Identifiable {
    public let id: UUID
    public let leagueId: UUID
    public let week: Int
    public let teamAId: UUID
    public let teamBId: UUID
    public let scoreA: Double?
    public let scoreB: Double?
    public let winnerTeamId: UUID?
}

public struct StandingRow: Codable, Identifiable {
    public let id: UUID
    public let leagueId: UUID
    public let teamId: UUID
    public let week: Int
    public let wins: Int
    public let losses: Int
    public let ties: Int
    public let points: Double
}
