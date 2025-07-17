//
//  HUDView.swift
//  EscapeThePolice
//
//  Created by Aviad on 24/06/2025.
//

import SwiftUI

/// Heads-up display for coins, level, and pause action.
struct HUDView: View {
    @Binding var collected: Int
    @Binding var total: Int
    @Binding var level: Int
    let onPause: () -> Void     // pause callback

    var body: some View {
        HStack(spacing: 20) {
            // Coins counter
            HStack(spacing: 4) {
                Image("coin")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundColor(Color("FontColor"))
                Text("\(collected)/\(total)")
                    .font(.headline)
                    .foregroundColor(Color("FontColor"))
            }

            Spacer()

            // Level indicator
            HStack(spacing: 4) {
                Image(systemName: "flag.fill")
                    .font(.headline)
                    .foregroundColor(Color("FontColor"))
                Text("Level \(level)")
                    .font(.headline)
                    .foregroundColor(Color("FontColor"))
            }

            Spacer()

            // Pause button
            Button(action: onPause) {
                Image(systemName: "pause.fill")
                    .font(.title)
                    .foregroundColor(Color("FontColor"))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal)
        .frame(height: 60)
        .background(Color("BackgroundColor"))
    }
}

struct HUDView_Previews: PreviewProvider {
    @State static var coins = 3
    @State static var total = 10
    @State static var level = 1

    static var previews: some View {
        Group {
            HUDView(
                collected: $coins,
                total:     $total,
                level:     $level,
                onPause:   { }
            )
            .background(Color("BackgroundColor"))
            .environment(\.colorScheme, .light)

            HUDView(
                collected: $coins,
                total:     $total,
                level:     $level,
                onPause:   { }
            )
            .background(Color("BackgroundColor"))
            .environment(\.colorScheme, .dark)
        }
        .previewLayout(.sizeThatFits)
    }
}
