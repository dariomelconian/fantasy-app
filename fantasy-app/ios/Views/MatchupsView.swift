import SwiftUI

struct MatchupsView: View {
    @EnvironmentObject var viewModel: FantasyViewModel
    @State private var matchups: [WeeklyMatchup] = []
    @State private var selectedWeek: Int = 1
    @State private var isLoading = false

    var body: some View {
        NavigationView {
            VStack {
                if let league = viewModel.activeLeague {
                    // Week selector
                    HStack {
                        Text("Week:")
                            .foregroundColor(.subtleText)
                        Picker("Week", selection: $selectedWeek) {
                            ForEach(1...17, id: \.self) { week in
                                Text("\(week)").tag(week)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.amber)
                        
                        Spacer()
                        
                        Button("Load Matchups") {
                            Task {
                                await loadMatchups(for: league.id, week: selectedWeek)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.amber)
                    }
                    .padding(.horizontal)
                    
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.amber)
                    } else if matchups.isEmpty {
                        Text("No matchups found for week \(selectedWeek)")
                            .foregroundColor(.subtleText)
                            .padding()
                    } else {
                        List(matchups) { matchup in
                            MatchupCard(matchup: matchup)
                                .listRowBackground(Color.clear)
                        }
                        .listStyle(.plain)
                    }
                } else {
                    Text("No active league selected")
                        .foregroundColor(.subtleText)
                }
            }
            .background(Color.carbonBackground.ignoresSafeArea())
            .navigationTitle("Matchups")
            .onAppear {
                if let league = viewModel.activeLeague {
                    Task {
                        await loadMatchups(for: league.id, week: selectedWeek)
                    }
                }
            }
        }
    }
    
    private func loadMatchups(for leagueId: UUID, week: Int) async {
        isLoading = true
        defer { isLoading = false }
        
        matchups = await viewModel.fetchWeeklyMatchups(leagueId: leagueId, week: week)
    }
}

struct MatchupCard: View {
    let matchup: WeeklyMatchup
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Week \(matchup.week)")
                    .font(.headline)
                    .foregroundColor(.amber)
                Spacer()
                if let winner = matchup.winnerTeamId {
                    Text(winner == matchup.teamAId ? "Team A Wins" : "Team B Wins")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
            }
            
            HStack(alignment: .center, spacing: 20) {
                // Team A
                VStack {
                    Text("Team A")
                        .font(.subheadline)
                        .foregroundColor(.subtleText)
                    Text("\(matchup.scoreA ?? 0, specifier: "%.1f")")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(matchup.winnerTeamId == matchup.teamAId ? .green : .white)
                }
                
                Text("vs")
                    .foregroundColor(.subtleText)
                
                // Team B
                VStack {
                    Text("Team B")
                        .font(.subheadline)
                        .foregroundColor(.subtleText)
                    Text("\(matchup.scoreB ?? 0, specifier: "%.1f")")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(matchup.winnerTeamId == matchup.teamBId ? .green : .white)
                }
            }
            .padding(.vertical, 8)
        }
        .padding()
        .background(Color.charcoal)
        .cornerRadius(12)
    }
}

struct MatchupsView_Previews: PreviewProvider {
    static var previews: some View {
        MatchupsView().environmentObject(FantasyViewModel())
    }
}