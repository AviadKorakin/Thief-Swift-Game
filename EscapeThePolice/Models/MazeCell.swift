//
//  MazeCell.swift
//  EscapeThePolice
//
//  Created by Aviad on 10/07/2025.
//

import Foundation

/// A single maze cell type.
enum MazeCell: Equatable {
    case wall
    case path
    case coin
    case thief
    case enemy
}
