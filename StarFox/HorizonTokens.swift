//
//  HorizonTokens.swift
//  Horizon — Design System
//
//  Single source of truth for color tokens in SwiftUI.
//  Mirrors `design-system/tokens.css`. Do NOT introduce raw hex values
//  in the rest of the codebase — always reference one of these.
//
//  Colors live in Assets.xcassets/Colors/<group>/<name>.colorset.
//  Asset catalog folders use `provides-namespace` so the literal name is
//  e.g. "Sky/SkyEmber". We hide that detail behind these accessors.
//

import SwiftUI

// MARK: - Namespace

public enum Horizon {}

// MARK: - Colors

public extension Horizon {

    enum Sky {
        public static let deep   = Color("Sky/SkyDeep",   bundle: .main)
        public static let plum   = Color("Sky/SkyPlum",   bundle: .main)
        public static let ember  = Color("Sky/SkyEmber",  bundle: .main)
        public static let flare  = Color("Sky/SkyFlare",  bundle: .main)
        public static let haze   = Color("Sky/SkyHaze",   bundle: .main)
    }

    enum Silhouette {
        public static let far    = Color("Silhouette/SilhouetteFar",   bundle: .main)
        public static let mid    = Color("Silhouette/SilhouetteMid",   bundle: .main)
        public static let near   = Color("Silhouette/SilhouetteNear",  bundle: .main)
        public static let ridge  = Color("Silhouette/SilhouetteRidge", bundle: .main)
        public static let void   = Color("Silhouette/SilhouetteVoid",  bundle: .main)
    }

    enum Ink {
        /// Primary text. Off-white (#fff5e8). NEVER use Color.white.
        public static let bone   = Color("Ink/InkBone",  bundle: .main)
        /// Eyebrow / italic taglines.
        public static let haze   = Color("Ink/InkHaze",  bundle: .main)
        /// Secondary text & labels (bone @ 65%).
        public static let dim    = Color("Ink/InkDim",   bundle: .main)
        /// Disabled / hint (bone @ 35%).
        public static let ghost  = Color("Ink/InkGhost", bundle: .main)
    }

    enum Accent {
        /// Multiplier ≥ 2.0, achievements, NEW RECORD.
        public static let ember      = Color("Accent/AccentEmber",      bundle: .main)
        /// Active lock-on, engine glow.
        public static let flare      = Color("Accent/AccentFlare",      bundle: .main)
        /// Sun core / hotspot.
        public static let core       = Color("Accent/AccentCore",       bundle: .main)
        /// Momentary shield-charge state.
        public static let shieldCyan = Color("Accent/AccentShieldCyan", bundle: .main)
        /// Low shield, error.
        public static let warn       = Color("Accent/AccentWarn",       bundle: .main)
    }

    enum Surface {
        public static let panel    = Color("Surface/SurfacePanel",    bundle: .main)
        public static let panelHi  = Color("Surface/SurfacePanelHi",  bundle: .main)
        public static let hairline = Color("Surface/SurfaceHairline", bundle: .main)
        public static let divider  = Color("Surface/SurfaceDivider",  bundle: .main)
    }
}

// MARK: - Spacing (4pt scale)

public extension Horizon {
    enum Space {
        public static let s1: CGFloat  = 4
        public static let s2: CGFloat  = 8
        public static let s3: CGFloat  = 12
        public static let s4: CGFloat  = 16
        public static let s6: CGFloat  = 24   // canonical screen padding
        public static let s8: CGFloat  = 32
        public static let s12: CGFloat = 48
        public static let s16: CGFloat = 64
    }
}

// MARK: - Radius

public extension Horizon {
    enum Radius {
        /// HUD readouts (sharp).
        public static let r0: CGFloat = 0
        /// Shield bar, telemetry strip.
        public static let r1: CGFloat = 2
        /// Buttons, mission cards, panels.
        public static let r2: CGFloat = 4
        public static let r3: CGFloat = 8
        /// Pills, badges, multiplier chip.
        public static let full: CGFloat = 9999
    }
}

// MARK: - Stroke

public extension Horizon {
    enum Stroke {
        public static let hairline: CGFloat = 1
        public static let thin: CGFloat     = 1.5
        public static let medium: CGFloat   = 2
        public static let bold: CGFloat     = 3
    }
}

// MARK: - Motion

