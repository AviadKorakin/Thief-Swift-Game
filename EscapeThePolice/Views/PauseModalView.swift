//
//  PauseModalView.swift
//  EscapeThePolice
//
//  Created by Aviad on 10/07/2025.
//
import SwiftUI

struct PauseModalView: View {
    let onResume: () -> Void
    let onFinish: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "pause.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(Color("FontColor"))

            Text("Game Paused")
                .font(.largeTitle).bold()
                .foregroundColor(Color("FontColor"))

            Button(action: onResume) {
                Label("Resume", systemImage: "play.fill")
                    .font(.headline)
                    .foregroundColor(Color("BackgroundColor"))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color("PathColor"))

            Button(action: onFinish) {
                Label("Finish Game", systemImage: "xmark.circle")
                    .font(.headline)
                    .foregroundColor(Color("SecondaryFontColor"))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.bordered)
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

struct PauseModalView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PauseModalView(
                onResume: {},
                onFinish: {}
            )
            .background(Color("BackgroundColor"))
            .environment(\.colorScheme, .light)

            PauseModalView(
                onResume: {},
                onFinish: {}
            )
            .background(Color("BackgroundColor"))
            .environment(\.colorScheme, .dark)
        }
        .previewLayout(.sizeThatFits)
    }
}
