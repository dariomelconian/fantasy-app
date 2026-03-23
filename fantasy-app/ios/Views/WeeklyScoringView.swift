import SwiftUI

struct WeeklyScoringView: View {
    @EnvironmentObject var viewModel: FantasyViewModel
    @State private var week = 1
    @State private var status = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Stepper("Week: \(week)", value: $week, in: 1...40)
                    .padding(.horizontal)

                Button("Run weekly scoring") {
                    Task {
                        await viewModel.runWeeklyScoring(week: week)
                        status = "Weekly scoring executed for week \(week)"
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.ember)
                .foregroundColor(.black)
                .cornerRadius(10)
                .padding(.horizontal)

                if !status.isEmpty {
                    Text(status)
                        .foregroundColor(.subtleText)
                        .font(.footnote)
                        .padding(.horizontal)
                }

                Spacer()
            }
            .navigationTitle("Weekly Scoring")
            .background(Color.carbonBackground.ignoresSafeArea())
        }
    }
}

struct WeeklyScoringView_Previews: PreviewProvider {
    static var previews: some View {
        WeeklyScoringView().environmentObject(FantasyViewModel())
    }
}
