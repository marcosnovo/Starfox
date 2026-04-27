//
//  HUDOverlay.swift
//  StarFox
//

import SwiftUI

private extension Color {
    static let hudWhiteMain = Color.white.opacity(0.88)
    static let hudWhiteSoft = Color.white.opacity(0.75)
    static let hudWhiteFaint = Color.white.opacity(0.62)
    static let hudLine = Color.white.opacity(0.20)
    static let hudPanel = Color.black.opacity(0.08)
}

struct HUDOverlay: View {
    @ObservedObject var state: GameState

    var body: some View {
        ZStack {
            if state.phase == .playing || state.phase == .bossEncounter {
                crosshair
            }
            topInfo
            bottomInfo
            phaseOverlays
        }
        .ignoresSafeArea()
    }

    // MARK: - Playing HUD

    private var topInfo: some View {
        VStack {
            HStack(alignment: .top) {
                leftTopPanel
                Spacer()
                rightTopPanel
            }
            .padding(.horizontal, 22)
            .padding(.top, 20)
            Spacer()
        }
        .allowsHitTesting(false)
    }

    private var leftTopPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text("SCORE")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(.hudWhiteFaint)
                Text(formatNumber(state.score))
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .foregroundColor(.hudWhiteMain)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("RINGS")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(.hudWhiteFaint)
                Text("\(state.rings)")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(.hudWhiteMain)
            }
        }
    }

    private var rightTopPanel: some View {
        VStack(alignment: .trailing, spacing: 14) {
            VStack(alignment: .trailing, spacing: 2) {
                Text("WAVE")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(.hudWhiteFaint)
                Text("\(state.level)")
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .foregroundColor(.hudWhiteMain)
            }
            VStack(alignment: .trailing, spacing: 2) {
                Text("MULTIPLIER")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(.hudWhiteFaint)
                Text(String(format: "x%.1f", state.multiplier))
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(.hudWhiteMain)
            }
        }
    }

    private var bottomInfo: some View {
        VStack {
            Spacer()
            HStack(alignment: .bottom) {
                shieldView
                Spacer()
                weaponsView
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 22)
        }
        .allowsHitTesting(false)
    }

    private var shieldView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text("SHIELD")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(.hudWhiteFaint)
                Text("\(state.shield)/\(state.maxShield)")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.hudWhiteSoft)
            }

            GeometryReader { geo in
                let ratio = CGFloat(max(0, min(state.shield, state.maxShield))) / CGFloat(state.maxShield)
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .stroke(Color.hudLine, lineWidth: 0.8)
                        .background(
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .fill(Color.hudPanel)
                        )
                    RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                        .fill(Color.hudWhiteMain)
                        .frame(width: max(4, (geo.size.width - 4) * ratio), height: geo.size.height - 4)
                        .padding(2)
                }
            }
            .frame(width: 120, height: 6)
        }
    }

    private var weaponsView: some View {
        VStack(alignment: .trailing, spacing: 5) {
            Text("WEAPONS")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(.hudWhiteFaint)
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.hudWhiteMain)
                        .frame(width: 14, height: 3)
                }
            }
        }
    }

    private var crosshair: some View {
        GeometryReader { geo in
            let cx = geo.size.width / 2
            let cy = geo.size.height * 0.42
            let size: CGFloat = 20
            let thickness: CGFloat = 1.5
            let gap: CGFloat = 5

            Canvas { ctx, _ in
                let color = Color.white.opacity(0.75)
                ctx.fill(
                    Path(CGRect(x: cx - thickness / 2, y: cy - size, width: thickness, height: size - gap)),
                    with: .color(color)
                )
                ctx.fill(
                    Path(CGRect(x: cx - thickness / 2, y: cy + gap, width: thickness, height: size - gap)),
                    with: .color(color)
                )
                ctx.fill(
                    Path(CGRect(x: cx - size, y: cy - thickness / 2, width: size - gap, height: thickness)),
                    with: .color(color)
                )
                ctx.fill(
                    Path(CGRect(x: cx + gap, y: cy - thickness / 2, width: size - gap, height: thickness)),
                    with: .color(color)
                )
            }
        }
        .allowsHitTesting(false)
    }

    private func formatNumber(_ n: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: n)) ?? "\(n)"
    }

    // MARK: - Phase Overlays

    @ViewBuilder
    private var phaseOverlays: some View {
        switch state.phase {
        case .menu:         menuOverlay
        case .gameOver:     gameOverOverlay
        case .paused:       pausedOverlay
        case .bossEncounter: bossWarning
        case .playing:      EmptyView()
        }
    }

    private var menuOverlay: some View {
        ZStack {
            Color.black.opacity(0.48)
            VStack(spacing: 32) {
                Text("STAR FOX")
                    .font(.system(size: 58, weight: .heavy, design: .monospaced))
                    .foregroundColor(.hudWhiteMain)

                Text("DEEP SPACE MISSION")
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundColor(.hudWhiteSoft)

                Spacer().frame(height: 16)

                Text("TAP TO START")
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundColor(.hudWhiteSoft)
            }
        }
    }

    private var gameOverOverlay: some View {
        ZStack {
            Color.black.opacity(0.50)
            VStack(spacing: 22) {
                Text("GAME OVER")
                    .font(.system(size: 46, weight: .heavy, design: .monospaced))
                    .foregroundColor(.hudWhiteMain)

                Text(formatNumber(state.score))
                    .font(.system(size: 30, weight: .bold, design: .monospaced))
                    .foregroundColor(.hudWhiteMain)

                Text("TAP TO RETRY")
                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    .foregroundColor(.hudWhiteSoft)
            }
        }
    }

    private var pausedOverlay: some View {
        ZStack {
            Color.black.opacity(0.40)
            VStack(spacing: 18) {
                Text("PAUSED")
                    .font(.system(size: 46, weight: .heavy, design: .monospaced))
                    .foregroundColor(.hudWhiteMain)
                Text("TAP TO RESUME")
                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    .foregroundColor(.hudWhiteSoft)
            }
        }
    }

    private var bossWarning: some View {
        VStack {
            Spacer()
            Text("⚠  BOSS INCOMING  ⚠")
                .font(.system(size: 22, weight: .heavy, design: .monospaced))
                .foregroundColor(.hudWhiteSoft)
                .padding(.bottom, 55)
        }
    }
}
