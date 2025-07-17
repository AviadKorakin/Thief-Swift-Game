import Foundation

/// Splits any diagonal moves into orthogonal steps.
struct PathSanitizer {
    static func orthogonalize(path: [Position]) -> [Position] {
        guard path.count > 1 else { return path }
        var newPath: [Position] = [path[0]]
        for i in 1..<path.count {
            let prev = path[i - 1]
            let curr = path[i]
            let dx = curr.x - prev.x
            let dy = curr.y - prev.y
            if abs(dx) == 1 && abs(dy) == 1 {
                let mid = Position(x: prev.x + dx, y: prev.y)
                newPath.append(mid)
                newPath.append(curr)
            } else {
                newPath.append(curr)
            }
        }
        return newPath
    }
}
