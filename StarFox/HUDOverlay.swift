//
//  HUDOverlay.swift
//  StarFox
//
//  SNES-style cockpit HUD on the project's limited palette: segmented
//  shield bar, boost gauge, smart bombs, lives, hit counter, squadron
//  radio panel and the mission intro / complete cards.
//

import SwiftUI

private extension Color {
    static let hudMint = Color(red: 0.88, green: 0.84, blue: 0.76)
    static let hudMintDim = Color(red: 0.68, green: 0.74, blue: 0.72)
    static let hudOrange = Color(red: 0.95, green: 0.58, blue: 0.33)
    static let hudLine = Color(red: 0.88, green: 0.84, blue: 0.76).opacity(0.25)
    static let hudPanel = Color(red: 0.08, green: 0.09, blue: 0.11).opacity(0.45)
}

private struct HUDLabel: View {
    let text: String
    var size: CGFloat = 11
    var color: Color = .hudMintDim

    var body: some View {
        Text(text)
            .font(.system(size: size, weight: .semibold, design: .monospaced))
            .foregroundColor(color)
    }
}

/// Tiny Arwing glyph used for the lives counter.
private struct ShipGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY * 0.72))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

struct HUDOverlay: View {
    @ObservedObject var state: HUDModel

    private var inCombat: Bool {
        state.phase == .playing || state.phase == .bossEncounter
    }

