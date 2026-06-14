//
//  JetSprite.swift
//  Horizon — Hero jet sprite for the Gameplay screen.
//
//  Renders the jet silhouette + (optional) twin engine flames over
//  the canonical sky background. The PNG asset MUST be transparent —
//  generated externally, dropped into Assets.xcassets/JetSprite.imageset.
//
//  See `ios-assets/JetSprite.README.md` for the exact ChatGPT/DALL·E
//  prompt and post-processing checklist.
//

import SwiftUI

public struct JetSprite: View {
    /// Render the engine flames behind the jet. False = silhouette only.
    let flames: Bool
    /// Width in points. The jet sits roughly 38% of screen width on iPhone landscape.
    let width: CGFloat
    /// Slight horizontal banking, -1...1 (left/right). Multiplies a 6° rotation.
    let bank: Double

    public init(flames: Bool = true, width: CGFloat = 320, bank: Double = 0) {
        self.flames = flames
        self.width = width
        self.bank = max(-1, min(1, bank))
    }

    public var body: some View {
        ZStack {
            if flames {
                JetFlames()
                    .frame(width: width * 0.42, height: width * 0.38)
                    .offset(y: width * 0.12)
                    .blendMode(.plusLighter)
                    .blur(radius: 1.2)
            }
            Image("JetSprite")
                .resizable()
                .scaledToFit()
                .frame(width: width)
        }
        .rotationEffect(.degrees(bank * 6))
        .shadow(color: .black.opacity(0.35), radius: 14, x: 0, y: 6)
    }
}

// MARK: - Twin engine flames (procedural, on-brand)

private struct JetFlames: View {
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            let nozzleGap = w * 0.18
            HStack(spacing: nozzleGap) {
                Flame()
                Flame()
            }
            .frame(width: w, height: h)
        }
    }
}

private struct Flame: View {
    var body: some View {
        ZStack {
            // outer glow
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Horizon.Accent.flare.opacity(0.0),
                            Horizon.Accent.flare.opacity(0.65),
                            Horizon.Accent.ember.opacity(0.85),
                            Horizon.Accent.core
                        ],
                        startPoint: .bottom, endPoint: .top
                    )
                )
                .frame(width: 38)
            // hot core
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Horizon.Accent.ember.opacity(0.0),
                            Horizon.Accent.core
                        ],
                        startPoint: .bottom, endPoint: .top
                    )
                )
                .frame(width: 14)
                .blur(radius: 0.5)
        }
        .compositingGroup()
    }
}
