//
//  MazeGenerator.swift
//  EscapeThePolice
//
//  Created by Aviad on 10/07/2025.
//

import Foundation
import Combine

/// Generates new Maze instances using the centralized Maze class.
struct MazeGenerator {
    /// Produces an Observable Maze with carved paths, coins, and the thief placed at (1,1).
    /// - Parameters:
    ///   - width: Number of columns in the maze (will be rounded down to the nearest odd ≥3).
    ///   - height: Number of rows in the maze (will be rounded down to the nearest odd ≥3).
    ///   - coinCount: How many coins to scatter throughout the maze.
    /// - Returns: A fully-initialized Maze object.
    func generate(width: Int, height: Int, coinCount: Int) -> Maze {
        // Delegate to the shared Maze generator
        return Maze.generate(width: width, height: height, coinCount: coinCount)
    }
}
