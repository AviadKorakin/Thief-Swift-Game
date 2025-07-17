import SwiftUI
import Combine
import FirebaseDatabase
import FirebaseAuth

// MARK: — Configuration constants
extension GameViewModel {
    static let kThiefDelay: TimeInterval      = 0.08
    static let kEnemyDelay:  TimeInterval     = 0.7
    static let kMinCoins:     Int             = 5
    static let kCoinDensityDivisor: Int       = 10
    static let kDetectionRange: Int           = 4
}

enum EnemyState {
    case patrolling, chasing, returning
}

struct Enemy: Identifiable {
    let id = UUID()
    var patrolPath: [Position]        // fixed patrol route
    var path: [Position]              // current active path (patrol/chase/return)
    var returnPath: [Position]?       // stored return corridor when returning
    var currentIndex: Int = 0         // index in `path`
    var state: EnemyState = .patrolling
    
}

/// ViewModel coordinating maze, player, and police logic.
final class GameViewModel: ObservableObject {
    @Published private(set) var maze: Maze
    @Published var grid: [[MazeCell]] = []
    @Published var collectedCoins: Int = 0
    @Published var totalCoins: Int = 0
    @Published var cumulativeCoins: Int = 0
    @Published var thiefPosition: Position = Position(x: 1, y: 1)
    @Published var enemies: [Enemy] = []
    @Published var currentLevel: Int = 1
    @Published var isGameOver: Bool = false
    @Published var isPaused: Bool = false
    
    private let userUID: String
    private let db = Database.database().reference()
    
    private var coinPositions: Set<Position> = []


    private var cancellables = Set<AnyCancellable>()
    private var currentMoveID = UUID()
    private var patrolEpoch = 0

    
    

    init(userUID: String, cols: Int, rows: Int, coinCount: Int) {
        self.userUID = userUID
        maze = Maze.generate(width: cols, height: rows, coinCount: coinCount)
        grid = maze.grid
        totalCoins = maze.grid.flatMap { $0 }.filter { $0 == .coin }.count
        fetchUserData()
        
        for y in 0..<grid.count {
            for x in 0..<grid[y].count {
                if grid[y][x] == .coin {
                    coinPositions.insert(Position(x: x, y: y))
                }
            }
        }

        $maze
          .flatMap { $0.$grid }
          .receive(on: DispatchQueue.main)
          .assign(to: &$grid)

        setupEnemies()
        startEnemyPatrols()
    }
    
    func fetchUserData() {
        db.child("users").child(userUID).observeSingleEvent(of: .value) { snapshot in
            if let data = snapshot.value as? [String: Any],
               let level = data["level"] as? Int,
               let cumulativeCoins = data["totalCoins"] as? Int {
                self.currentLevel = level
                self.cumulativeCoins = cumulativeCoins
            } else {
                // New user: initialize in Firebase
                self.db.child("users").child(self.userUID).setValue(["totalCoins": 0, "level": 1])
                self.currentLevel = 1
                self.cumulativeCoins = 0
            }
        }
    }
    // MARK: — Player movement

    func moveTo(x: Int, y: Int) {
        currentMoveID = UUID()

           // figure out our true destination:
           var destination = Position(x: x, y: y)
           if grid[y][x] == .wall {
               // if it was a wall tap, pick the nearest open spot
               if let alt = nearestValidPosition(from: destination) {
                   destination = alt
               }
               // otherwise we'll just bail (no open spots anywhere!)
           }

           // now run A*
           let start = thiefPosition
        guard let path = Maze.astarPath(
                in:           grid,
                from:         start,
                to:           destination,
                gridVersion:  maze.version,
                maxRange:     nil,         // no range limit for player
                useCache:     true         // or false if you prefer
            ) else { return }

           animate(path, moveID: currentMoveID)
    }

