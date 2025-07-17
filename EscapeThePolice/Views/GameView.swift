// Views/GameView.swift
import SwiftUI

private let kCellSize: CGFloat    = 32
private let kPlayerScale: CGFloat = 0.8
private let kEnemyScale: CGFloat  = 0.8

struct GameView: View {
    @StateObject private var vm: GameViewModel
    @Environment(\.dismiss) private var dismiss

    init(userUID: String) {
        let cols = Int(UIScreen.main.bounds.width  / kCellSize)
        let rows = Int((UIScreen.main.bounds.height - 60) / kCellSize)
        let coins = Int.random(in: 20...40)
        _vm = StateObject(
            wrappedValue: GameViewModel(
                userUID: userUID,
                cols: cols,
                rows: rows,
                coinCount: coins
            )
        )
    }

    var body: some View {
        ZStack {
            // Background uses asset-catalog color
            Color("BackgroundColor").ignoresSafeArea()

            VStack(spacing: 0) {
                HUDView(
                    collected: $vm.collectedCoins,
                    total:     $vm.totalCoins,
                    level:     $vm.currentLevel,
                    onPause:   { vm.isPaused = true }
                )

                GeometryReader { geo in
                    if vm.grid.isEmpty {
                        EmptyView()
                    } else {
                        let cols     = vm.grid[0].count
                        let rows     = vm.grid.count
                        let cellSize = CGSize(
                            width:  geo.size.width  / CGFloat(cols),
                            height: geo.size.height / CGFloat(rows)
                        )

                        ZStack(alignment: .topLeading) {
                            MazeGridView(grid: vm.grid, cellSize: cellSize)

                            // Thief
                            Image("player")
                                .resizable()
                                .scaledToFit()
                                .frame(
                                    width:  cellSize.width  * kPlayerScale,
                                    height: cellSize.height * kPlayerScale
                                )
                                .offset(
                                    x: CGFloat(vm.thiefPosition.x) * cellSize.width,
                                    y: CGFloat(vm.thiefPosition.y) * cellSize.height
                                )
                                .animation(
                                    .linear(duration: GameViewModel.kThiefDelay),
                                    value: vm.thiefPosition
                                )

                            // Police enemies
                            ForEach(vm.enemies) { e in
                                let idx = e.currentIndex % e.path.count
                                let p   = e.path[idx]
                                Image("police")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(
                                        width:  cellSize.width  * kEnemyScale,
                                        height: cellSize.height * kEnemyScale
                                    )
                                    .offset(
                                        x: CGFloat(p.x) * cellSize.width,
                                        y: CGFloat(p.y) * cellSize.height
                                    )
                                    .animation(.linear(duration: GameViewModel.kEnemyDelay), value: p)
                            }
                        }
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onEnded { v in
                                    let x = Int(v.location.x / cellSize.width)
                                    let y = Int(v.location.y / cellSize.height)
                                    if x >= 0, x < cols, y >= 0, y < rows {
                                        vm.moveTo(x: x, y: y)
                                    }
                                }
                        )
                    }
                }
            }

            // Game Over Overlay
            if vm.isGameOver {
                Color("BackgroundColor")
                    .opacity(0.6)
                    .ignoresSafeArea()

                GameOverModalView {
                    dismiss()
                }
                .foregroundColor(Color("FontColor"))
                .transition(.scale)
            }

            // Pause Overlay
            if vm.isPaused {
                Color("BackgroundColor")
                    .opacity(0.6)
                    .ignoresSafeArea()

                PauseModalView(
                    onResume: { vm.isPaused = false },
                    onFinish: { dismiss() }
                )
                .foregroundColor(Color("FontColor"))
                .transition(.scale)
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .animation(.easeInOut, value: vm.isGameOver || vm.isPaused)
    }
}
