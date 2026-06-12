//
//  GameState.swift
//  StarFox
//

import Foundation
import Combine

enum GamePhase {
    case menu, levelIntro, playing, bossEncounter, levelComplete, paused, gameOver
}

struct RadioMessage: Equatable {
    let callsign: String
    let text: String
}

class GameState: ObservableObject {
    @Published var score: Int = 0
    @Published var hiScore: Int = 0
    @Published var shield: Int = 6
    @Published var lives: Int = 3
    @Published var level: Int = 1
    @Published var phase: GamePhase = .menu
    @Published var rings: Int = 0
    @Published var bombs: Int = 2
    @Published var hits: Int = 0
    @Published var boostGauge: Double = 1.0
    @Published var twinLaserActive: Bool = false
    @Published var radio: RadioMessage?

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

    private var radioClearItem: DispatchWorkItem?
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

    func postRadio(_ callsign: String, _ text: String, duration: TimeInterval = 3.4) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.radioClearItem?.cancel()
            self.radio = RadioMessage(callsign: callsign, text: text)
            let clear = DispatchWorkItem { [weak self] in self?.radio = nil }
            self.radioClearItem = clear
            DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: clear)
        }
    }
}