    private func animate(_ path: [Position], moveID: UUID) {
        DispatchQueue.global(qos: .userInitiated).async {
            var prev = self.thiefPosition
            for pos in path {
                // existing bail-out checks
                if moveID != self.currentMoveID || self.isGameOver { return }
                
                // ← if paused, wait here until unpaused
                while self.isPaused {
                    Thread.sleep(forTimeInterval: 0.05)
                }
                
                Thread.sleep(forTimeInterval: Self.kThiefDelay)
                DispatchQueue.main.async {
                    guard moveID == self.currentMoveID, !self.isGameOver else { return }
                    // clear old thief location
                    self.maze.grid[prev.y][prev.x] = .path
                    // move thief
                    self.thiefPosition = pos
                    if self.maze.grid[pos.y][pos.x] == .coin {
                        self.collectedCoins += 1
                        self.coinPositions.remove(pos)
                        if self.collectedCoins == self.totalCoins {
                            self.completeLevel()
                            self.nextLevel()
                            self.currentMoveID = UUID()
                        }
                    }
                    self.maze.grid[pos.y][pos.x] = .thief
                    self.checkForCollision()
                    prev = pos
                }
            }
        }
    }

    // MARK: — Police setup & AI

    private func setupEnemies() {
        enemies.removeAll()

        let rows = grid.count
        let cols = grid.first?.count ?? 0
        let thiefStart = Position(x: 1, y: 1)

        // 1) Build forbidden positions by walking up/down/left/right from the thief
        var forbidden = Set<Position>()

        // Up
        var y = thiefStart.y - 1
        while y >= 0, grid[y][thiefStart.x] != .wall {
            forbidden.insert(Position(x: thiefStart.x, y: y))
            y -= 1
        }
        // Down
        y = thiefStart.y + 1
        while y < rows, grid[y][thiefStart.x] != .wall {
            forbidden.insert(Position(x: thiefStart.x, y: y))
            y += 1
        }
        // Left
        var x = thiefStart.x - 1
        while x >= 0, grid[thiefStart.y][x] != .wall {
            forbidden.insert(Position(x: x, y: thiefStart.y))
            x -= 1
        }
        // Right
        x = thiefStart.x + 1
        while x < cols, grid[thiefStart.y][x] != .wall {
            forbidden.insert(Position(x: x, y: thiefStart.y))
            x += 1
        }

        // 2) Gather all open cells except start, skipping forbidden AND any within detection range
        var spawnCells: [Position] = []
        for yy in 0..<rows {
            for xx in 0..<cols {
                let pos = Position(x: xx, y: yy)

                // a) Must be open path and not the thief start or in forbidden
                guard grid[yy][xx] == .path,
                      pos != thiefStart,
                      !forbidden.contains(pos)
                else { continue }

                // b) Exclude detection‐range neighbors via A* with maxRange
                if let chase = Maze.astarPath(
                       in:           grid,
                       from:         pos,
                       to:           thiefStart,
                       gridVersion:  maze.version,
                       maxRange:     Self.kDetectionRange,
                       useCache:     true
                   ),
                   chase.count - 1 <= Self.kDetectionRange
                {
                    continue
                }

                spawnCells.append(pos)
            }
        }

        // 3) Shuffle + pick up to four
        spawnCells.shuffle()
        let spawnCount = min(spawnCells.count, Int.random(in: 1...4))

        // 4) Build patrols for each spawn
        for i in 0..<spawnCount {
            let start = spawnCells[i]
            let hSpan = scanRange(from: start, dx: 1, dy: 0)
            let vSpan = scanRange(from: start, dx: 0, dy: 1)
            let corridor = (hSpan.count >= vSpan.count ? hSpan : vSpan)
                .sorted { a, b in
                    (hSpan.count >= vSpan.count) ? (a.x < b.x) : (a.y < b.y)
                }
            guard corridor.count > 1 else { continue }

            var patrol = corridor
            patrol += corridor.dropFirst().dropLast().reversed()

            let enemy = Enemy(patrolPath: patrol, path: patrol, returnPath: nil)
            let home = patrol[0]
            maze.grid[home.y][home.x] = .enemy
            enemies.append(enemy)
        }
    }
    
    private func startEnemyPatrols() {
        patrolEpoch += 1
        let epochAtStart = patrolEpoch
        for idx in enemies.indices {
                advanceEnemy(at: idx, epoch: epochAtStart)
            }
    }

