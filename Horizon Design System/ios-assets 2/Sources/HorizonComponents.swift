//
//  HorizonComponents.swift
//  Horizon — Design System
//
//  Reusable SwiftUI components mirroring `design-system/components.md`.
//  Use these in screens; do NOT inline ad-hoc HUD layouts.
//

import SwiftUI

// MARK: - Background scene (canonical)

/// Full-bleed reference background. EVERY gameplay/menu screen sits on top of this.
/// Never redraw the scene in SwiftUI shapes.
public struct HorizonBackground: View {
    public init() {}
    public var body: some View {
        Image("HorizonBackground")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .ignoresSafeArea()
            .background(Horizon.Silhouette.void) // letterbox color if image is masked
    }
}

// MARK: - HUD label / readout primitives

public struct HUDLabel: View {
    let text: String
    public init(_ text: String) { self.text = text }
    public var body: some View {
        Text(text)
            .font(Horizon.Type.label)
            .horizonLabelTracking()
            .foregroundColor(Horizon.Ink.dim)
            .horizonHUDTextShadow()
    }
}

public struct HUDReadout: View {
    let label: String
    let value: String
    let valueFont: Font
    let valueColor: Color
    let alignment: HorizontalAlignment

    public init(
        label: String,
        value: String,
        valueFont: Font = Horizon.Type.readoutLg,
        valueColor: Color = Horizon.Ink.bone,
        alignment: HorizontalAlignment = .leading
    ) {
        self.label = label
        self.value = value
        self.valueFont = valueFont
        self.valueColor = valueColor
        self.alignment = alignment
    }

    public var body: some View {
        VStack(alignment: alignment, spacing: 2) {
            HUDLabel(label)
            Text(value)
                .font(valueFont)
                .kerning(-0.6) // -0.02em-ish at this size
                .foregroundColor(valueColor)
                .horizonHUDTextShadow()
        }
    }
}

// MARK: - Score / Wave panels (top corners)

public struct ScorePanel: View {
    let score: Int
    let rings: Int
    let compact: Bool
    public init(score: Int, rings: Int, compact: Bool = true) {
        self.score = score; self.rings = rings; self.compact = compact
    }
    public var body: some View {
        VStack(alignment: .leading, spacing: Horizon.Space.s4) {
            HUDReadout(
                label: "SCORE",
                value: score.formatted(.number),
                valueFont: compact ? Horizon.Type.readoutLg : Horizon.Type.readoutXL
            )
            HUDReadout(
                label: "RINGS",
                value: rings.formatted(.number),
                valueFont: Horizon.Type.readoutSm
            )
        }
    }
}

public struct WavePanel: View {
    let wave: Int
    let multiplier: Double
    let compact: Bool
    public init(wave: Int, multiplier: Double, compact: Bool = true) {
        self.wave = wave; self.multiplier = multiplier; self.compact = compact
    }
    public var body: some View {
        VStack(alignment: .trailing, spacing: Horizon.Space.s4) {
            HUDReadout(
                label: "WAVE",
                value: String(format: "%02d", wave),
                valueFont: compact ? Horizon.Type.readoutLg : Horizon.Type.readoutXL,
                alignment: .trailing
            )
            HUDReadout(
                label: "MULTIPLIER",
                value: String(format: "×%.1f", multiplier),
                valueFont: Horizon.Type.readoutSm,
                valueColor: multiplier >= 2.0 ? Horizon.Accent.ember : Horizon.Ink.bone,
                alignment: .trailing
            )
        }
    }
}

// MARK: - Reticle (center)

/// Two square brackets `[ ]` flanking a `+`. NO dotted ring, NO corner ticks, NO filled circle.
public struct Reticle: View {
    let size: CGFloat
    let locked: Bool
    public init(size: CGFloat = 56, locked: Bool = false) {
        self.size = size; self.locked = locked
    }
    public var body: some View {
        let stroke = locked ? Horizon.Accent.flare : Horizon.Ink.bone
        Canvas { ctx, sz in
            let w = sz.width, h = sz.height
            let bracketW = w * 0.18
            let lineWidth: CGFloat = Horizon.Stroke.thin

            // Left bracket
            var left = Path()
            left.move(to: CGPoint(x: bracketW, y: 0))
            left.addLine(to: CGPoint(x: 0, y: 0))
            left.addLine(to: CGPoint(x: 0, y: h))
            left.addLine(to: CGPoint(x: bracketW, y: h))
            ctx.stroke(left, with: .color(stroke),
                       style: StrokeStyle(lineWidth: lineWidth, lineCap: .square))

            // Right bracket
            var right = Path()
            right.move(to: CGPoint(x: w - bracketW, y: 0))
            right.addLine(to: CGPoint(x: w, y: 0))
            right.addLine(to: CGPoint(x: w, y: h))
            right.addLine(to: CGPoint(x: w - bracketW, y: h))
            ctx.stroke(right, with: .color(stroke),
                       style: StrokeStyle(lineWidth: lineWidth, lineCap: .square))

            // Crosshair +
            let cx = w / 2, cy = h / 2
            let armOuter: CGFloat = w * 0.10
            let armInner: CGFloat = w * 0.04

            var cross = Path()
            cross.move(to: CGPoint(x: cx - armOuter, y: cy))
            cross.addLine(to: CGPoint(x: cx - armInner, y: cy))
            cross.move(to: CGPoint(x: cx + armInner, y: cy))
            cross.addLine(to: CGPoint(x: cx + armOuter, y: cy))
            cross.move(to: CGPoint(x: cx, y: cy - armOuter))
            cross.addLine(to: CGPoint(x: cx, y: cy - armInner))
            cross.move(to: CGPoint(x: cx, y: cy + armInner))
            cross.addLine(to: CGPoint(x: cx, y: cy + armOuter))
            ctx.stroke(cross, with: .color(stroke), lineWidth: lineWidth * 0.95)
        }
        .frame(width: size, height: size * 0.56) // wider than tall, like the spec art
        .horizonIconShadow()
    }
}