    var body: some View {
        ZStack {
            if inCombat {
                topInfo
                bottomInfo
                radioPanel
            }
            phaseOverlays
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    // MARK: - Combat HUD

    private var topInfo: some View {
        VStack {
            HStack(alignment: .top) {
                leftTopPanel
                Spacer()
                rightTopPanel
            }
            .padding(.horizontal, 56)
            .padding(.top, 16)
            Spacer()
        }
    }

    private var leftTopPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    HUDLabel(text: "SHIELD")
                    if state.twinLaser {
                        HUDLabel(text: "TWIN", size: 10, color: .hudOrange)
                    }
                }
                shieldBar
            }
            HStack(spacing: 5) {
                ForEach(0..<max(0, state.lives - 1), id: \.self) { _ in
                    ShipGlyph()
                        .fill(Color.hudMint)
                        .frame(width: 14, height: 11)
                }
                if state.lives <= 1 {
                    HUDLabel(text: "LAST SHIP", size: 9, color: .hudOrange)
                }
            }
        }
    }

    private var shieldBar: some View {
        HStack(spacing: 3) {
            ForEach(0..<state.maxShield, id: \.self) { index in
                Rectangle()
                    .fill(cellColor(index: index))
                    .frame(width: 18, height: 8)
            }
        }
        .padding(4)
        .background(Color.hudPanel)
        .overlay(Rectangle().stroke(Color.hudLine, lineWidth: 1))
    }

    private func cellColor(index: Int) -> Color {
        guard index < state.shield else { return Color.hudMint.opacity(0.12) }
        return state.shield <= 2 ? .hudOrange : .hudMint
    }

    private var rightTopPanel: some View {
        VStack(alignment: .trailing, spacing: 6) {
            VStack(alignment: .trailing, spacing: 2) {
                HUDLabel(text: "SCORE")
                Text(formatNumber(state.score))
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .foregroundColor(.hudMint)
            }
            HStack(spacing: 10) {
                HUDLabel(text: "HITS", size: 10)
                Text("\(state.hits)")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.hudMint)
            }
        }
    }

    private var bottomInfo: some View {
        VStack {
            Spacer()
            HStack(alignment: .bottom) {
                boostGauge
                Spacer()
                bombsView
            }
            // Inset past the touch clusters (FIRE/ROLL/BOMB right, BST/BRK left).
            .padding(.horizontal, 170)
            .padding(.bottom, 28)
        }
    }

    private var boostGauge: some View {
        VStack(alignment: .leading, spacing: 4) {
            HUDLabel(text: "BOOST", size: 10)
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.hudPanel)
                    .frame(width: 110, height: 7)
                Rectangle()
                    .fill(state.boost < 0.25 ? Color.hudOrange : Color.hudMint)
                    .frame(width: max(2, 110 * CGFloat(state.boost)), height: 7)
            }
            .overlay(Rectangle().stroke(Color.hudLine, lineWidth: 1))
            // Smooth the ~10 Hz snapshot steps into a continuous sweep.
            .animation(.linear(duration: 0.12), value: state.boost)
        }
    }

    private var bombsView: some View {
        VStack(alignment: .trailing, spacing: 4) {
            HUDLabel(text: "BOMBS", size: 10)
            HStack(spacing: 5) {
                ForEach(0..<state.maxBombs, id: \.self) { index in
                    Circle()
                        .fill(index < state.bombs ? Color.hudOrange : Color.hudOrange.opacity(0.15))
                        .frame(width: 11, height: 11)
                }
            }
        }
    }

    // MARK: - Radio

    @ViewBuilder
    private var radioPanel: some View {
        if let radio = state.radio {
            VStack {
                Spacer()
                HStack(spacing: 10) {
                    Text(radio.callsign)
                        .font(.system(size: 11, weight: .heavy, design: .monospaced))
                        .foregroundColor(.hudOrange)
                    Rectangle()
                        .fill(Color.hudLine)
                        .frame(width: 1, height: 14)
                    Text(radio.text)
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundColor(.hudMint)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.hudPanel)
                .overlay(Rectangle().stroke(Color.hudLine, lineWidth: 1))
                .padding(.bottom, 24)
            }
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.2), value: state.radio)
        }
    }

    // MARK: - Phase Overlays

    @ViewBuilder
    private var phaseOverlays: some View {
        switch state.phase {
        case .menu:          menuOverlay
        case .levelIntro:    levelIntroOverlay
        case .levelComplete: levelCompleteOverlay
        case .gameOver:      gameOverOverlay
        case .paused:        pausedOverlay
        case .bossEncounter: bossBanner
        case .playing:       EmptyView()
        }
    }

    private var menuOverlay: some View {
        ZStack {
            Color.black.opacity(0.48)
            VStack(spacing: 22) {
                ShipGlyph()
                    .fill(Color.hudOrange)
                    .frame(width: 64, height: 48)

                Text("STAR FOX")
                    .font(.system(size: 58, weight: .heavy, design: .monospaced))
                    .foregroundColor(.hudMint)

                Text("LYLAT PATROL — RAIL COMBAT")
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundColor(.hudMintDim)

                Spacer().frame(height: 10)

                Text("TAP TO LAUNCH")
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundColor(.hudMint)

                HUDLabel(text: "HI-SCORE  \(formatNumber(state.hiScore))", size: 12)
            }
        }
    }

    private var levelIntroOverlay: some View {
        ZStack {
            Color.black.opacity(0.25)
            VStack(spacing: 14) {
                HUDLabel(text: "SECTOR \(state.level)", size: 14)
                Text(state.sectorName)
                    .font(.system(size: 44, weight: .heavy, design: .monospaced))
                    .foregroundColor(.hudMint)
                Text("MISSION START")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.hudOrange)
            }
        }
    }

    private var levelCompleteOverlay: some View {
        ZStack {
            Color.black.opacity(0.25)
            VStack(spacing: 14) {
                Text("MISSION COMPLETE")
                    .font(.system(size: 38, weight: .heavy, design: .monospaced))
                    .foregroundColor(.hudMint)
                HStack(spacing: 24) {
                    HUDLabel(text: "HITS  \(state.hits)", size: 15, color: .hudMint)
                    HUDLabel(text: "BONUS  \(formatNumber(1000 + state.hits * 10))", size: 15, color: .hudOrange)
                }
                HUDLabel(text: state.sectorName + " CLEAR", size: 12)
            }
        }
    }

    private var gameOverOverlay: some View {
        ZStack {
            Color.black.opacity(0.50)
            VStack(spacing: 20) {
                Text("GAME OVER")
                    .font(.system(size: 46, weight: .heavy, design: .monospaced))
                    .foregroundColor(.hudMint)

                Text(formatNumber(state.score))
                    .font(.system(size: 30, weight: .bold, design: .monospaced))
                    .foregroundColor(.hudMint)

                if state.score >= state.hiScore && state.score > 0 {
                    HUDLabel(text: "NEW RECORD", size: 14, color: .hudOrange)
                } else {
                    HUDLabel(text: "HI-SCORE  \(formatNumber(state.hiScore))", size: 12)
                }

                Text("TAP TO RETRY")
                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    .foregroundColor(.hudMintDim)
            }
        }
    }

    private var pausedOverlay: some View {
        ZStack {
            Color.black.opacity(0.40)
            VStack(spacing: 18) {
                Text("PAUSED")
                    .font(.system(size: 46, weight: .heavy, design: .monospaced))
                    .foregroundColor(.hudMint)
                Text("TAP TO RESUME")
                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    .foregroundColor(.hudMintDim)
            }
        }
    }

    private var bossBanner: some View {
        VStack {
            HStack(spacing: 8) {
                HUDLabel(text: "⚠", size: 14, color: .hudOrange)
                Text("SECTOR GUARDIAN")
                    .font(.system(size: 15, weight: .heavy, design: .monospaced))
                    .foregroundColor(.hudOrange)
                HUDLabel(text: "⚠", size: 14, color: .hudOrange)
            }
            .padding(.top, 52)
            Spacer()
        }
    }

    private func formatNumber(_ n: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: n)) ?? "\(n)"
    }
}
