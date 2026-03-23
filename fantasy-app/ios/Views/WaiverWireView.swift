import SwiftUI

struct WaiverWireView: View {
    @EnvironmentObject var viewModel: FantasyViewModel
    @State private var waivers: [WaiverTransaction] = []
    @State private var selectedLeagueId: UUID?

    var body: some View {
        NavigationView {
            VStack {
                if let league = viewModel.leagues.first {
                    Button("Load waivers for \(league.name)") {
                        selectedLeagueId = league.id
                        Task {
                            waivers = await viewModel.fetchWaiverQueue(leagueId: league.id)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.amber)
                    .padding()
                }

                List(waivers) { waiver in
                    VStack(alignment: .leading) {
                        Text("Team: \(waiver.teamId.uuidString.prefix(5))...")
                        Text("Added: \(waiver.playerAddedId.uuidString.prefix(5))")
                        Text("Priority: \(waiver.priority)")
                            .font(.caption)
                            .foregroundColor(.subtleText)
                    }
                    .padding(6)
                    .background(Color.charcoal)
                    .cornerRadius(8)
                    .listRowBackground(Color.clear)
                }
                .listStyle(.plain)
                .background(Color.carbonBackground)
            }
            .background(Color.carbonBackground.ignoresSafeArea())
            .navigationTitle("Waiver Wire")
        }
    }
}

struct WaiverWireView_Previews: PreviewProvider {
    static var previews: some View {
        WaiverWireView().environmentObject(FantasyViewModel())
    }
}
