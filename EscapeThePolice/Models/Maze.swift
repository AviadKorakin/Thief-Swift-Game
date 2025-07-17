//
//  Maze.swift
//  EscapeThePolice
//
//  Created by Aviad on 10/07/2025.
//

import Foundation
import Combine

/// Observable maze model that publishes grid changes and provides A* pathfinding.
final class Maze: ObservableObject {
    @Published var grid: [[MazeCell]]
    let width: Int, height: Int

    /// Incremented any time `grid` is regenerated so caches can be invalidated.
    private(set) var version: Int = 0
    private static var pathCache = [String: [Position]]()

    
    init(width: Int, height: Int, coinCount: Int) {
        self.width = width
        self.height = height
        self.grid = Array(
            repeating: Array(repeating: .wall, count: width),
            count: height
        )
        carveMaze(coinCount: coinCount)
    }
    /// Completely rebuild the maze (increments version and clears cache).
        func carveMaze(coinCount: Int) {
            // increment version and drop old paths
            version &+= 1
            Maze.pathCache.removeAll()

            // reset to all walls
            grid = Array(
                repeating: Array(repeating: .wall, count: width),
                count: height
            )
            // clear inner area
            for y in 1..<(height-1) {
                for x in 1..<(width-1) {
                    grid[y][x] = .path
                }
            }
            // recursive division
            Maze.carveByDivision(minX: 1, minY: 1,
                                 maxX: width-2, maxY: height-2,
                                 grid: &grid)
            // coins + thief
            Maze.placeCoins(count: coinCount, in: &grid)
            grid[1][1] = .thief
        }

    /// Generate a new maze with odd dimensions.
    static func generate(width: Int, height: Int, coinCount: Int) -> Maze {
           let w = width % 2 == 0 ? max(3, width-1) : width
           let h = height % 2 == 0 ? max(3, height-1) : height
           return Maze(width: w, height: h, coinCount: coinCount)
       }

    private static func carve(
        fromX x: Int, y: Int,
        w: Int, h: Int,
        grid: inout [[MazeCell]],
        visited: inout [[Bool]]
    ) {
        visited[y][x] = true
        grid[y][x] = .path

        var dirs = [(2,0),(-2,0),(0,2),(0,-2)]
        dirs.shuffle()
        for (dx, dy) in dirs {
            let nx = x + dx, ny = y + dy
            if nx > 0, ny > 0, nx < w - 1, ny < h - 1,
               !visited[ny][nx] {
                grid[y + dy/2][x + dx/2] = .path
                carve(fromX: nx, y: ny, w: w, h: h, grid: &grid, visited: &visited)
            }
        }
    }
    
    // Carve the grid by recursive division, leaving two openings per wall
        private static func carveByDivision(
            minX: Int, minY: Int,
            maxX: Int, maxY: Int,
            grid: inout [[MazeCell]]
        ) {
            // Base case: too thin to divide
            let width = maxX - minX + 1
            let height = maxY - minY + 1
            guard width > 2 && height > 2 else { return }
            
            // Decide orientation
            let horizontal = width < height
            
            if horizontal {
                // choose a horizontal wall (even row)
                let wallY = Int.random(in: (minY+1)..<maxY)
                let y = (wallY % 2 == 0) ? wallY : wallY + 1
                // carve the wall
                for x in minX...maxX {
                    grid[y][x] = .wall
                }
                // choose two distinct odd x positions for connectors
                let possible = (minX...maxX).filter { $0 % 2 == 1 }
                let holes = possible.shuffled().prefix(2)
                for x in holes {
                    grid[y][x] = .path
                }
                // recurse above and below
                carveByDivision(minX: minX, minY: minY, maxX: maxX, maxY: y-1, grid: &grid)
                carveByDivision(minX: minX, minY: y+1, maxX: maxX, maxY: maxY, grid: &grid)
            } else {
                // choose a vertical wall (even column)
                let wallX = Int.random(in: (minX+1)..<maxX)
                let x = (wallX % 2 == 0) ? wallX : wallX + 1
                // carve the wall
                for y in minY...maxY {
                    grid[y][x] = .wall
                }
                // choose two distinct odd y positions for connectors
                let possible = (minY...maxY).filter { $0 % 2 == 1 }
                let holes = possible.shuffled().prefix(2)
                for y in holes {
                    grid[y][x] = .path
                }
                // recurse left and right
                carveByDivision(minX: minX, minY: minY, maxX: x-1, maxY: maxY, grid: &grid)
                carveByDivision(minX: x+1, minY: minY, maxX: maxX, maxY: maxY, grid: &grid)
            }
        }

