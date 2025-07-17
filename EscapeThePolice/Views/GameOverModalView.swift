//
//  GameOverModalView.swift
//  EscapeThePolice
//
//  Created by Aviad on 02/07/2025.
//

import SwiftUI

struct GameOverModalView: View {
    let returnToMenu: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "xmark.octagon.fill")
                .font(.system(size: 60))
                .foregroundColor(Color("FontColor"))

            Text("You Lost")
                .font(.largeTitle).bold()
                .foregroundColor(Color("FontColor"))

            Text("Better luck next time!")
                .font(.body)
                .foregroundColor(Color("FontColor"))

            Button(action: returnToMenu) {
                Label("Return to Main Menu", systemImage: "house.fill")
                    .font(.headline)
                    .foregroundColor(Color("BackgroundColor"))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color("PathColor"))
        }
        .padding(40)
        .background(
            Color("BackgroundColor"),
            in: RoundedRectangle(cornerRadius: 16)
        )
        .shadow(radius: 10)
    }
}

struct GameOverModalView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            GameOverModalView(returnToMenu: {})
                .background(Color("BackgroundColor"))
                .environment(\.colorScheme, .light)

            GameOverModalView(returnToMenu: {})
                .background(Color("BackgroundColor"))
                .environment(\.colorScheme, .dark)
        }
        .previewLayout(.sizeThatFits)
    }
}