// MARK: - Shield bar (bottom-left)

public struct ShieldBar: View {
    /// 0...1
    let value: Double
    let width: CGFloat
    public init(value: Double, width: CGFloat = 200) {
        self.value = max(0, min(1, value)); self.width = width
    }

    private var fillColor: Color {
        if value < 0.30 { return Horizon.Accent.warn }
        return Horizon.Ink.bone
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Horizon.Space.s2) {
            HUDLabel("SHIELD")
            // Outline + 2px inner padding + fill
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: Horizon.Radius.r1)
                    .stroke(Horizon.Ink.bone.opacity(0.85), lineWidth: Horizon.Stroke.thin)
                    .frame(width: width, height: 12)
                Rectangle()
                    .fill(fillColor)
                    .frame(width: max(0, (width - 4) * value), height: 8)
                    .padding(.leading, 2)
                    .animation(Horizon.Motion.easeOut, value: value)
            }
        }
    }
}

// MARK: - Weapons rack (bottom-right)

public enum WeaponState { case active, available, disabled }

public struct WeaponsRack: View {
    let weapons: [WeaponState]
    public init(weapons: [WeaponState]) { self.weapons = weapons }

    public var body: some View {
        VStack(alignment: .trailing, spacing: Horizon.Space.s2) {
            HUDLabel("WEAPONS")
            HStack(spacing: 14) {
                ForEach(0..<weapons.count, id: \.self) { i in
                    WeaponGlyph(state: weapons[i])
                }
            }
        }
    }
}

public struct WeaponGlyph: View {
    let state: WeaponState
    public var body: some View {
        let color: Color = {
            switch state {
            case .active:    return Horizon.Accent.ember
            case .available: return Horizon.Ink.bone
            case .disabled:  return Horizon.Ink.ghost
            }
        }()
        // Missile silhouette: 24×24, 1.5 stroke
        Canvas { ctx, sz in
            let w = sz.width, h = sz.height
            var p = Path()
            p.move(to: CGPoint(x: w*0.5,  y: h*0.08))
            p.addLine(to: CGPoint(x: w*0.58, y: h*0.25))
            p.addLine(to: CGPoint(x: w*0.58, y: h*0.75))
            p.addLine(to: CGPoint(x: w*0.66, y: h*0.88))
            p.addLine(to: CGPoint(x: w*0.34, y: h*0.88))
            p.addLine(to: CGPoint(x: w*0.42, y: h*0.75))
            p.addLine(to: CGPoint(x: w*0.42, y: h*0.25))
            p.closeSubpath()
            ctx.stroke(p, with: .color(color),
                       style: StrokeStyle(lineWidth: Horizon.Stroke.thin,
                                          lineCap: .round, lineJoin: .round))
            if state == .active {
                ctx.fill(p, with: .color(color.opacity(0.25)))
            }
        }
        .frame(width: 24, height: 24)
        .horizonIconShadow()
    }
}

// MARK: - Glass panel

public struct HorizonPanel<Content: View>: View {
    let content: () -> Content
    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    public var body: some View {
        content()
            .padding(Horizon.Space.s6)
            .background(
                RoundedRectangle(cornerRadius: Horizon.Radius.r2)
                    .fill(Horizon.Surface.panel)
                    .background(.ultraThinMaterial,
                                in: RoundedRectangle(cornerRadius: Horizon.Radius.r2))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Horizon.Radius.r2)
                    .stroke(Horizon.Surface.hairline, lineWidth: Horizon.Stroke.hairline)
            )
            .foregroundColor(Horizon.Ink.bone)
    }
}

// MARK: - Buttons

public struct HorizonPrimaryButton: View {
    let title: String
    let action: () -> Void
    public init(_ title: String, action: @escaping () -> Void) {
        self.title = title; self.action = action
    }
    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(Horizon.Type.label.weight(.medium))
                .horizonLabelTracking()
                .foregroundColor(Horizon.Silhouette.void)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: Horizon.Radius.r1)
                        .fill(Horizon.Ink.bone)
                )
        }
        .buttonStyle(.plain)
    }
}

public struct HorizonGhostButton: View {
    let title: String
    let action: () -> Void
    public init(_ title: String, action: @escaping () -> Void) {
        self.title = title; self.action = action
    }
    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(Horizon.Type.label.weight(.medium))
                .horizonLabelTracking()
                .foregroundColor(Horizon.Ink.bone)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .overlay(
                    RoundedRectangle(cornerRadius: Horizon.Radius.r1)
                        .stroke(Horizon.Ink.bone.opacity(0.4),
                                lineWidth: Horizon.Stroke.hairline)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Close button (used in pause / overlays)

public struct HorizonCloseButton: View {
    let action: () -> Void
    public init(action: @escaping () -> Void) { self.action = action }
    public var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .stroke(Horizon.Ink.bone.opacity(0.5), lineWidth: Horizon.Stroke.thin)
                    .background(Circle().fill(Horizon.Surface.panel))
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Horizon.Ink.bone)
            }
            .frame(width: 36, height: 36)
        }
        .buttonStyle(.plain)
        .horizonIconShadow()
    }
}
