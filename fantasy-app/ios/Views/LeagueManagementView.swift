import SwiftUI

struct LeagueManagementView: View {
    @EnvironmentObject var viewModel: FantasyViewModel
    @State private var leagueName: String = ""
    @State private var inviteCode: String = ""
    @State private var userId = UUID()
    @State private var statusMessage: String = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("Create New League")
                .font(.headline)
                .foregroundColor(.amber)

            TextField("League name", text: $leagueName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            Button(action: {
                Task {
                    let invite = "INV-\(UUID().uuidString.prefix(5))"
                    await viewModel.createLeague(name: leagueName, sport: "NHL", ownerId: userId, inviteCode: invite)
                    statusMessage = "Created league: \(leagueName) (code: \(invite))"
                    leagueName = ""
                }
            }) {
                Text("Create League")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.ember)
                    .foregroundColor(.white)
                    .cornerRadius(9)
                    .padding(.horizontal)
            }

            Divider().background(Color.subtleText)

            Text("Join League")
                .font(.headline)
                .foregroundColor(.amber)

            TextField("League ID", text: $inviteCode)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            Button(action: {
                Task {
                    await viewModel.joinLeague(inviteCode: inviteCode, userId: userId)
                    statusMessage = "Joined league by code: \(inviteCode)"
                    inviteCode = ""
                }
            }) {
                Text("Join League")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.ember)
                    .foregroundColor(.white)
                    .cornerRadius(9)
                    .padding(.horizontal)
            }

            if !statusMessage.isEmpty {
                Text(statusMessage)
                    .foregroundColor(.subtleText)
                    .font(.footnote)
                    .padding(.top)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("My Leagues")
                    .font(.headline)
                    .foregroundColor(.amber)

                ForEach(viewModel.leagues) { league in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(league.name)
                                .foregroundColor(.white)
                            Text("Code: \(league.inviteCode ?? "")")
                                .font(.caption)
                                .foregroundColor(.subtleText)
                        }
                        Spacer()
                    }
                    .padding(8)
                    .background(Color.charcoal)
                    .cornerRadius(8)
                }
            }

            Spacer()
        }
        .padding(.top)
        .background(Color.carbonBackground.ignoresSafeArea())
        .navigationTitle("League Management")
    }
}

struct LeagueManagementView_Previews: PreviewProvider {
    static var previews: some View {
        LeagueManagementView().environmentObject(FantasyViewModel())
    }
}
