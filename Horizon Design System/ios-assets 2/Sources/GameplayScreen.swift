//
//  GameplayScreen.swift
//  Horizon — Reference layout for the in-game HUD.
//
//  This is the canonical layout for iPhone landscape. Match this
//  EXACTLY in the production game scene. Padding 22pt from the
//  visible viewport (NOT the device chrome).
//

import SwiftUI

public struct GameplayScreen: View {
    @State private var score = 10
    @State private var rings = 0
    @State private var wave  = 1
    @State private var multiplier = 1.0
    @State private var shield = 0.55
    @State private var weapons: [WeaponsRack.SlotState] = [.default, .default, .default]
    @State private var locked = false

    let onClose: () -> Void
    let onFire: () -> Void

    public init(onClose: @escaping () -> Void = {}, onFire: @escaping () -> Void = {}) {
        self.onClose = onClose
        self.onFire  = onFire
    }

    public var body: some View {
        ZStack {
            HorizonBackground()                  // canonical sky
            Horizon.Gradients.scrimTop            // top vignette
                .allowsHitTesting(false)
            Horizon.Gradients.scrimBottom         // bottom vignette
                .allowsHitTesting(false)

            // 4-corner HUD, 22pt from visible viewport edges.
            VStack {
                HStack(alignment: .top) {
                    ScorePanel(score: score, rings: rings)
                    Spacer(minLength: 0)
                    WavePanel(wave: wave, multiplier: multiplier)
                }
                Spacer(minLength: 0)
                HStack(alignment: .bottom) {
                    ShieldBar(value: shield)
                    Spacer(minLength: 0)
                    WeaponsRack(slots: weapons)
                }
            }
            .padding(.horizontal, 22)
            .padding(.vertical,   22)

            // Center reticle — slightly above optical center to sit on the sun.
            GeometryReader { g in
                Reticle(size: 56, locked: locked)
                    .position(x: g.size.width * 0.5, y: g.size.height * 0.47)
            }
            .allowsHitTesting(false)

            // Close button — top-left, OUTSIDE the score panel column.
            // NOTE: in prior iterations this overlapped SCORE. It must sit in
            // its own column above-left of the HUD readouts (or be removed
            // during gameplay and only shown in the pause overlay).
            VStack {
                HStack {
                    closeButton
                    Spacer()
                }
                Spacer()
            }
            .padding(.horizontal, 22)
            .padding(.vertical,   22)

            // Fire button — bottom-right, sized 56pt and OFFSET from WeaponsRack
            // so it never overlaps the weapon glyphs.
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    fireButton
                }
            }
            .padding(.trailing, 22)
            .padding(.bottom,   22)
        }
        .background(Horizon.Silhouette.void)
        .ignoresSafeArea()
    }

    // MARK: subviews

    private var closeButton: some View {
        Button(action: onClose) {
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Horizon.Ink.bone)
                .frame(width: 32, height: 32)
                .background(
                    Circle().fill(Horizon.Surface.panel)
                )
                .overlay(
                    Circle().strokeBorder(Horizon.Surface.hairline,
                                          lineWidth: Horizon.Stroke.hairline)
                )
        }
        .buttonStyle(.plain)
        .horizonIconShadow()
    }

    private var fireButton: some View {
        Button(action: onFire) {
            Image(systemName: "scope")
                .font(.system(size: 22, weight: .regular))
                .foregroundColor(Horizon.Ink.bone)
                .frame(width: 56, height: 56)
                .background(
                    Circle().fill(Horizon.Surface.panel)
                )
                .overlay(
                    Circle().strokeBorder(Horizon.Ink.bone.opacity(0.4),
                                          lineWidth: Horizon.Stroke.thin)
                )
        }
        .buttonStyle(.plain)
        .horizonIconShadow()
        .padding(.bottom, 0)
        // IMPORTANT: keep this button BELOW the WeaponsRack column. The
        // rack is 22pt from the edge and ~18pt tall — the fire button
        // sits in its own 56pt circle to the right of/below the rack.
    }
}
