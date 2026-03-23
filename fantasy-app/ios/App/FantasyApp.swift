import SwiftUI

@main
struct FantasyApp: App {
    @StateObject private var viewModel = FantasyViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
    }
}
