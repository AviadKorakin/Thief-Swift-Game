//
//  LeaderboardView.swift
//  EscapeThePolice
//
//  Created by Aviad on 29/06/2025.
//

import SwiftUI

struct LeaderboardView: View {
    @StateObject var vm = LeaderboardViewModel()

    var body: some View {
        List(vm.leaderboard) { entry in
            HStack {
                Text(entry.flag)
                    .font(.body)
                    .foregroundColor(Color("FontColor"))

                Text(entry.nickname)
                    .font(.body).fontWeight(.semibold)
                    .foregroundColor(Color("FontColor"))

                Spacer()

                Text("\(entry.totalCoins)")
                    .foregroundColor(Color("FontColor"))
            }
            .padding(.vertical, 8)
            .listRowBackground(Color("BackgroundColor"))
        }
        .background(Color("BackgroundColor"))
        .navigationTitle("Leaderboard")
        .onAppear { vm.fetchLeaderboard() }
    }
}

struct LeaderboardView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationStack {
                LeaderboardView()
            }
            .environment(\.colorScheme, .light)

            NavigationStack {
                LeaderboardView()
            }
            .environment(\.colorScheme, .dark)
        }
    }
}
