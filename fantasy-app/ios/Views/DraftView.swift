import SwiftUI

struct DraftView: View {
    @EnvironmentObject var viewModel: FantasyViewModel

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Snake Draft Status")
                    .font(.headline)
                    .foregroundColor(.amber)

                if let draft = viewModel.activeDraft {
                    Text("League: \(draft.leagueName)")
                        .foregroundColor(.white)
                    Text("Round: \(draft.currentRound) / \(draft.totalRounds)")
                        .foregroundColor(.subtleText)
                    Text("Next pick: \(draft.nextTeamName)")
                        .foregroundColor(.amber)

                    Button(action: { viewModel.advanceDraft() }) {
                        Text("Advance pick")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.ember)
                            .foregroundColor(.black)
                            .cornerRadius(10)
                    }
                } else {
                    Text("No draft running yet. Tap create in leagues to bootstrap.")
                        .foregroundColor(.subtleText)
                }

                Spacer()
            }
            .padding()
            .background(Color.charcoal.ignoresSafeArea())
            .navigationTitle("Draft Room")
        }
    }
}

struct DraftView_Previews: PreviewProvider {
    static var previews: some View {
        DraftView().environmentObject(FantasyViewModel())
    }
}
