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
                    await viewModel.createLeague(name: leagueName, sport: "NHL", ownerId: userId)
                    statusMessage = "Created league: \(leagueName)"
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
                    if let leagueId = UUID(uuidString: inviteCode) {
                        await viewModel.joinLeague(leagueId: leagueId, userId: userId)
                        statusMessage = "Joined league: \(inviteCode)"
                        inviteCode = ""
                    } else {
                        statusMessage = "Invalid league id"
                    }
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
