//
//  HorizonHUD.swift
//  Horizon — Design System
//
//  Reusable HUD components for the gameplay screen. Reference these
//  rather than re-inventing the layouts inline. Specs match
//  `design-system/components.md` and `screens.md`.
//

import SwiftUI

// MARK: - Background

/// Full-bleed canonical background. Use on EVERY gameplay/menu screen.
/// Never replace with a procedural sky or SVG.
public struct HorizonBackground: View {
    public init() {}
    public var body: some View {
        Image("HorizonBackground")
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
    }
}

// MARK: - HUD readout (label + value)

public struct HUDReadout: View {
    public enum Size { case large, small }
    let label: String
    let value: String
    let size: Size
    let alignment: HorizontalAlignment
    let valueColor: Color

    public init(
        label: String,
        value: String,
        size: Size = .large,
        alignment: HorizontalAlignment = .leading,
        valueColor: Color = Horizon.Ink.bone
    ) {
        self.label = label
        self.value = value
        self.size = size
        self.alignment = alignment
        self.valueColor = valueColor
    }

    public var body: some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(label)
                .font(Horizon.Typography.label)
                .horizonLabelTracking()
                .foregroundColor(Horizon.Ink.dim)
            Text(value)
                .font(size == .large ? Horizon.Typography.readoutLg : Horizon.Typography.readoutSm)
                .horizonTitleTracking(fontSize: size == .large ? 38 : 28)
                .foregroundColor(valueColor)
        }
        .horizonHUDTextShadow()
    }
}

// MARK: - ScorePanel (top-left)

public struct ScorePanel: View {
    let score: Int
    let rings: Int
    public init(score: Int, rings: Int) {
        self.score = score
        self.rings = rings
    }
    public var body: some View {
        VStack(alignment: .leading, spacing: Horizon.Space.s4) {
            HUDReadout(label: "SCORE", value: score.formatted(), size: .large)
            HUDReadout(label: "RINGS", value: "\(rings)",        size: .small)
        }
    }
}

// MARK: - WavePanel (top-right)

public struct WavePanel: View {
    let wave: Int
    let multiplier: Double
    public init(wave: Int, multiplier: Double) {
        self.wave = wave
        self.multiplier = multiplier
    }
    public var body: some View {
        VStack(alignment: .trailing, spacing: Horizon.Space.s4) {
            HUDReadout(
                label: "WAVE",
                value: String(format: "%02d", wave),
                size: .large,
                alignment: .trailing
            )
            HUDReadout(
                label: "MULTIPLIER",
                value: String(format: "×%.1f", multiplier),
                size: .small,
                alignment: .trailing,
                valueColor: multiplier >= 2.0 ? Horizon.Accent.ember : Horizon.Ink.bone
            )
        }
    }
}

// MARK: - Reticle (center)

public struct Reticle: View {
    let size: CGFloat
    let locked: Bool
    public init(size: CGFloat = 56, locked: Bool = false) {
        self.size = size
        self.locked = locked
    }
    public var body: some View {
        let stroke = locked ? Horizon.Accent.flare : Horizon.Ink.bone
        Canvas { ctx, sz in
            let w = sz.width, h = sz.height
            let bracketW: CGFloat = w * 0.18
            var left = Path()
            left.move(to: CGPoint(x: bracketW, y: 0))
            left.addLine(to: CGPoint(x: 0, y: 0))
            left.addLine(to: CGPoint(x: 0, y: h))
            left.addLine(to: CGPoint(x: bracketW, y: h))
            var right = Path()
            right.move(to: CGPoint(x: w - bracketW, y: 0))
            right.addLine(to: CGPoint(x: w, y: 0))
            right.addLine(to: CGPoint(x: w, y: h))
            right.addLine(to: CGPoint(x: w - bracketW, y: h))
            ctx.stroke(left,  with: .color(stroke), lineWidth: Horizon.Stroke.thin)
            ctx.stroke(right, with: .color(stroke), lineWidth: Horizon.Stroke.thin)
            // crosshair
            let cx = w / 2, cy = h / 2, arm: CGFloat = 6
            var cross = Path()
            cross.move(to: CGPoint(x: cx - arm, y: cy)); cross.addLine(to: CGPoint(x: cx + arm, y: cy))
            cross.move(to: CGPoint(x: cx, y: cy - arm)); cross.addLine(to: CGPoint(x: cx, y: cy + arm))
            ctx.stroke(cross, with: .color(stroke), lineWidth: Horizon.Stroke.thin)
        }
        .frame(width: size, height: size * 0.56)
        .horizonIconShadow()
    }
}

// MARK: - ShieldBar (bottom-left)

public struct ShieldBar: View {
    /// 0...1
    let value: Double
    public init(value: Double) { self.value = max(0, min(1, value)) }

    public var body: some View {
        VStack(alignment: .leading, spacing: Horizon.Space.s2) {
            Text("SHIELD")
                .font(Horizon.Typography.label)
                .horizonLabelTracking()
                .foregroundColor(Horizon.Ink.dim)
                .horizonHUDTextShadow()

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: Horizon.Radius.r1)
                    .stroke(Horizon.Ink.bone, lineWidth: Horizon.Stroke.thin)
                GeometryReader { g in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(value < 0.30 ? Horizon.Accent.warn : Horizon.Ink.bone)
                        .frame(width: max(0, (g.size.width - 4) * value),
                               height: g.size.height - 4)
                        .padding(2)
                        .animation(Horizon.Motion.easeOut, value: value)
                }
            }
            .frame(width: 200, height: 12)
        }
    }
}

// MARK: - WeaponsRack (bottom-right)

public struct WeaponsRack: View {
    public enum SlotState { case `default`, active, disabled }
    let slots: [SlotState]
    public init(slots: [SlotState]) { self.slots = slots }

    public var body: some View {
        VStack(alignment: .trailing, spacing: Horizon.Space.s2) {
            Text("WEAPONS")
                .font(Horizon.Typography.label)
                .horizonLabelTracking()
                .foregroundColor(Horizon.Ink.dim)
                .horizonHUDTextShadow()
            HStack(spacing: 14) {
                ForEach(Array(slots.enumerated()), id: \.offset) { _, state in
                    WeaponGlyph(state: state)
                }
            }
        }
    }
}

private struct WeaponGlyph: View {
    let state: WeaponsRack.SlotState
    var color: Color {
        switch state {
        case .default:  return Horizon.Ink.bone
        case .active:   return Horizon.Accent.ember
        case .disabled: return Horizon.Ink.ghost
        }
    }
    var body: some View {
        // Simple missile glyph — replace with SF Symbol or vector asset if available.
        Triangle()
            .stroke(color, lineWidth: Horizon.Stroke.thin)
            .frame(width: 18, height: 18)
            .horizonIconShadow()
    }
}

private struct Triangle: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

// MARK: - Glass panel

public struct HorizonPanel<Content: View>: View {
    let content: Content
    public init(@ViewBuilder content: () -> Content) { self.content = content() }
    public var body: some View {
        content
            .padding(Horizon.Space.s6)
            .background(
                RoundedRectangle(cornerRadius: Horizon.Radius.r2)
                    .fill(Horizon.Surface.panel)
                    .background(.ultraThinMaterial,
                                in: RoundedRectangle(cornerRadius: Horizon.Radius.r2))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Horizon.Radius.r2)
                    .strokeBorder(Horizon.Surface.hairline, lineWidth: Horizon.Stroke.hairline)
            )
    }
}