    private func advanceEnemy(at idx: Int, epoch: Int) {
        guard !isGameOver, epoch == patrolEpoch else { return }    // bail if level changed
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.kEnemyDelay) {
            guard epoch == self.patrolEpoch, idx < self.enemies.count else { return}
            if self.isPaused {
                  return self.advanceEnemy(at: idx, epoch: epoch)
              }
            var enemy = self.enemies[idx]
            let pos = enemy.path[enemy.currentIndex]
            // 1) Transition states
            switch enemy.state {
            case .patrolling:
                if let chase = Maze.astarPath(
                               in:           self.grid,
                               from:         pos,
                               to:           self.thiefPosition,
                               gridVersion:  self.maze.version,
                               maxRange:     Self.kDetectionRange,
                               useCache:     true
                           ),
                   chase.count - 1 <= Self.kDetectionRange {
                    enemy.state = .chasing
                    // preserve position in the new chase path
                    if let newIdx = chase.firstIndex(of: pos) {
                        enemy.currentIndex = newIdx
                    } else {
                        enemy.currentIndex = 0
                    }
                    enemy.path = chase
                }

            case .chasing:
                // still within detection range?
                if let chase = Maze.astarPath(
                               in:           self.grid,
                               from:         pos,
                               to:           self.thiefPosition,
                               gridVersion:  self.maze.version,
                               maxRange:     Self.kDetectionRange,
                               useCache:     true
                           ),
                   chase.count - 1 <= Self.kDetectionRange {
                    // … your existing “stay in chasing” logic …
                    if let newIdx = chase.firstIndex(of: pos) {
                        enemy.currentIndex = newIdx
                    } else {
                        enemy.currentIndex = 0
                    }
                    enemy.path = chase
                }
                else {
                    // LOST SIGHT: are we still on our original patrol corridor?
                    if let patrolIdx = enemy.patrolPath.firstIndex(of: pos) {
                        // YES—snap right back to patrolling *at that same index*
                        enemy.state        = .patrolling
                        enemy.path         = enemy.patrolPath
                        enemy.currentIndex = patrolIdx
                        enemy.returnPath   = nil
                    }
                    else {
                        // NO—actually off‐corridor, so build a returnPath
                        enemy.state = .returning
                        if enemy.returnPath == nil {
                            // find nearest patrol waypoint, compute path back
                            if let nearest = enemy.patrolPath
                                 .enumerated()
                                 .min(by: { a, b in
                                   abs(a.element.x - pos.x) + abs(a.element.y - pos.y)
                                   < abs(b.element.x - pos.x) + abs(b.element.y - pos.y)
                                 })?.offset,
                               let back = Maze.astarPath(
                                   in:           self.grid,
                                   from:         pos,
                                   to:           enemy.patrolPath[nearest],
                                   gridVersion:  self.maze.version,
                                   maxRange:     nil,          // no limit for return trips
                                   useCache:     true
                               ),
                               back.count > 1
                            {
                                enemy.returnPath = back
                            }
                        }
                        // if we got a valid returnPath, start following it
                        if let back = enemy.returnPath {
                            enemy.path = back
                            enemy.currentIndex = 0
                        } else {
                            // FAILED to build a path back—fallback to patrol,
                            // but resume at whichever patrol index we're on now
                            enemy.state        = .patrolling
                            enemy.path         = enemy.patrolPath
                            enemy.currentIndex = enemy.patrolPath.firstIndex(of: pos) ?? 0
                            enemy.returnPath   = nil
                        }
                    }
                }

            case .returning:
                break
            }

            // 2) Step one cell
            if !enemy.path.isEmpty {
                let prev = pos
                  let nextIndex: Int = (enemy.state == .patrolling)
                      ? (enemy.currentIndex + 1) % enemy.path.count
                      : min(enemy.currentIndex + 1, enemy.path.count - 1)
                  let nxt = enemy.path[nextIndex]

                  // restore a coin only if it really remains
                  if self.coinPositions.contains(prev) {
                      self.maze.grid[prev.y][prev.x] = .coin
                  } else {
                      self.maze.grid[prev.y][prev.x] = .path
                  }

                  self.maze.grid[nxt.y][nxt.x] = .enemy
                  enemy.currentIndex = nextIndex

                // 3) If returning and reached end, restore patrol
                if enemy.state == .returning,
                   let ret = enemy.returnPath,
                   enemy.currentIndex == ret.count - 1 {
                    enemy.state = .patrolling
                    enemy.path = enemy.patrolPath
                    // resume at correct patrol index
                    if let last = ret.last,
                       let idx0 = enemy.patrolPath.firstIndex(of: last) {
                        enemy.currentIndex = idx0
                    } else {
                        enemy.currentIndex = 0
                    }
                    enemy.returnPath = nil
                }
            }
            self.checkForCollision()
            self.enemies[idx] = enemy
            self.advanceEnemy(at: idx, epoch: epoch)
        }
    }

    /// Scan a straight corridor until walls stop you.
    private func scanRange(from start: Position, dx: Int, dy: Int) -> [Position] {
        var list: [Position] = [start]
        let rows = grid.count, cols = grid.first?.count ?? 0
        var x = start.x, y = start.y
        
        // forward
        while true {
            let nx = x + dx, ny = y + dy
            guard nx >= 0, nx < cols,
                  ny >= 0, ny < rows,
                  grid[ny][nx] != .wall
            else { break }
            list.append(Position(x: nx, y: ny))
            x = nx; y = ny
        }
        
        // backward
        x = start.x; y = start.y
        while true {
            let nx = x - dx, ny = y - dy
            guard nx >= 0, nx < cols,
                  ny >= 0, ny < rows,
                  grid[ny][nx] != .wall
            else { break }
            list.insert(Position(x: nx, y: ny), at: 0)
            x = nx; y = ny
        }
        
        return list
    }
    
    private func nearestValidPosition(from tap: Position) -> Position? {
           let rows = grid.count, cols = grid.first?.count ?? 0
           var visited = Set<Position>()
           var queue: [Position] = [tap]
           visited.insert(tap)

           let directions = [(1,0),(-1,0),(0,1),(0,-1)]
           while !queue.isEmpty {
               let current = queue.removeFirst()
               // If this cell isn’t a wall, we can use it
               if grid[current.y][current.x] != .wall {
                   return current
               }
               // Otherwise enqueue neighbours
               for (dx, dy) in directions {
                   let nx = current.x + dx
                   let ny = current.y + dy
                   let neigh = Position(x: nx, y: ny)
                   guard nx >= 0, nx < cols, ny >= 0, ny < rows,
                         !visited.contains(neigh) else { continue }
                   visited.insert(neigh)
                   queue.append(neigh)
               }
           }
           return nil
       }
    
    private func completeLevel() {
        cumulativeCoins += collectedCoins
        db.child("users").child(userUID)
          .runTransactionBlock { currentData in
            var userData = (currentData.value as? [String:Any]) ?? [:]
            let oldLevel      = userData["level"] as? Int ?? 1
            userData["level"]      = oldLevel + 1
            userData["totalCoins"] = self.cumulativeCoins
            currentData.value      = userData
            return .success(withValue: currentData)
          }
    }
    
    func nextLevel() {
        // 1) Pick a new random coin count in 20...40
        let newCoinCount = Int.random(in: 20...40)
        
        // 2) Generate the maze with that randomized coin count
        maze = Maze.generate(
            width:  maze.width,
            height: maze.height,
            coinCount: newCoinCount
        )
        
        // 3) Reset all the usual state
        grid            = maze.grid
        collectedCoins  = 0
        totalCoins      = newCoinCount
        thiefPosition   = Position(x: 1, y: 1)
        coinPositions   = Set(grid.enumerated().flatMap { y, row in
            row.enumerated().compactMap { x, cell in
                cell == .coin ? Position(x: x, y: y) : nil
            }
        })
        
        // 4) Restart your enemies and patrols
        setupEnemies()
        startEnemyPatrols()
        
        // 5) Bump up the level counter
        currentLevel += 1
    }
    private func checkForCollision() {
            for enemy in enemies {
                if enemy.path[enemy.currentIndex] == thiefPosition {
                    // collision!
                    isGameOver = true
                    return
                }
            }
        }
}

