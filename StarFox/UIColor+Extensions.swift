//
//  UIColor+Extensions.swift
//  StarFox
//

import SceneKit
import UIKit

extension UIColor {
    convenience init(hex: String) {
        var value = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if value.hasPrefix("#") { value.removeFirst() }
        if value.count != 6 {
            self.init(white: 0, alpha: 1)
            return
        }

        var rgb: UInt64 = 0
        Scanner(string: value).scanHexInt64(&rgb)
        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: 1)
    }

    static func lerp(from: UIColor, to: UIColor, t: CGFloat) -> UIColor {
        let clamped = max(0, min(1, t))
        var fr: CGFloat = 0, fg: CGFloat = 0, fb: CGFloat = 0, fa: CGFloat = 0
        var tr: CGFloat = 0, tg: CGFloat = 0, tb: CGFloat = 0, ta: CGFloat = 0
        from.getRed(&fr, green: &fg, blue: &fb, alpha: &fa)
        to.getRed(&tr, green: &tg, blue: &tb, alpha: &ta)
        return UIColor(
            red: fr + (tr - fr) * clamped,
            green: fg + (tg - fg) * clamped,
            blue: fb + (tb - fb) * clamped,
            alpha: fa + (ta - fa) * clamped
        )
    }

    var scnVector3RGB: SCNVector3 {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return SCNVector3(Float(r), Float(g), Float(b))
    }

    func multiplied(by color: UIColor) -> UIColor {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        color.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        return UIColor(red: r1 * r2, green: g1 * g2, blue: b1 * b2, alpha: a1 * a2)
    }

    func weightedAdd(color: UIColor, weight: CGFloat) -> UIColor {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        color.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        return UIColor(
            red: min(1, r1 + r2 * weight),
            green: min(1, g1 + g2 * weight),
            blue: min(1, b1 + b2 * weight),
            alpha: min(1, a1 + a2 * weight)
        )
    }
}

extension CGFloat {
    static func lerp(from: CGFloat, to: CGFloat, t: CGFloat) -> CGFloat {
        from + (to - from) * t
    }

    var smoothStep01: CGFloat {
        let x = Swift.min(CGFloat(1), Swift.max(CGFloat(0), self))
        return x * x * (CGFloat(3) - CGFloat(2) * x)
    }
}
