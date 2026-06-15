//
//  GroundGridSystem.swift
//  StarFox
//
//  Alto's Adventure-style ground plane.
//
//  Replaces the neon synthwave grid with a single soft warm-to-deep
//  gradient surface that fades into the scene's atmospheric fog at
//  distance. No hard grid lines, no glowing lattice — pure atmospheric
//  read, so the mountain silhouettes and sun stay the focal points.
//
//  The type name is kept for source-compatibility with the rest of the
//  scene; it is no longer a grid.
//

import SceneKit
import UIKit

final class GroundGridSystem {
    private let rootNode: SCNNode
    private var groundNode: SCNNode?

    /// World height of the floor — matches the base of the pillars so they
    /// stand on the ground.
    static let groundY: Float = -7.0

    private let planeWidth: CGFloat = 240
    private let planeLength: CGFloat = 640

    init(rootNode: SCNNode) {
        self.rootNode = rootNode
    }

    func setup() {
        groundNode?.removeFromParentNode()

        let plane = SCNPlane(width: planeWidth, height: planeLength)
        let mat = SCNMaterial()
        mat.lightingModel = .constant
        mat.diffuse.contents = Self.groundGradientImage()
        // Anchor: the gradient runs along the plane's height axis (which
        // becomes world Z once the plane is rotated flat) — image-top is
        // the near foreground (warm), image-bottom is the far distance
        // (deep) where scene fog takes over.
        mat.diffuse.wrapS = .clamp
        mat.diffuse.wrapT = .clamp
        mat.diffuse.magnificationFilter = .linear
        mat.diffuse.minificationFilter  = .linear
        mat.isDoubleSided = true
        mat.writesToDepthBuffer = false
        mat.readsFromDepthBuffer = false
        plane.materials = [mat]

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
        // The plane follows the ship in Z so we never run off it. The
        // gradient texture is anchored to the plane's UV space (not
        // scrolled), so the warm patch always reads as the area we're
        // crossing right now.
        groundNode?.position = SCNVector3(shipPosition.x * 0.4, Self.groundY, shipPosition.z)
    }

    func reset(shipPosition: SCNVector3) {
        update(shipPosition: shipPosition)
    }

    // MARK: - Procedural ground texture

    /// Vertical gradient that runs from a warm near-ground tone at the
    /// top of the texture (the near foreground after the plane is laid
    /// flat) down to a deep silhouette tone at the bottom (the far
    /// distance, where scene fog completes the fade).
    private static func groundGradientImage() -> UIImage {
        let size = CGSize(width: 64, height: 512)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let cg = ctx.cgContext
            cg.clear(CGRect(origin: .zero, size: size))

            let space = CGColorSpaceCreateDeviceRGB()
            let near    = UIColor(hex: "#D17F69")          // warm rose, matches dusk horizon
            let nearMid = UIColor(hex: "#9C5A5D")
            let farMid  = UIColor(hex: "#5D3C50")
            let far     = UIColor(hex: "#2A1F2C")          // deep silhouette before fog completes the fade

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
            // breaks every few rows that give the eye something to read
            // as snow drift / sand crest, without becoming a grid.
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
