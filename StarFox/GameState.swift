//
//  GameState.swift
//  StarFox
//

import Foundation
import Combine

enum GamePhase {
    case menu, playing, bossEncounter, paused, gameOver
}

class GameState: ObservableObject {
    @Published var score: Int = 0
    @Published var shield: Int = 3
    @Published var lives: Int = 3
    @Published var level: Int = 1
    @Published var phase: GamePhase = .menu
    @Published var rings: Int = 0
    @Published var multiplier: Double = 1.0

    let maxShield: Int = 3
    var bossHealth: Int = 0
    var fireBoostTimer: TimeInterval = 0
    var levelTimer: TimeInterval = 0

    var obstacleSpeed: Float { 16.0 + Float(level - 1) * 3.0 }
    var spawnInterval: TimeInterval { max(0.4, 1.5 - Double(level - 1) * 0.15) }
    let levelDuration: TimeInterval = 60.0

    func startNewGame() {
        score = 0
        lives = 3
        level = 1
        rings = 0
        multiplier = 1.0
        startLevel()
    }

    func startLevel() {
        shield = maxShield
        bossHealth = 6 + level * 4
        levelTimer = 0
        phase = .playing
    }

    func nextLevel() {
        level += 1
        shield = min(shield + 1, maxShield)
        startLevel()
    }
}
