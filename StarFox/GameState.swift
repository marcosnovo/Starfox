//
//  GameState.swift
//  StarFox
//
//  Plain gameplay model, owned and mutated by the render thread.
//  The HUD never observes this directly — GameScene pushes throttled
//  HUDSnapshot values to HUDModel on the main thread.
//

import Foundation

enum GamePhase {
    case menu, levelIntro, playing, bossEncounter, levelComplete, paused, gameOver
}

class GameState {
    var score: Int = 0
    private(set) var hiScore: Int = 0
    var shield: Int = 6
    var lives: Int = 3
    var level: Int = 1
    var phase: GamePhase = .menu
    var rings: Int = 0
    var bombs: Int = 2
    var hits: Int = 0
    var boostGauge: Double = 1.0
    var twinLaserActive: Bool = false

    let maxShield: Int = 6
    let maxBombs: Int = 3
    let levelDuration: TimeInterval = 75.0

    var bossHealth: Int = 0
    var twinLaserTimer: TimeInterval = 0
    var levelTimer: TimeInterval = 0

    static let sectorNames = ["CORNERIA", "ASTEROID BELT", "SPACE ARMADA", "SECTOR X", "VENOM"]
    var sectorName: String { Self.sectorNames[(level - 1) % Self.sectorNames.count] }

    /// World scroll speed added on top of the ship's own forward speed.
    var scrollSpeed: Float { 14.0 + Float(min(level, 8) - 1) * 2.0 }
    /// Cadence of the wave director while in the playing phase.
    var eventInterval: TimeInterval { max(1.2, 2.4 - Double(level - 1) * 0.18) }

    private static let hiScoreKey = "starfox.hiScore"

    init() {
        hiScore = UserDefaults.standard.integer(forKey: Self.hiScoreKey)
    }

    func startNewGame() {
        score = 0
        lives = 3
        level = 1
        rings = 0
        bombs = 2
        startLevel()
    }

    func startLevel() {
        shield = maxShield
        hits = 0
        boostGauge = 1.0
        twinLaserTimer = 0
        twinLaserActive = false
        bossHealth = 10 + level * 5
        levelTimer = 0
        phase = .levelIntro
    }

    func nextLevel() {
        level += 1
        bombs = min(bombs + 1, maxBombs)
        startLevel()
    }

    func registerGameOver() {
        if score > hiScore {
            hiScore = score
            UserDefaults.standard.set(score, forKey: Self.hiScoreKey)
        }
        phase = .gameOver
    }

    func makeHUDSnapshot() -> HUDSnapshot {
        HUDSnapshot(
            phase: phase,
            score: score,
            hiScore: hiScore,
            shield: shield,
            lives: lives,
            level: level,
            bombs: bombs,
            hits: hits,
            // Quantized so the throttled HUD doesn't churn on tiny changes.
            boost: (boostGauge * 20).rounded() / 20,
            twinLaser: twinLaserActive,
            sectorName: sectorName
        )
    }
}
