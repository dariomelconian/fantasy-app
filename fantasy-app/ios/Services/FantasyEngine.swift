import Foundation

public struct WaiverRequestInput: Encodable {
    public let league_id: UUID
    public let team_id: UUID
    public let player_added_id: UUID
    public let player_dropped_id: UUID?
    public let priority: Int
    public let status: String
    public let requested_at: Date
}

public struct WeeklyMatchupResultInput {
    public let league_id: UUID
    public let week: Int
    public let teamAId: UUID
    public let teamBId: UUID
    public let scoreA: Double
    public let scoreB: Double
}

public struct StandingUpdate {
    public let leagueId: UUID
    public let teamId: UUID
    public let week: Int
    public let wins: Int
    public let losses: Int
    public let ties: Int
    public let points: Double
}

public final class FantasyEngine {
    /// Determine next draft pick index using snake pattern.
    public static func nextPickIndex(for currentRound: Int, currentPickIndex: Int, teams: [String]) -> Int {
        if currentPickIndex + 1 < teams.count {
            return currentPickIndex + 1
        }
        return 0
    }

    public static func isReverseRound(_ round: Int) -> Bool {
        return round % 2 == 0
    }

    public static func orderedTeamNames(for teams: [String], round: Int) -> [String] {
        isReverseRound(round) ? teams.reversed() : teams
    }

    /// Process matchup results and produce standings updates.
    public static func calculateStandingsFromMatchups(_ results: [WeeklyMatchupResultInput]) -> [StandingUpdate] {
        var map = [UUID: StandingUpdate]()

        for result in results {
            let teamAWins = result.scoreA > result.scoreB
            let teamBWins = result.scoreB > result.scoreA
            let tie = result.scoreA == result.scoreB

            let teamAUpdate = map[result.teamAId] ?? StandingUpdate(leagueId: result.league_id, teamId: result.teamAId, week: result.week, wins: 0, losses: 0, ties: 0, points: 0)
            let teamBUpdate = map[result.teamBId] ?? StandingUpdate(leagueId: result.league_id, teamId: result.teamBId, week: result.week, wins: 0, losses: 0, ties: 0, points: 0)

            let updatedA: StandingUpdate
            let updatedB: StandingUpdate

            if tie {
                updatedA = StandingUpdate(leagueId: result.league_id, teamId: result.teamAId, week: result.week, wins: teamAUpdate.wins, losses: teamAUpdate.losses, ties: teamAUpdate.ties + 1, points: teamAUpdate.points + 1)
                updatedB = StandingUpdate(leagueId: result.league_id, teamId: result.teamBId, week: result.week, wins: teamBUpdate.wins, losses: teamBUpdate.losses, ties: teamBUpdate.ties + 1, points: teamBUpdate.points + 1)
            } else if teamAWins {
                updatedA = StandingUpdate(leagueId: result.league_id, teamId: result.teamAId, week: result.week, wins: teamAUpdate.wins + 1, losses: teamAUpdate.losses, ties: teamAUpdate.ties, points: teamAUpdate.points + 2)
                updatedB = StandingUpdate(leagueId: result.league_id, teamId: result.teamBId, week: result.week, wins: teamBUpdate.wins, losses: teamBUpdate.losses + 1, ties: teamBUpdate.ties, points: teamBUpdate.points)
            } else {
                updatedA = StandingUpdate(leagueId: result.league_id, teamId: result.teamAId, week: result.week, wins: teamAUpdate.wins, losses: teamAUpdate.losses + 1, ties: teamAUpdate.ties, points: teamAUpdate.points)
                updatedB = StandingUpdate(leagueId: result.league_id, teamId: result.teamBId, week: result.week, wins: teamBUpdate.wins + 1, losses: teamBUpdate.losses, ties: teamBUpdate.ties, points: teamBUpdate.points + 2)
            }

            map[result.teamAId] = updatedA
            map[result.teamBId] = updatedB
        }

        return map.values.sorted { $0.teamId.uuidString < $1.teamId.uuidString }
    }

    /// Evaluate waiver requests order by priority and request time.
    public static func resolveWaiverQueue(_ queue: [WaiverRequestInput]) -> [WaiverRequestInput] {
        queue.sorted {
            if $0.priority == $1.priority {
                return $0.requested_at < $1.requested_at
            }
            return $0.priority > $1.priority
        }
    }
}
