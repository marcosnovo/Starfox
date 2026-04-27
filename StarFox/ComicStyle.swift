//
//  ComicStyle.swift
//  StarFox
//

import SceneKit
import UIKit

enum AltoVisualStyle {
    static let maxColorsPerScene = 5
    static let defaultSkyCycleDuration: TimeInterval = 240
    static let defaultWeatherTransitionDuration: TimeInterval = 8

    enum ScenePhase {
        case dawn
        case day
        case dusk
        case night
    }

    struct Palette {
        let skyTop: UIColor
        let skyBottom: UIColor
        let foreground: UIColor
        let accent: UIColor
        let mist: UIColor
        let highlight: UIColor

        var limitedSceneColors: [UIColor] {
            [skyTop, skyBottom, foreground, accent, mist]
        }
    }

    static func palette(for phase: ScenePhase) -> Palette {
        switch phase {
        case .dawn:
            return Palette(
                skyTop: UIColor(red: 0.45, green: 0.34, blue: 0.34, alpha: 1),
                skyBottom: UIColor(red: 0.86, green: 0.64, blue: 0.48, alpha: 1),
                foreground: UIColor(red: 0.11, green: 0.12, blue: 0.14, alpha: 1),
                accent: UIColor.cSafetyOrange,
                mist: UIColor.cMintMetal,
                highlight: UIColor.cMintHighlight
            )
        case .day:
            return Palette(
                skyTop: UIColor(red: 0.52, green: 0.44, blue: 0.42, alpha: 1),
                skyBottom: UIColor(red: 0.90, green: 0.72, blue: 0.56, alpha: 1),
                foreground: UIColor(red: 0.13, green: 0.15, blue: 0.17, alpha: 1),
                accent: UIColor.cSafetyOrange,
                mist: UIColor.cMintMetal,
                highlight: UIColor.cMintHighlight
            )
        case .dusk:
            return Palette(
                skyTop: UIColor(red: 0.34, green: 0.28, blue: 0.36, alpha: 1),
                skyBottom: UIColor(red: 0.82, green: 0.56, blue: 0.42, alpha: 1),
                foreground: UIColor(red: 0.10, green: 0.11, blue: 0.13, alpha: 1),
                accent: UIColor.cSafetyOrange,
                mist: UIColor.cMintMetal,
                highlight: UIColor.cMintHighlight
            )
        case .night:
            return Palette(
                skyTop: UIColor(red: 0.14, green: 0.12, blue: 0.18, alpha: 1),
                skyBottom: UIColor(red: 0.24, green: 0.22, blue: 0.28, alpha: 1),
                foreground: UIColor(red: 0.08, green: 0.09, blue: 0.11, alpha: 1),
                accent: UIColor.cSafetyOrange,
                mist: UIColor.cMetalShadow,
                highlight: UIColor.cMintMetal
            )
        }
    }

    static func calmEase(_ t: CGFloat) -> CGFloat {
        let x = Swift.min(CGFloat(1), Swift.max(CGFloat(0), t))
        return x * x * (CGFloat(3) - CGFloat(2) * x)
    }
}

private enum ComicStyleCache {
    static let inkMaterial: SCNMaterial = {
        let material = SCNMaterial()
        material.lightingModel = .constant
        material.diffuse.contents = UIColor.cInk
        material.emission.contents = UIColor.cInk
        material.cullMode = .front
        material.isDoubleSided = true
        material.readsFromDepthBuffer = true
        material.writesToDepthBuffer = true
        return material
    }()
}

extension UIColor {
    static let cDeepCharcoal = UIColor(red: 0.08, green: 0.09, blue: 0.11, alpha: 1)
    static let cSafetyOrange = UIColor(red: 0.80, green: 0.44, blue: 0.24, alpha: 1)
    static let cMintMetal = UIColor(red: 0.68, green: 0.74, blue: 0.72, alpha: 1)
    static let cMintHighlight = UIColor(red: 0.88, green: 0.84, blue: 0.76, alpha: 1)
    static let cMetalShadow = UIColor(red: 0.43, green: 0.49, blue: 0.48, alpha: 1)
    static let cInk = UIColor(red: 0.01, green: 0.01, blue: 0.01, alpha: 1)

