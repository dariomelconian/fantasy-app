import Foundation
import SwiftUI

final class FantasyViewModel: ObservableObject {
    @Published var leagues: [FantasyLeague] = []
    @Published var activeDraft: DraftProgress?
    @Published var activeLeague: FantasyLeague?

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
            waiverPeriodHours: 72,
            inviteCode: "CARBON" 
        )

        if !leagues.contains(where: { $0.id == league.id }) {
            leagues.append(league)
        }

        startDraft(for: league)
        activeLeague = league
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

    func executeDraftPick(playerId: UUID) async {
        guard let draft = activeDraft,
              let league = activeLeague else { return }

        // ensure league teams loaded
        if leagueTeams.isEmpty {
            await loadTeams(leagueId: league.id)
        }

        let currentTeamName = draft.nextTeamName
        guard let currentTeam = leagueTeams.first(where: { $0.name == currentTeamName }) else {
            print("No team mapped for: \(currentTeamName)")
            return
        }

        do {
            _ = try await leagueService.createDraftPick(leagueId: league.id, teamId: currentTeam.id, round: draft.currentRound, pick: draft.pickIndex + 1, playerId: playerId)
            await leagueService.pickPlayer(teamId: currentTeam.id, playerId: playerId)
            await persistDraftStatus(currentRound: draft.currentRound, totalRounds: draft.totalRounds)
            self.advanceDraft()
        } catch {
            print("Draft pick persistence failed: \(error)")
        }
    }

    private func persistDraftStatus(currentRound: Int, totalRounds: Int) async {
        guard let league = activeLeague else { return }
        do {
            _ = try await leagueService.updateLeagueStatus(leagueId: league.id, draftStarted: true, draftCompleted: currentRound >= totalRounds)
        } catch {
            print("Failed to update league draft status: \(error)")
        }
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

    func createLeague(name: String, sport: String = "NHL", ownerId: UUID, inviteCode: String? = nil) async {
        let input = CreateLeagueInput(
            name: name,
            sport: sport,
            owner_id: ownerId,
            roster_size: 15,
            draft_rounds: 15,
            season_year: Calendar.current.component(.year, from: Date()),
            waiver_period_hours: 72,
            invite_code: inviteCode ?? "INV-\(UUID().uuidString.prefix(8))"
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

    func joinLeague(inviteCode: String, userId: UUID) async {
        do {
            guard let league = try await leagueService.fetchLeagueByInviteCode(inviteCode) else {
                print("League not found for code: \(inviteCode)")
                return
            }

            _ = try await leagueService.joinLeague(leagueId: league.id, userId: userId)
            await loadLeagues(for: userId)
        } catch {
            print("Error joining league by invite code: \(error)")
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

    @Published var selectedTeamRoster: [RosterEntry] = []
    @Published var leagueTeams: [FantasyTeam] = []

    func loadStandings(leagueId: UUID, week: Int) async -> [StandingRow] {
        do {
            return try await leagueService.fetchStandings(leagueId: leagueId, week: week)
        } catch {
            print("Failed loading standings: \(error)")
            return []
        }
    }

    func loadTeams(leagueId: UUID) async {
        do {
            self.leagueTeams = try await leagueService.fetchTeams(leagueId: leagueId)
        } catch {
            print("Failed loading teams: \(error)")
            self.leagueTeams = []
        }
    }

    func loadRoster(teamId: UUID) async {
        do {
            self.selectedTeamRoster = try await leagueService.fetchRosterEntries(teamId: teamId)
        } catch {
            print("Failed loading roster: \(error)")
            self.selectedTeamRoster = []
        }
    }

    func pickPlayer(teamId: UUID, playerId: UUID, slot: String = "N/A") async {
        do {
            _ = try await leagueService.pickPlayer(teamId: teamId, playerId: playerId, slot: slot)
            await loadRoster(teamId: teamId)
        } catch {
            print("Failed picking player: \(error)")
        }
    }

    func dropRosterEntry(_ rosterEntry: RosterEntry) async {
        do {
            _ = try await leagueService.dropPlayer(rosterEntryId: rosterEntry.id)
            await loadRoster(teamId: rosterEntry.teamId)
        } catch {
            print("Failed dropping player: \(error)")
        }
    }

    func processWaiver(_ waiver: WaiverTransaction, approve: Bool) async {
        do {
            let status = approve ? "approved" : "rejected"
            _ = try await leagueService.processWaiverDecision(waiverId: waiver.id, status: status)
        } catch {
            print("Failed processing waiver: \(error)")
        }
    }

    func runWeeklyScoring(week: Int, season: String = "20242025") async {
        guard let leagueId = activeLeague?.id else { return }
        do {
            let results = try await leagueService.calculateWeeklyMatchups(leagueId: leagueId, week: week, season: season)
            print("Weekly matchup results computed for week \(week):", results)
            // an app could also refresh standings here
        } catch {
            print("Failed running weekly scoring: \(error)")
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
