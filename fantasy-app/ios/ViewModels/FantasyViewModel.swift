import Foundation
import SwiftUI

final class FantasyViewModel: ObservableObject {
    @Published var leagues: [FantasyLeague] = []
    @Published var activeDraft: DraftProgress?

    private var draftOrder: [String] = []
    private let leagueService: SupabaseLeagueService

    init(supabaseClient: SupabaseClient = SupabaseClient(config: SupabaseConfig(urlString: "https://your-project-ref.supabase.co", anonKey: "YOUR_ANON_KEY"))) {
        self.leagueService = SupabaseLeagueService(supabaseClient: supabaseClient)
        // sample seed
        createSampleLeague()
    }

    func createSampleLeague() {
        let league = FantasyLeague(
            id: UUID(),
            name: "Carbon Ember League",
            sport: "NHL",
            ownerId: UUID(),
            rosterSize: 15,
            draftRounds: 15,
            seasonYear: Calendar.current.component(.year, from: Date()),
            draftStarted: true,
            draftCompleted: false,
            waiverPeriodHours: 72
        )

        if !leagues.contains(where: { $0.id == league.id }) {
            leagues.append(league)
        }

        startDraft(for: league)
    }

    func startDraft(for league: FantasyLeague) {
        let teams = (1...8).map { "Team \($0)" }
        draftOrder = teams
        activeDraft = DraftProgress(leagueName: league.name,
                                     currentRound: 1,
                                     totalRounds: league.draftRounds,
                                     pickIndex: 0,
                                     teams: teams)
    }

    func advanceDraft() {
        guard var draft = activeDraft else { return }
        draft.pickIndex += 1

        if draft.pickIndex >= draft.teams.count {
            draft.currentRound += 1
            if draft.currentRound > draft.totalRounds {
                activeDraft = nil
                return
            }

            // reverse order every round to follow snake pattern
            draft.teams.reverse()
            draft.pickIndex = 0
        }

        activeDraft = draft
    }

    func isDraftPickForTeam(_ team: String) -> Bool {
        guard let draft = activeDraft else { return false }
        return draft.nextTeamName == team
    }

    func loadLeagues(for userId: UUID) async {
        do {
            let result = try await leagueService.fetchUserLeagues(userId: userId)
            DispatchQueue.main.async {
                self.leagues = result
            }
        } catch {
            print("Failed to fetch leagues: \(error)")
        }
    }

    func createLeague(name: String, sport: String = "NHL", ownerId: UUID) async {
        let input = CreateLeagueInput(
            name: name,
            sport: sport,
            owner_id: ownerId,
            roster_size: 15,
            draft_rounds: 15,
            season_year: Calendar.current.component(.year, from: Date()),
            waiver_period_hours: 72
        )

        do {
            let league = try await leagueService.createLeague(input: input)
            DispatchQueue.main.async {
                self.leagues.append(league)
            }
        } catch {
            print("Error creating league: \(error)")
        }
    }

    func joinLeague(leagueId: UUID, userId: UUID) async {
        do {
            _ = try await leagueService.joinLeague(leagueId: leagueId, userId: userId)
            await loadLeagues(for: userId)
        } catch {
            print("Error joining league: \(error)")
        }
    }

    func updateLeagueDraftStatus(leagueId: UUID, started: Bool? = nil, completed: Bool? = nil) async {
        do {
            _ = try await leagueService.updateLeagueStatus(leagueId: leagueId, draftStarted: started, draftCompleted: completed)
        } catch {
            print("Error updating league status: \(error)")
        }
    }

    func fetchWaiverQueue(leagueId: UUID) async -> [WaiverTransaction] {
        do {
            return try await leagueService.fetchWaiverTransactions(leagueId: leagueId)
        } catch {
            print("Failed fetching waivers: \(error)")
            return []
        }
    }

    func submitWaiver(_ input: WaiverRequestInput) async {
        do {
            _ = try await leagueService.submitWaiverRequest(input)
        } catch {
            print("Failed submitting waiver: \(error)")
        }
    }

    func loadStandings(leagueId: UUID, week: Int) async -> [StandingRow] {
        do {
            return try await leagueService.fetchStandings(leagueId: leagueId, week: week)
        } catch {
            print("Failed loading standings: \(error)")
            return []
        }
    }

    func resolveWaivers(_ queue: [WaiverRequestInput]) -> [WaiverRequestInput] {
        FantasyEngine.resolveWaiverQueue(queue)
    }

    func calculateStandings(after matchups: [WeeklyMatchupResultInput]) -> [StandingUpdate] {
        FantasyEngine.calculateStandingsFromMatchups(matchups)
    }
}

struct DraftProgress {
    var leagueName: String
    var currentRound: Int
    var totalRounds: Int
    var pickIndex: Int
    var teams: [String]

    var nextTeamName: String { teams[pickIndex] }
}
