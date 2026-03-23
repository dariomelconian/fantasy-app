import SwiftUI

struct WaiverWireView: View {
    @EnvironmentObject var viewModel: FantasyViewModel
    @State private var waivers: [WaiverTransaction] = []
    @State private var freeAgents: [FantasyPlayer] = []
    @State private var selectedLeagueId: UUID?
    @State private var isLoading = false

    var body: some View {
        NavigationView {
            VStack {
                if let league = viewModel.leagues.first {
                    HStack {
                        Button("Load Waivers") {
                            selectedLeagueId = league.id
                            Task {
                                await loadWaivers(for: league.id)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.amber)
                        
                        Spacer()
                        
                        Button("Free Agents") {
                            Task {
                                await loadFreeAgents()
                            }
                        }
                        .buttonStyle(.bordered)
                        .tint(.charcoal)
                    }
                    .padding(.horizontal)
                    
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.amber)
                    } else {
                        List {
                            if !waivers.isEmpty {
                                Section(header: Text("Pending Claims").foregroundColor(.amber)) {
                                    ForEach(waivers.filter { $0.status == "pending" }) { waiver in
                                        WaiverClaimCard(waiver: waiver, onApprove: {
                                            Task { await approveWaiver(waiver) }
                                        }, onReject: {
                                            Task { await rejectWaiver(waiver) }
                                        })
                                    }
                                }
                            }
                            
                            if !freeAgents.isEmpty {
                                Section(header: Text("Free Agents").foregroundColor(.amber)) {
                                    ForEach(freeAgents) { player in
                                        FreeAgentCard(player: player, onClaim: {
                                            // TODO: Implement claim waiver
                                        })
                                    }
                                }
                            }
                        }
                        .listStyle(.plain)
                    }
                } else {
                    Text("No league available")
                        .foregroundColor(.subtleText)
                }
            }
            .background(Color.carbonBackground.ignoresSafeArea())
            .navigationTitle("Waiver Wire")
        }
    }
    
    private func loadWaivers(for leagueId: UUID) async {
        isLoading = true
        defer { isLoading = false }
        waivers = await viewModel.fetchWaiverQueue(leagueId: leagueId)
    }
    
    private func loadFreeAgents() async {
        isLoading = true
        defer { isLoading = false }
        // TODO: Implement fetching free agents not on rosters
        freeAgents = [] // Placeholder
    }
    
    private func approveWaiver(_ waiver: WaiverTransaction) async {
        await viewModel.processWaiver(waiver, approve: true)
        if let leagueId = selectedLeagueId {
            await loadWaivers(for: leagueId)
        }
    }
    
    private func rejectWaiver(_ waiver: WaiverTransaction) async {
        await viewModel.processWaiver(waiver, approve: false)
        if let leagueId = selectedLeagueId {
            await loadWaivers(for: leagueId)
        }
    }
}

struct WaiverClaimCard: View {
    let waiver: WaiverTransaction
    let onApprove: () -> Void
    let onReject: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Priority: \(waiver.priority)")
                .font(.subheadline)
                .foregroundColor(.amber)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Add: Player \(waiver.playerAddedId.uuidString.prefix(8))")
                        .font(.caption)
                    if let dropId = waiver.playerDroppedId {
                        Text("Drop: Player \(dropId.uuidString.prefix(8))")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                Spacer()
                VStack(spacing: 4) {
                    Button("Approve") {
                        onApprove()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .font(.caption)
                    
                    Button("Reject") {
                        onReject()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .font(.caption)
                }
            }
        }
        .padding()
        .background(Color.charcoal)
        .cornerRadius(8)
    }
}

struct FreeAgentCard: View {
    let player: FantasyPlayer
    let onClaim: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(player.fullName)
                    .font(.headline)
                Text("\(player.position ?? "N/A") • \(player.team ?? "FA")")
                    .font(.subheadline)
                    .foregroundColor(.subtleText)
            }
            Spacer()
            Button("Claim") {
                onClaim()
            }
            .buttonStyle(.borderedProminent)
            .tint(.amber)
        }
        .padding()
        .background(Color.charcoal)
        .cornerRadius(8)
    }
}

struct WaiverWireView_Previews: PreviewProvider {
    static var previews: some View {
        WaiverWireView().environmentObject(FantasyViewModel())
    }
}
