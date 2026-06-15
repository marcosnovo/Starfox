//
//  GroundGridSystem.swift
//  StarFox
//
//  Alto's Adventure-style ground plane.
//
//  Replaces the neon synthwave grid with a single soft gradient surface
//  that runs from a warm near-ground tone (the patch under the ship) to
//  a deep horizon tone where scene fog finishes the fade. The gradient
//  is regenerated whenever the active sky palette shifts so dawn / day /
//  dusk / night each get a coherent ground tone.
//
//  The type name is kept for source-compatibility with the rest of the
//  scene; it is no longer a grid.
//

import SceneKit
import UIKit

final class GroundGridSystem {
    private let rootNode: SCNNode
    private var groundNode: SCNNode?
    private var material: SCNMaterial?

    /// World height of the floor — matches the base of the pillars so they
    /// stand on the ground.
    static let groundY: Float = -7.0

    private let planeWidth: CGFloat = 240
    private let planeLength: CGFloat = 640

    // Regenerating the gradient image every frame is wasteful — the sky
    // only shifts a couple of times a second anyway.
    private var tintAccumulator: TimeInterval = 0
    private let tintInterval: TimeInterval = 0.6

    init(rootNode: SCNNode) {
        self.rootNode = rootNode
    }

    func setup() {
        groundNode?.removeFromParentNode()

        let plane = SCNPlane(width: planeWidth, height: planeLength)
        let mat = SCNMaterial()
        mat.lightingModel = .constant
        // Start at dusk colours so the opening frame already reads
        // Alto's even before the first tint pass arrives.
        mat.diffuse.contents = Self.gradientImage(
            near:    UIColor(hex: "#D17F69"),
            nearMid: UIColor(hex: "#9C5A5D"),
            farMid:  UIColor(hex: "#5D3C50"),
            far:     UIColor(hex: "#2A1F2C")
        )
        mat.diffuse.wrapS = .clamp
        mat.diffuse.wrapT = .clamp
        mat.diffuse.magnificationFilter = .linear
        mat.diffuse.minificationFilter  = .linear
        mat.isDoubleSided = true
        mat.writesToDepthBuffer = false
        mat.readsFromDepthBuffer = false
        plane.materials = [mat]
        material = mat

        let node = SCNNode(geometry: plane)
        node.name = "ground"
        node.eulerAngles.x = -.pi / 2
        node.position = SCNVector3(0, Self.groundY, 0)
        node.renderingOrder = -120
        node.castsShadow = false
        rootNode.addChildNode(node)
        groundNode = node
    }

    func update(shipPosition: SCNVector3) {
        // The plane follows the ship in Z so we never run off it.
        groundNode?.position = SCNVector3(shipPosition.x * 0.4, Self.groundY, shipPosition.z)
    }

    /// Re-tint the gradient texture using the current sky palette so
    /// the ground reads coherently with dawn / day / dusk / night.
    /// Throttled.
    func tintToPalette(horizon: UIColor, top: UIColor, dt: TimeInterval) {
        tintAccumulator += dt
        if tintAccumulator < tintInterval { return }
        tintAccumulator = 0

        let void = UIColor(hex: "#0E0C18")
        let near    = horizon
        let nearMid = UIColor.lerp(from: horizon, to: void, t: 0.35)
        let farMid  = UIColor.lerp(from: top,     to: void, t: 0.50)
        let far     = UIColor.lerp(from: top,     to: void, t: 0.80)

        material?.diffuse.contents = Self.gradientImage(
            near: near, nearMid: nearMid, farMid: farMid, far: far
        )
    }

    func reset(shipPosition: SCNVector3) {
        tintAccumulator = tintInterval   // force a refresh next tint pass.
        update(shipPosition: shipPosition)
    }

    // MARK: - Procedural ground texture

    private static func gradientImage(near: UIColor, nearMid: UIColor, farMid: UIColor, far: UIColor) -> UIImage {
        let size = CGSize(width: 64, height: 512)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let cg = ctx.cgContext
            cg.clear(CGRect(origin: .zero, size: size))

            let space = CGColorSpaceCreateDeviceRGB()
            let colors = [
                near.cgColor,
                nearMid.cgColor,
                farMid.cgColor,
                far.cgColor
            ] as CFArray
            let locs: [CGFloat] = [0.0, 0.35, 0.70, 1.0]
            if let g = CGGradient(colorsSpace: space, colors: colors, locations: locs) {
                cg.drawLinearGradient(g,
                                      start: CGPoint(x: 0, y: 0),
                                      end:   CGPoint(x: 0, y: size.height),
                                      options: [])
            }

            // Very subtle horizontal ripple — barely-visible value
            // breaks every few rows that give the eye something to
            // read as snow drift / sand crest, without becoming a grid.
            let ripple = UIColor.black.withAlphaComponent(0.06).cgColor
            cg.setFillColor(ripple)
            var y: CGFloat = 24
            while y < size.height - 8 {
                cg.fill(CGRect(x: 0, y: y, width: size.width, height: 1))
                y += CGFloat.random(in: 14...28)
            }
        }
    }
}
