import SwiftUI

struct TeamRosterView: View {
    @EnvironmentObject var viewModel: FantasyViewModel
    @State private var selectedTeamId: UUID?
    @State private var playerIdText: String = ""
    @State private var statusMessage: String = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                if let leagueId = viewModel.activeLeague?.id {
                    Button("Load Teams") {
                        Task {
                            await viewModel.loadTeams(leagueId: leagueId)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.amber)
                    .padding(.top)
                }

                Picker("Team", selection: $selectedTeamId) {
                    Text("Select team").tag(UUID?.none)
                    ForEach(viewModel.leagueTeams) { team in
                        Text(team.name).tag(Optional(team.id))
                    }
                }
                .pickerStyle(.menu)
                .padding(.horizontal)

                if let teamId = selectedTeamId {
                    Button("Load roster") {
                        Task { await viewModel.loadRoster(teamId: teamId) }
                    }
                    .buttonStyle(.bordered)
                    .padding(.horizontal)
                }

                if let teamId = selectedTeamId {
                    HStack {
                        TextField("Player UUID", text: $playerIdText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)

                        Button("Add") {
                            if let playerId = UUID(uuidString: playerIdText) {
                                Task {
                                    await viewModel.pickPlayer(teamId: teamId, playerId: playerId)
                                    statusMessage = "Added player to roster";
                                    playerIdText = ""
                                }
                            } else {
                                statusMessage = "Invalid player UUID"
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.ember)
                    }
                }

                Text(statusMessage)
                    .foregroundColor(.subtleText)
                    .font(.footnote)

                List(viewModel.selectedTeamRoster) { entry in
                    HStack {
                        Text(entry.playerId.uuidString.prefix(5))
                            .foregroundColor(.white)
                        Spacer()
                        Button("Drop") {
                            Task {
                                await viewModel.dropRosterEntry(entry)
                                statusMessage = "Dropped roster entry"
                            }
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                    }
                    .padding(8)
                    .background(Color.charcoal)
                    .cornerRadius(8)
                }
                .listStyle(.plain)

                Spacer()
            }
            .background(Color.carbonBackground.ignoresSafeArea())
            .navigationTitle("Team Roster")
        }
    }
}

struct TeamRosterView_Previews: PreviewProvider {
    static var previews: some View {
        TeamRosterView().environmentObject(FantasyViewModel())
    }
}