public extension Horizon {
    enum Motion {
        public static let easeOut = Animation.timingCurve(0.2, 0.7, 0.2, 1, duration: 0.22)
        public static let fast    = Animation.timingCurve(0.2, 0.7, 0.2, 1, duration: 0.16)
        public static let slow    = Animation.timingCurve(0.2, 0.7, 0.2, 1, duration: 0.48)
    }
}

// MARK: - Gradients

public extension Horizon {
    enum Gradients {
        /// Top vignette over sky for legibility.
        public static let scrimTop = LinearGradient(
            stops: [
                .init(color: .black.opacity(0.45), location: 0.0),
                .init(color: .clear,                location: 0.35)
            ],
            startPoint: .top, endPoint: .bottom
        )

        /// Bottom vignette.
        public static let scrimBottom = LinearGradient(
            stops: [
                .init(color: .clear,                location: 0.6),
                .init(color: .black.opacity(0.55), location: 1.0)
            ],
            startPoint: .top, endPoint: .bottom
        )

        /// Uniform pause/menu scrim — apply with `.background(...)` AFTER a `.blur()` layer.
        public static let scrimUniform = Color.black.opacity(0.55)
    }
}

// MARK: - Shadow helpers

public extension View {
    /// Drop-shadow required on ANY HUD text sitting over the sky.
    /// Mirrors `--shadow-text-hud` (0 1px 8px rgba(0,0,0,0.5)).
    func horizonHUDTextShadow() -> some View {
        self.shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 1)
    }

    /// Icon shadow (slightly heavier).
    func horizonIconShadow() -> some View {
        self.shadow(color: .black.opacity(0.55), radius: 3, x: 0, y: 1)
    }
}

// MARK: - Typography
//
// Two type voices, no third:
//  - Inter Tight   → narrative, menus, screen titles
//  - JetBrains Mono → HUD numerics, labels, telemetry
//
// Add the .ttf files to the target and register them in Info.plist under
// `UIAppFonts`. Without registration these fall back to the system font.

public extension Horizon {

    enum Typography {
        public static let displayName = "InterTight"
        public static let monoName    = "JetBrainsMono"

        // Display (Inter Tight)
        public static let display    = Font.custom("\(displayName)-ExtraLight", size: 88)
        public static let displaySm  = Font.custom("\(displayName)-ExtraLight", size: 56)
        public static let title      = Font.custom("\(displayName)-Light",      size: 42)
        public static let heading    = Font.custom("\(displayName)-Regular",    size: 22)
        public static let body       = Font.custom("\(displayName)-Regular",    size: 15)
        public static let caption    = Font.custom("\(displayName)-Regular",    size: 12)
        public static let taglineIt  = Font.custom("\(displayName)-LightItalic", size: 22)

        // HUD (JetBrains Mono)
        public static let readoutXL  = Font.custom("\(monoName)-Light",   size: 64)
        public static let readoutLg  = Font.custom("\(monoName)-Light",   size: 38)
        public static let readout    = Font.custom("\(monoName)-Regular", size: 32)
        public static let readoutSm  = Font.custom("\(monoName)-Light",   size: 28)
        public static let label      = Font.custom("\(monoName)-Medium",  size: 11)
        public static let eyebrow    = Font.custom("\(monoName)-Medium",  size: 10)
        public static let telemetry  = Font.custom("\(monoName)-Regular", size: 13)
    }
}

// MARK: - Tracking (kerning) helpers

public extension Text {
    /// Label tracking: uppercase-mono, +0.22em.
    func horizonLabelTracking(fontSize: CGFloat = 11) -> some View {
        self.kerning(fontSize * 0.22).textCase(.uppercase)
    }
    /// Eyebrow tracking: +0.32em uppercase.
    func horizonEyebrowTracking(fontSize: CGFloat = 10) -> some View {
        self.kerning(fontSize * 0.32).textCase(.uppercase)
    }
    /// Display/title negative tracking.
    func horizonTitleTracking(fontSize: CGFloat) -> Text {
        self.kerning(-fontSize * 0.02)
    }
    func horizonDisplayTracking(fontSize: CGFloat) -> Text {
        self.kerning(-fontSize * 0.04)
    }
    /// Telemetry strip: +0.18em.
    func horizonTelemetryTracking(fontSize: CGFloat = 13) -> some View {
        self.kerning(fontSize * 0.18).textCase(.uppercase)
    }
}
