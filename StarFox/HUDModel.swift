//
//  HUDModel.swift
//  StarFox
//
//  Main-thread mirror of the gameplay state for SwiftUI. The game loop
//  mutates GameState on the render thread and pushes throttled snapshots
//  here, so @Published never fires off-main and the HUD re-renders at
//  ~10 Hz instead of every frame.
//

import Foundation
import Combine

struct RadioMessage: Equatable {
    let callsign: String
    let text: String
}

struct HUDSnapshot {
    let phase: GamePhase
    let score: Int
    let hiScore: Int
    let shield: Int
    let lives: Int
    let level: Int
    let bombs: Int
    let hits: Int
    let boost: Double
    let twinLaser: Bool
    let sectorName: String
}

final class HUDModel: ObservableObject {
    @Published var phase: GamePhase = .menu
    @Published var score: Int = 0
    @Published var hiScore: Int = 0
    @Published var shield: Int = 6
    @Published var lives: Int = 3
    @Published var level: Int = 1
    @Published var bombs: Int = 2
    @Published var hits: Int = 0
    @Published var boost: Double = 1.0
    @Published var twinLaser: Bool = false
    @Published var sectorName: String = ""
    @Published var radio: RadioMessage?

    let maxShield: Int = 6
    let maxBombs: Int = 3

    private var radioClearItem: DispatchWorkItem?

    /// Applies a snapshot, only touching properties whose value changed so
    /// SwiftUI invalidates the minimum amount of view state.
    func apply(_ s: HUDSnapshot) {
        if phase != s.phase { phase = s.phase }
        if score != s.score { score = s.score }
        if hiScore != s.hiScore { hiScore = s.hiScore }
        if shield != s.shield { shield = s.shield }
        if lives != s.lives { lives = s.lives }
        if level != s.level { level = s.level }
        if bombs != s.bombs { bombs = s.bombs }
        if hits != s.hits { hits = s.hits }
        if boost != s.boost { boost = s.boost }
        if twinLaser != s.twinLaser { twinLaser = s.twinLaser }
        if sectorName != s.sectorName { sectorName = s.sectorName }
    }

    func showRadio(_ message: RadioMessage, duration: TimeInterval) {
        radioClearItem?.cancel()
        radio = message
        let clear = DispatchWorkItem { [weak self] in self?.radio = nil }
        radioClearItem = clear
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: clear)
    }
}
