//
//  MazeService.swift
//  EscapeThePolice
//
//  Created by Aviad on 24/06/2025.
//

import Foundation

/// Centralized maze generation service.
struct MazeService {
    static let shared = MazeService()
    private init() {}

    func generate(width: Int, height: Int, coinCount: Int) -> Maze {
        Maze.generate(width: width, height: height, coinCount: coinCount)
    }
}
