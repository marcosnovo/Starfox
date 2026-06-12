//
//  FeedbackSystem.swift
//  StarFox
//
//  Procedural chiptune-style sound effects (no asset files — every
//  buffer is synthesized once at startup) plus haptic feedback.
//  Both systems are safe to call from the render thread: SoundSystem
//  hops to its own serial queue, Haptics hops to main.
//

import AVFoundation
import UIKit

// MARK: - Sound

enum SoundEffect: CaseIterable {
    case laser, enemyLaser, hit, damage, explosion
    case ring, powerUp, bomb, roll, radio, bossAlarm
}

final class SoundSystem {
    static let shared = SoundSystem()

    private let engine = AVAudioEngine()
    private var players: [AVAudioPlayerNode] = []
    private var buffers: [SoundEffect: AVAudioPCMBuffer] = [:]
    private var nextPlayer = 0
    private let queue = DispatchQueue(label: "starfox.sound")
    private var ready = false

    private static let sampleRate: Double = 44100

    private init() {
        queue.async { [weak self] in self?.setup() }
    }

    private func setup() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)

        guard let format = AVAudioFormat(standardFormatWithSampleRate: Self.sampleRate, channels: 1) else { return }
        for _ in 0..<8 {
            let player = AVAudioPlayerNode()
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: format)
            players.append(player)
        }
        for effect in SoundEffect.allCases {
            buffers[effect] = Self.makeBuffer(for: effect, format: format)
        }
        engine.prepare()
        do {
            try engine.start()
            ready = true
        } catch {
            ready = false // stay silent rather than crash
        }
    }

    func play(_ effect: SoundEffect, volume: Float = 1.0) {
        queue.async { [weak self] in
            guard let self, self.ready, let buffer = self.buffers[effect] else { return }
            let player = self.players[self.nextPlayer]
            self.nextPlayer = (self.nextPlayer + 1) % self.players.count
            player.stop()
            player.volume = volume
            player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
            player.play()
        }
    }

    // MARK: Synthesis

    private static func makeBuffer(for effect: SoundEffect, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        switch effect {
        case .laser:
            // Bright square-wave zap sweeping down.
            return tone(duration: 0.09, format: format) { t in
                square(sweepPhase(1500, 650, 0.09, t)) * fexp(-t * 28) * 0.45
            }
        case .enemyLaser:
            // Lower, rounder hostile shot.
            return tone(duration: 0.12, format: format) { t in
                square(sweepPhase(520, 260, 0.12, t)) * fexp(-t * 18) * 0.35
            }
        case .hit:
            // Short crunchy tap.
            return tone(duration: 0.07, format: format) { t in
                rand() * 0.55 * fexp(-t * 60) + fsin(220, t) * 0.40 * fexp(-t * 40)
            }
        case .damage:
            // Heavy low thud when the shield takes a hit.
            return tone(duration: 0.25, format: format) { t in
                Float(sin(sweepPhase(160, 80, 0.25, t))) * 0.75 * fexp(-t * 12)
                    + rand() * 0.30 * fexp(-t * 25)
            }
        case .explosion:
            return noiseBurst(duration: 0.50, format: format, lowpass: 0.90, decay: 6, gain: 1.1)
        case .bomb:
            // Deep boom: sub sine + long rumble.
            return layered(duration: 0.80, format: format,
                noise: noiseBurst(duration: 0.80, format: format, lowpass: 0.95, decay: 5, gain: 0.6)
            ) { t in
                fsin(55, t) * 0.85 * fexp(-t * 4)
            }
        case .ring:
            // Two-note chime (E5 → B5).
            return tone(duration: 0.30, format: format) { t in
                if t < 0.15 {
                    return fsin(659.25, t) * 0.40 * fexp(-t * 12)
                }
                let u = t - 0.15
                return fsin(987.77, u) * 0.40 * fexp(-u * 12)
            }
        case .powerUp:
            // Ascending C-E-G arpeggio.
            return tone(duration: 0.36, format: format) { t in
                let step = min(2, Int(t / 0.12))
                let freqs: [Double] = [523.25, 659.25, 783.99]
                let u = t - Double(step) * 0.12
                return square(2 * .pi * freqs[step] * u) * 0.22 * fexp(-u * 14)
            }
        case .roll:
            // Whoosh: noise swelling up and away.
            return noiseBurst(duration: 0.40, format: format, lowpass: 0.88, decay: 0, gain: 0.45) { t, total in
                Float(sin(.pi * t / total)) // bell envelope
            }
        case .radio:
            // Tiny double comm blip.
            return tone(duration: 0.07, format: format) { t in
                let active = t < 0.025 || (t > 0.038 && t < 0.063)
                return active ? square(2 * .pi * 950 * t) * 0.18 : 0
            }
        case .bossAlarm:
            // Alternating two-tone klaxon.
            return tone(duration: 0.90, format: format) { t in
                let freq: Double = Int(t / 0.15) % 2 == 0 ? 620 : 830
                let envelope = fexp(-max(0, t - 0.7) * 8)
                return square(2 * .pi * freq * t) * 0.25 * envelope
            }
        }
    }

    // MARK: Synth helpers

    private static func tone(
        duration: Double,
        format: AVAudioFormat,
        _ sample: (Double) -> Float
    ) -> AVAudioPCMBuffer? {
        let frames = AVAudioFrameCount(duration * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames),
              let data = buffer.floatChannelData?[0] else { return nil }
        buffer.frameLength = frames
        for i in 0..<Int(frames) {
            data[i] = max(-1, min(1, sample(Double(i) / sampleRate)))
        }
        return buffer
    }

    /// Low-passed white noise with exponential decay (or a custom envelope).
    private static func noiseBurst(
        duration: Double,
        format: AVAudioFormat,
        lowpass: Float,
        decay: Double,
        gain: Float,
        envelope: ((Double, Double) -> Float)? = nil
    ) -> AVAudioPCMBuffer? {
        let frames = AVAudioFrameCount(duration * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames),
              let data = buffer.floatChannelData?[0] else { return nil }
        buffer.frameLength = frames
        var previous: Float = 0
        for i in 0..<Int(frames) {
            let t = Double(i) / sampleRate
            previous = previous * lowpass + rand() * (1 - lowpass)
            let env = envelope?(t, duration) ?? fexp(-t * decay)
            data[i] = max(-1, min(1, previous * env * gain * 4))
        }
        return buffer
    }

    /// Mixes a tone on top of an existing noise buffer.
    private static func layered(
        duration: Double,
        format: AVAudioFormat,
        noise: AVAudioPCMBuffer?,
        _ sample: (Double) -> Float
    ) -> AVAudioPCMBuffer? {
        guard let buffer = noise, let data = buffer.floatChannelData?[0] else {
            return tone(duration: duration, format: format, sample)
        }
        for i in 0..<Int(buffer.frameLength) {
            let t = Double(i) / sampleRate
            data[i] = max(-1, min(1, data[i] + sample(t)))
        }
        return buffer
    }

    private static func sweepPhase(_ f0: Double, _ f1: Double, _ total: Double, _ t: Double) -> Double {
        2 * .pi * (f0 * t + (f1 - f0) * t * t / (2 * total))
    }

    private static func square(_ phase: Double) -> Float { sin(phase) >= 0 ? 1 : -1 }
    private static func fsin(_ freq: Double, _ t: Double) -> Float { Float(sin(2 * .pi * freq * t)) }
    private static func fexp(_ x: Double) -> Float { Float(exp(x)) }
    private static func rand() -> Float { Float.random(in: -1...1) }
}

// MARK: - Haptics

final class Haptics {
    static let shared = Haptics()

    enum Kind {
        case pickup, kill, roll, damage, bomb, gameOver
    }

    private var light: UIImpactFeedbackGenerator?
    private var medium: UIImpactFeedbackGenerator?
    private var heavy: UIImpactFeedbackGenerator?
    private var notify: UINotificationFeedbackGenerator?

    /// Generators must be created on the main thread; call once at launch.
    func warmUp() {
        DispatchQueue.main.async {
            guard self.light == nil else { return }
            self.light = UIImpactFeedbackGenerator(style: .light)
            self.medium = UIImpactFeedbackGenerator(style: .medium)
            self.heavy = UIImpactFeedbackGenerator(style: .heavy)
            self.notify = UINotificationFeedbackGenerator()
        }
    }

    func play(_ kind: Kind) {
        DispatchQueue.main.async {
            switch kind {
            case .pickup, .kill: self.light?.impactOccurred()
            case .roll:          self.medium?.impactOccurred()
            case .damage, .bomb: self.heavy?.impactOccurred()
            case .gameOver:      self.notify?.notificationOccurred(.error)
            }
        }
    }
}
