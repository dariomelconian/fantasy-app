import Foundation
import SwiftUI

final class FantasyViewModel: ObservableObject {
    @Published var leagues: [FantasyLeague] = []
    @Published var activeDraft: DraftProgress?

    private var draftOrder: [String] = []

    init() {
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
}

struct DraftProgress {
    var leagueName: String
    var currentRound: Int
    var totalRounds: Int
    var pickIndex: Int
    var teams: [String]

    var nextTeamName: String { teams[pickIndex] }
}
