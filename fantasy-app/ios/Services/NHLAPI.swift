import Foundation

public enum NHLAPIError: Error {
    case invalidURL
    case serverError(status: Int)
    case decodingError(Error)
}

public struct NHLTeam: Codable { public let id: Int; public let name: String; public let abbreviation: String;  public let venue: NHLVenue? }
public struct NHLVenue: Codable { public let name: String }
public struct NHLPlayer: Codable { public let id: Int; public let fullName: String; public let primaryPosition: NHLPosition }
public struct NHLPosition: Codable { public let code: String; public let type: String; public let name: String }

public final class NHLAPI {
    private let baseURL = "https://statsapi.web.nhl.com/api/v1"
    private let session: URLSession

    public init(session: URLSession = .shared) { self.session = session }

    private func fetch<T: Decodable>(from url: URL) async throws -> T {
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw NHLAPIError.serverError(status: (response as? HTTPURLResponse)?.statusCode ?? -1)
        }
        do { return try JSONDecoder().decode(T.self, from: data) }
        catch { throw NHLAPIError.decodingError(error) }
    }

    public func getTeams() async throws -> [NHLTeam] {
        guard let url = URL(string: "\(baseURL)/teams") else { throw NHLAPIError.invalidURL }
        let wrapper = try await fetch(from: url, type: NHLTeamsResponse.self)
        return wrapper.teams
    }

    public func getTeamRoster(teamId: Int) async throws -> [NHLPlayer] {
        guard let url = URL(string: "\(baseURL)/teams/\(teamId)?expand=team.roster") else { throw NHLAPIError.invalidURL }
        let wrapper = try await fetch(from: url, type: NHLTeamRosterResponse.self)
        return wrapper.teams.first?.roster?.roster.map { $0.person } ?? []
    }

    public func getSchedule(startDate: String, endDate: String) async throws -> [NHLScheduleGame] {
        guard let url = URL(string: "\(baseURL)/schedule?startDate=\(startDate)&endDate=\(endDate)") else { throw NHLAPIError.invalidURL }
        let wrapper: NHLScheduleResponse = try await fetch(from: url)
        return wrapper.dates.flatMap { $0.games }
    }

    public func getPlayerStats(playerId: Int, season: String) async throws -> NHLPlayerStatsResponse {
        guard let url = URL(string: "\(baseURL)/people/\(playerId)/stats?stats=statsSingleSeason&season=\(season)") else { throw NHLAPIError.invalidURL }
        return try await fetch(from: url)
    }

    public func getGameBoxscore(gamePk: Int) async throws -> NHLBoxscoreResponse {
        guard let url = URL(string: "\(baseURL)/game/\(gamePk)/boxscore") else { throw NHLAPIError.invalidURL }
        return try await fetch(from: url)
    }
}

fileprivate struct NHLTeamsResponse: Codable { let teams: [NHLTeam] }
fileprivate struct NHLTeamRosterResponse: Codable { let teams: [NHLTeamWithRoster] }
fileprivate struct NHLTeamRosterResponse: Codable { let teams: [NHLTeamWithRoster] }
fileprivate struct NHLTeamWithRoster: Codable { let roster: NHLRoster? }
fileprivate struct NHLRoster: Codable { let roster: [NHLRosterEntry] }
fileprivate struct NHLRosterEntry: Codable { let person: NHLPlayer }

public struct NHLScheduleResponse: Codable { let dates: [NHLScheduleDate] }
public struct NHLScheduleDate: Codable { let date: String; let games: [NHLScheduleGame] }
public struct NHLScheduleGame: Codable { let gamePk: Int; let link: String; let status: NHLGameStatus; let teams: NHLScheduleTeams }
public struct NHLGameStatus: Codable { let abstractGameState: String; let codedGameState: String }
public struct NHLScheduleTeams: Codable {
    let away: NHLScheduleTeamInfo
    let home: NHLScheduleTeamInfo
}
public struct NHLScheduleTeamInfo: Codable { let score: Int?; let team: NHLTeam }

public struct NHLPlayerStatsResponse: Codable {
    let stats: [NHLPlayerStatsContainer]
}

public struct NHLPlayerStatsContainer: Codable {
    let type: NHLPlayerStatsType
    let splits: [NHLPlayerStatsSplit]
}

public struct NHLPlayerStatsType: Codable {
    let displayName: String
    let gameType: String
    let season: String
}

public struct NHLPlayerStatsSplit: Codable {
    let stat: NHLPlayerStat
}

public struct NHLPlayerStat: Codable {
    let goals: Int?
    let assists: Int?
    let pim: Int?
    let shots: Int?
    let hits: Int?
    let blocked: Int?
    let powerPlayGoals: Int?
    let shortHandedGoals: Int?
    let gameWinningGoals: Int?
    let plusMinus: Int?
}

public struct NHLBoxscoreResponse: Codable {
    let teams: NHLBoxscoreTeams
}

public struct NHLBoxscoreTeams: Codable {
    let away: NHLBoxscoreTeam
    let home: NHLBoxscoreTeam
}

public struct NHLBoxscoreTeam: Codable {
    let team: NHLTeam
    let players: [String: NHLBoxscorePlayer]
}

public struct NHLBoxscorePlayer: Codable {
    let person: NHLPlayer
    let stats: NHLBoxscorePlayerStats
}

public struct NHLBoxscorePlayerStats: Codable {
    let skaterStats: NHLPlayerStat?
}
