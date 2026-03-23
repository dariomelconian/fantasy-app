import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: FantasyViewModel

    var body: some View {
        TabView {
            LeagueDashboardView()
                .tabItem {
                    Image(systemName: "sportscourt")
                    Text("Leagues")
                }

            LeagueManagementView()
                .tabItem {
                    Image(systemName: "plus.circle")
                    Text("Manage")
                }

            DraftView()
                .tabItem {
                    Image(systemName: "hand.raised.fill")
                    Text("Draft")
                }

            WaiverWireView()
                .tabItem {
                    Image(systemName: "arrow.up.arrow.down")
                    Text("Waivers")
                }

            MatchupsView()
                .tabItem {
                    Image(systemName: "trophy")
                    Text("Matchups")
                }

            LineupManagerView()
                .tabItem {
                    Image(systemName: "line.horizontal.3")
                    Text("Lineup")
                }

            StandingsView()
                .tabItem {
                    Image(systemName: "list.number")
                    Text("Standings")
                }

            TeamRosterView()
                .tabItem {
                    Image(systemName: "person.3")
                    Text("Roster")
                }

            WeeklyScoringView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Scoring")
                }
        }
        .accentColor(.ember)
        .background(Color.carbonBackground.ignoresSafeArea())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(FantasyViewModel())
    }
}
