import SwiftUI

struct StandingsView: View {
    @EnvironmentObject var viewModel: FantasyViewModel
    @State private var standings: [StandingRow] = []
    @State private var week: Int = 1

    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                HStack {
                    Stepper("Week: \(week)", value: $week, in: 1...20)
                        .padding(.horizontal)
                    Button("Refresh") {
                        if let leagueId = viewModel.leagues.first?.id {
                            Task { standings = await viewModel.loadStandings(leagueId: leagueId, week: week) }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.amber)
                    .padding(.trailing)
                }

                List(standings) { row in
                    HStack {
                        Text(row.teamId.uuidString.prefix(5))
                            .bold()
                            .foregroundColor(.white)
                        Spacer()
                        Text("W:\(row.wins) L:\(row.losses) T:\(row.ties) P:\(row.points, specifier: "%.1f")")
                            .foregroundColor(.subtleText)
                    }
                    .padding(8)
                    .background(Color.charcoal)
                    .cornerRadius(8)
                    .listRowBackground(Color.clear)
                }
                .listStyle(.plain)
            }
            .background(Color.carbonBackground.ignoresSafeArea())
            .navigationTitle("Standings")
        }
    }
}

struct StandingsView_Previews: PreviewProvider {
    static var previews: some View {
        StandingsView().environmentObject(FantasyViewModel())
    }
}