    private static func placeCoins(count: Int, in grid: inout [[MazeCell]]) {
        var cells = [Position]()
        for y in 0..<grid.count {
            for x in 0..<grid[y].count
            where grid[y][x] == .path && !(x == 1 && y == 1) {
                cells.append(Position(x: x, y: y))
            }
        }
        cells.shuffle()
        for i in 0..<min(count, cells.count) {
            let p = cells[i]
            grid[p.y][p.x] = .coin
        }
    }

    /// A* pathfinding with Manhattan heuristic.
    static func astarPath(
          in grid: [[MazeCell]],
          from start: Position,
          to target: Position,
          gridVersion: Int,
          maxRange: Int? = nil,
          useCache: Bool = false
        ) -> [Position]? {
            // 1) early-exit by straight-line distance
            let dx = abs(start.x - target.x)
            let dy = abs(start.y - target.y)
            if let limit = maxRange, dx + dy > limit {
                return nil
            }

            // 2) caching key
            let key = "\(start.x),\(start.y)->\(target.x),\(target.y)@\(gridVersion)"
            if useCache, let cached = pathCache[key] {
                return cached
            }

            let rows = grid.count, cols = grid.first?.count ?? 0
            if start == target { return [start] }
            if dx + dy == 1 { return [start, target] }

            struct FastNode { var g, f, parent: Int }
            let total = rows * cols
            var nodes = [FastNode](repeating: FastNode(g: .max, f: .max, parent: -1),
                                   count: total)
            var openHeap = MinHeap<Int> { nodes[$0].f < nodes[$1].f }

            func idx(_ x: Int, _ y: Int) -> Int { y * cols + x }

            let startIdx = idx(start.x, start.y)
            nodes[startIdx] = FastNode(g: 0, f: dx + dy, parent: -1)
            openHeap.insert(startIdx)

            let dirs = [(1,0),(-1,0),(0,1),(0,-1)]
            while let current = openHeap.remove() {
                if current == idx(target.x, target.y) { break }
                let cx = current % cols, cy = current / cols

                for (ddx, ddy) in dirs {
                    let nx = cx + ddx, ny = cy + ddy
                    guard nx >= 0, nx < cols,
                          ny >= 0, ny < rows,
                          grid[ny][nx] != .wall else { continue }

                    let neighbour = idx(nx, ny)
                    let tentativeG = nodes[current].g + 1

                    // extra prune: if maxRange set & g+h > maxRange, skip
                    let h = abs(nx - target.x) + abs(ny - target.y)
                    if let limit = maxRange, tentativeG + h > limit {
                        continue
                    }

                    if tentativeG < nodes[neighbour].g {
                        nodes[neighbour].g = tentativeG
                        nodes[neighbour].f = tentativeG + h
                        nodes[neighbour].parent = current
                        openHeap.insert(neighbour)
                    }
                }
            }

            // Reconstruct
            var path = [Position]()
            var cur = idx(target.x, target.y)
            if nodes[cur].parent == -1 { return nil }
            while cur != -1 {
                let x = cur % cols, y = cur / cols
                path.append(Position(x: x, y: y))
                cur = nodes[cur].parent
            }
            path.reverse()

            if useCache { pathCache[key] = path }
            return path
        }
}




private class Node: Equatable {
    let x, y: Int
    var g, h: Int
    var parent: Node?
    init(x: Int, y: Int, g: Int = 0, h: Int = 0, parent: Node?) {
        self.x = x; self.y = y; self.g = g; self.h = h; self.parent = parent
    }
    var f: Int { g + h }
    static func ==(a: Node, b: Node) -> Bool { a.x == b.x && a.y == b.y }
}

private struct MinHeap<T> {
    var elements = [T]()
    let sort: (T, T) -> Bool
    init(sort: @escaping (T, T) -> Bool) { self.sort = sort }

    mutating func insert(_ v: T) {
        elements.append(v)
        siftUp(elements.count - 1)
    }

    mutating func remove() -> T? {
        guard !elements.isEmpty else { return nil }
        elements.swapAt(0, elements.count - 1)
        let v = elements.removeLast()
        siftDown(0)
        return v
    }

    private mutating func siftUp(_ i: Int) {
        var child = i
        var parent = (child - 1) / 2
        while child > 0 && sort(elements[child], elements[parent]) {
            elements.swapAt(child, parent)
            child = parent
            parent = (child - 1) / 2
        }
    }

    private mutating func siftDown(_ i: Int) {
        var parent = i
        while true {
            let left = 2 * parent + 1, right = left + 1
            var candidate = parent
            if left < elements.count && sort(elements[left], elements[candidate]) {
                candidate = left
            }
            if right < elements.count && sort(elements[right], elements[candidate]) {
                candidate = right
            }
            if candidate == parent { return }
            elements.swapAt(parent, candidate)
            parent = candidate
        }
    }
}
