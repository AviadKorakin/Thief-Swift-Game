// Views/MazeGridView.swift
import SwiftUI

/// Renders static maze walls, paths, and coins with GPU caching.
struct MazeGridView: View {
    let grid: [[MazeCell]]
    let cellSize: CGSize

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<grid.count, id: \.self) { y in
                HStack(spacing: 0) {
                    ForEach(0..<grid[y].count, id: \.self) { x in
                        cellView(grid[y][x])
                            .frame(
                                width:  cellSize.width,
                                height: cellSize.height
                            )
                    }
                }
            }
        }
        .drawingGroup() // offload rendering to GPU
    }

    @ViewBuilder
    private func cellView(_ cell: MazeCell) -> some View {
        switch cell {
        case .wall:
            Color("WallColor")
        case .path:
            Color("PathColor")
        case .coin:
            ZStack {
                Color("PathColor")
                Image("coin")
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .frame(
                        width:  cellSize.width * 0.6,
                        height: cellSize.height * 0.6
                    )
            }
        default:
            Color("PathColor")
        }
    }
}

struct MazeGridView_Previews: PreviewProvider {
    static var previews: some View {
        let sample: [[MazeCell]] = [
            [.wall, .wall, .wall],
            [.wall, .path, .coin],
            [.wall, .wall, .wall]
        ]
        MazeGridView(
            grid: sample,
            cellSize: CGSize(width: 40, height: 40)
        )
    }
}