    // Backward-compatible aliases used across the project.
    static let aCharcoal = UIColor.cDeepCharcoal
    static let aOrange = UIColor.cSafetyOrange
    static let aOrangeHot = UIColor.cSafetyOrange
    static let aMint = UIColor.cMintMetal
    static let aMintBright = UIColor.cMintHighlight
    static let aOffWhite = UIColor.cMintHighlight
    static let aDarkSuit = UIColor.cDeepCharcoal

    func blended(with color: UIColor, t: CGFloat) -> UIColor {
        let clamped = max(0, min(1, t))
        var r1: CGFloat = 0
        var g1: CGFloat = 0
        var b1: CGFloat = 0
        var a1: CGFloat = 0
        var r2: CGFloat = 0
        var g2: CGFloat = 0
        var b2: CGFloat = 0
        var a2: CGFloat = 0
        getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        color.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        return UIColor(
            red: r1 + (r2 - r1) * clamped,
            green: g1 + (g2 - g1) * clamped,
            blue: b1 + (b2 - b1) * clamped,
            alpha: a1 + (a2 - a1) * clamped
        )
    }

    func dimmed(_ amount: CGFloat) -> UIColor {
        blended(with: .black, t: amount)
    }
}

func comicMaterial(_ color: UIColor, emission: UIColor? = nil) -> SCNMaterial {
    let material = SCNMaterial()
    material.lightingModel = .lambert
    material.diffuse.contents = color
    material.specular.contents = UIColor.black
    if let emission {
        material.emission.contents = emission
    }
    return material
}

enum ShipLookPreset {
    case cenital
    case frontal

    // Cambia esta linea para alternar rapido entre presets.
    static let current: ShipLookPreset = .cenital

    var shipScale: Float {
        switch self {
        case .cenital: return 1.95
        case .frontal: return 1.72
        }
    }

    var shipEulerAngles: SCNVector3 {
        switch self {
        case .cenital:
            return SCNVector3(0.08, Float.pi * 0.93, -0.16)
        case .frontal:
            return SCNVector3(0.03, Float.pi * 0.95, -0.08)
        }
    }

    var shipInkScale: Float {
        switch self {
        case .cenital: return 1.05
        case .frontal: return 1.07
        }
    }

    var cameraPosition: SCNVector3 {
        switch self {
        case .cenital: return SCNVector3(1.1, 4.15, -7.8)
        case .frontal: return SCNVector3(0.55, 3.45, -9.4)
        }
    }

    var cameraLookAt: SCNVector3 {
        switch self {
        case .cenital: return SCNVector3(-0.9, 0.95, 3.0)
        case .frontal: return SCNVector3(-0.35, 0.85, 4.4)
        }
    }

    var cameraFieldOfView: CGFloat {
        switch self {
        case .cenital: return 56
        case .frontal: return 60
        }
    }
}

extension SCNNode {
    func addInkOutline(scale: Float = 1.08) {
        guard name != "__ink",
              parent?.name != "__ink",
              childNode(withName: "__ink", recursively: false) == nil,
              let sourceGeometry = geometry,
              let clonedGeometry = sourceGeometry.copy() as? SCNGeometry
        else { return }

        clonedGeometry.materials = Array(
            repeating: ComicStyleCache.inkMaterial,
            count: max(1, clonedGeometry.materials.count)
        )

        let outlineNode = SCNNode(geometry: clonedGeometry)
        outlineNode.name = "__ink"
        outlineNode.scale = SCNVector3(scale, scale, scale)
        outlineNode.renderingOrder = -5
        addChildNode(outlineNode)
    }
}
