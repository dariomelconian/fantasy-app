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

            DraftView()
                .tabItem {
                    Image(systemName: "hand.raised.fill")
                    Text("Draft")
                }

            Text("Waivers")
                .tabItem {
                    Image(systemName: "arrow.up.arrow.down")
                    Text("Waivers")
                }

            Text("Standings")
                .tabItem {
                    Image(systemName: "list.number")
                    Text("Standings")
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
