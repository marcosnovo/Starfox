//
//  HorizonTypography.swift
//  Horizon — Design System
//
//  Two type voices, no third:
//   - Inter Tight  → narrative, menus, screen titles
//   - JetBrains Mono → HUD numerics, labels, telemetry
//
//  Add the .ttf files to the target and register them in Info.plist
//  under `UIAppFonts`. See ClaudeCode.md for the exact list of files.
//

import SwiftUI

public extension Horizon {

    enum Type {
        // ----- Family names as they appear inside the font files -----
        public static let displayName = "InterTight"      // PostScript family
        public static let monoName    = "JetBrainsMono"

        // MARK: Display (Inter Tight)
        /// 88 / 200 / -4% — cover hero
        public static let display    = Font.custom("\(displayName)-ExtraLight", size: 88)
        /// 56 / 200 / -3% — pause hero
        public static let displaySm  = Font.custom("\(displayName)-ExtraLight", size: 56)
        /// 42 / 300 / -2% — screen titles
        public static let title      = Font.custom("\(displayName)-Light",      size: 42)
        /// 22 / 400 — section headings
        public static let heading    = Font.custom("\(displayName)-Regular",    size: 22)
        /// 15 / 400 — body
        public static let body       = Font.custom("\(displayName)-Regular",    size: 15)
        /// 12 / 400 — captions
        public static let caption    = Font.custom("\(displayName)-Regular",    size: 12)
        /// 22 italic — taglines
        public static let taglineIt  = Font.custom("\(displayName)-LightItalic", size: 22)

        // MARK: HUD (JetBrains Mono)
        /// 64 / 300 / -2% — score (use 38 in compact iPhone HUD).
        public static let readoutXL  = Font.custom("\(monoName)-Light",   size: 64)
        /// 38 / 300 — score on iPhone landscape (compact).
        public static let readoutLg  = Font.custom("\(monoName)-Light",   size: 38)
        /// 32 / 400 — multiplier, secondary numbers.
        public static let readout    = Font.custom("\(monoName)-Regular", size: 32)
        /// 28 / 300 — secondary on iPhone (rings).
        public static let readoutSm  = Font.custom("\(monoName)-Light",   size: 28)
        /// 11 / 500 — labels (uppercase, +0.22em).
        public static let label      = Font.custom("\(monoName)-Medium",  size: 11)
        /// 10 / 500 — eyebrow (uppercase, +0.32em).
        public static let eyebrow    = Font.custom("\(monoName)-Medium",  size: 10)
        /// 13 / 400 — telemetry strip (+0.18em).
        public static let telemetry  = Font.custom("\(monoName)-Regular", size: 13)
    }
}

// MARK: - Tracking (kerning) helpers

public extension Text {
    /// Apply Horizon's "label" tracking: uppercase-mono, +0.22em.
    /// SwiftUI uses absolute kerning in points; ~22% of font size.
    func horizonLabelTracking(fontSize: CGFloat = 11) -> Text {
        self.kerning(fontSize * 0.22).textCase(.uppercase)
    }
    /// Eyebrow tracking: +0.32em uppercase.
    func horizonEyebrowTracking(fontSize: CGFloat = 10) -> Text {
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
    func horizonTelemetryTracking(fontSize: CGFloat = 13) -> Text {
        self.kerning(fontSize * 0.18).textCase(.uppercase)
    }
}
