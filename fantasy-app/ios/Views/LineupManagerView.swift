import SwiftUI

struct LineupManagerView: View {
    @EnvironmentObject var viewModel: FantasyViewModel
    @State private var roster: [RosterEntry] = []
    @State private var players: [UUID: FantasyPlayer] = [:]
    @State private var isLoading = false
    @State private var draggedPlayer: RosterEntry?

    var body: some View {
        NavigationView {
            VStack {
                if let team = viewModel.leagueTeams.first {
                    HStack {
                        Text("Team: \(team.name)")
                            .font(.headline)
                            .foregroundColor(.amber)
                        Spacer()
                        Button("Refresh") {
                            Task {
                                await loadRoster(for: team.id)
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
                        ScrollView {
                            VStack(spacing: 16) {
                                // Starters Section
                                LineupSection(
                                    title: "Starters",
                                    slot: "starter",
                                    players: roster.filter { $0.lineupSlot == "starter" },
                                    playersDict: players,
                                    onDrop: { playerId, slot in
                                        Task { await updatePlayerSlot(playerId: playerId, slot: slot) }
                                    }
                                )
                                
                                // Bench Section
                                LineupSection(
                                    title: "Bench",
                                    slot: "bench",
                                    players: roster.filter { $0.lineupSlot == "bench" },
                                    playersDict: players,
                                    onDrop: { playerId, slot in
                                        Task { await updatePlayerSlot(playerId: playerId, slot: slot) }
                                    }
                                )
                                
                                // IR Section (Injured Reserve)
                                LineupSection(
                                    title: "IR",
                                    slot: "ir",
                                    players: roster.filter { $0.lineupSlot == "ir" },
                                    playersDict: players,
                                    onDrop: { playerId, slot in
                                        Task { await updatePlayerSlot(playerId: playerId, slot: slot) }
                                    }
                                )
                            }
                            .padding()
                        }
                    }
                } else {
                    Text("No team selected")
                        .foregroundColor(.subtleText)
                }
            }
            .background(Color.carbonBackground.ignoresSafeArea())
            .navigationTitle("Lineup Manager")
            .onAppear {
                if let team = viewModel.leagueTeams.first {
                    Task {
                        await loadRoster(for: team.id)
                    }
                }
            }
        }
    }
    
    private func loadRoster(for teamId: UUID) async {
        isLoading = true
        defer { isLoading = false }
        
        await viewModel.loadRoster(teamId: teamId)
        roster = viewModel.selectedTeamRoster
        
        // Load player details
        let playerIds = roster.map { $0.playerId }
        if !playerIds.isEmpty {
            players = await viewModel.fetchPlayers(playerIds: playerIds).reduce(into: [:]) { $0[$1.id] = $1 }
        }
    }
    
    private func updatePlayerSlot(playerId: UUID, slot: String) async {
        guard let entry = roster.first(where: { $0.playerId == playerId }) else { return }
        await viewModel.updateLineupSlot(rosterEntryId: entry.id, newSlot: slot)
        // Reload roster to reflect changes
        if let teamId = entry.teamId {
            await loadRoster(for: teamId)
        }
    }
}

struct LineupSection: View {
    let title: String
    let slot: String
    let players: [RosterEntry]
    let playersDict: [UUID: FantasyPlayer]
    let onDrop: (UUID, String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.amber)
            
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.charcoal.opacity(0.5))
                    .frame(height: max(60, CGFloat(players.count) * 50 + 20))
                
                VStack(spacing: 4) {
                    ForEach(players) { entry in
                        if let player = playersDict[entry.playerId] {
                            PlayerCard(player: player, slot: entry.lineupSlot)
                                .onDrag {
                                    NSItemProvider(object: entry.id.uuidString as NSString)
                                }
                        }
                    }
                    
                    // Drop zone
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.clear)
                        .frame(height: 30)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.amber.opacity(0.3), lineWidth: 2)
                                .overlay(
                                    Text("Drop here")
                                        .font(.caption)
                                        .foregroundColor(.amber.opacity(0.7))
                                )
                        )
                        .onDrop(of: [.text], isTargeted: nil) { providers in
                            guard let provider = providers.first else { return false }
                            _ = provider.loadObject(ofClass: NSString.self) { string, _ in
                                if let idString = string as? String, let uuid = UUID(uuidString: idString) {
                                    DispatchQueue.main.async {
                                        onDrop(uuid, slot)
                                    }
                                }
                            }
                            return true
                        }
                }
                .padding(8)
            }
        }
    }
}

struct PlayerCard: View {
    let player: FantasyPlayer
    let slot: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(player.fullName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("\(player.position ?? "N/A") • \(player.team ?? "FA")")
                    .font(.caption)
                    .foregroundColor(.subtleText)
            }
            Spacer()
            Text(slot.uppercased())
                .font(.caption)
                .foregroundColor(.amber)
                .padding(4)
                .background(Color.amber.opacity(0.2))
                .cornerRadius(4)
        }
        .padding(8)
        .background(Color.charcoal)
        .cornerRadius(6)
    }
}

struct LineupManagerView_Previews: PreviewProvider {
    static var previews: some View {
        LineupManagerView().environmentObject(FantasyViewModel())
    }
}