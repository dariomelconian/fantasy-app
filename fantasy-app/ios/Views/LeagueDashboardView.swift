import SwiftUI

struct LeagueDashboardView: View {
    @EnvironmentObject var viewModel: FantasyViewModel

    var body: some View {
        NavigationView {
            ZStack {
                Color.carbonBackground.ignoresSafeArea()
                List {
                    Section(header: Text("Your Leagues").foregroundColor(.amber)) {
                        ForEach(viewModel.leagues) { league in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(league.name).font(.headline).foregroundColor(.white)
                                Text(league.sport + " • " + String(league.seasonYear))
                                    .font(.subheadline)
                                    .foregroundColor(.subtleText)
                            }
                            .padding(8)
                            .background(Color.charcoal)
                            .cornerRadius(10)
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .navigationTitle("Fantasy Leagues")
                .toolbar { 
                    Button(action: { viewModel.createSampleLeague() }) {
                        Label("Create", systemImage: "plus")
                    }
                }
            }
        }
    }
}

struct LeagueDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        LeagueDashboardView().environmentObject(FantasyViewModel())
    }
}
