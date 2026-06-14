//
//  GroundGridSystem.swift
//  StarFox
//
//  Scrolling neon ground grid — the synthwave/Star Fox floor. A large
//  plane sits at the base of the corridor, follows the ship, and scrolls
//  its glowing grid texture toward the viewer to convey speed and depth.
//  The scene's warm fog fades the far rows into the sunset, so there's no
//  hard horizon line. Everything is procedural — the grid texture is
//  drawn once into a UIImage at startup.
//

import SceneKit
import UIKit

final class GroundGridSystem {
    private let rootNode: SCNNode
    private var gridNode: SCNNode?
    private var material: SCNMaterial?

    /// World height of the floor — matches the base of the pillars so they
    /// stand on the grid.
    static let groundY: Float = -7.0

    private let planeWidth: CGFloat = 220
    private let planeLength: CGFloat = 640
    private let cellSize: CGFloat = 8.0

    init(rootNode: SCNNode) {
        self.rootNode = rootNode
    }

    func setup() {
        gridNode?.removeFromParentNode()

        let plane = SCNPlane(width: planeWidth, height: planeLength)
        let mat = SCNMaterial()
        mat.lightingModel = .constant
        mat.diffuse.contents = Self.gridImage()
        mat.diffuse.wrapS = .repeat
        mat.diffuse.wrapT = .repeat
        mat.diffuse.magnificationFilter = .linear
        mat.diffuse.minificationFilter = .linear
        mat.diffuse.mipFilter = .linear
        mat.emission.contents = mat.diffuse.contents
        mat.emission.wrapS = .repeat
        mat.emission.wrapT = .repeat
        // Alpha (not additive): the cyan lines overlay the warm ground as
        // crisp neon instead of compounding into a blown-out smear.
        mat.blendMode = .alpha
        mat.transparency = 0.85
        mat.isDoubleSided = true
        mat.writesToDepthBuffer = false
        mat.readsFromDepthBuffer = false
        plane.materials = [mat]
        material = mat

        let node = SCNNode(geometry: plane)
        node.name = "groundGrid"
        node.eulerAngles.x = -.pi / 2
        node.position = SCNVector3(0, Self.groundY, 0)
        node.renderingOrder = -120
        node.castsShadow = false
        rootNode.addChildNode(node)
        gridNode = node

        applyTransform(shipZ: 0)
    }

    func update(shipPosition: SCNVector3) {
        gridNode?.position = SCNVector3(shipPosition.x * 0.4, Self.groundY, shipPosition.z)
        applyTransform(shipZ: shipPosition.z)
    }

    func reset(shipPosition: SCNVector3) {
        update(shipPosition: shipPosition)
    }

    // MARK: - Texture scroll

    private func applyTransform(shipZ: Float) {
        let repeatX = Float(planeWidth / cellSize)
        let repeatZ = Float(planeLength / cellSize)
        // The plane follows the ship in Z, so without a texture offset the
        // grid would look locked to the ship. Scroll V by ship Z to make the
        // rows flow toward the camera.
        let scrollV = shipZ / Float(cellSize)
        let scale = SCNMatrix4MakeScale(repeatX, repeatZ, 1)
        let translate = SCNMatrix4MakeTranslation(0, scrollV, 0)
        let transform = SCNMatrix4Mult(scale, translate)
        material?.diffuse.contentsTransform = transform
        material?.emission.contentsTransform = transform
    }

    // MARK: - Procedural textures

    /// One grid cell: transparent fill with a neon line on two edges, so
    /// repeating it builds a continuous lattice. Cyan reads as crisp neon
    /// against the warm sunset (the classic complementary synthwave combo).
    private static func gridImage() -> UIImage {
        let size = CGSize(width: 128, height: 128)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let cg = ctx.cgContext
            cg.clear(CGRect(origin: .zero, size: size))

            let line = UIColor(red: 0.55, green: 0.95, blue: 1.0, alpha: 0.95)
            cg.setFillColor(line.cgColor)
            cg.fill(CGRect(x: 0, y: 0, width: 2, height: size.height))
            cg.fill(CGRect(x: 0, y: 0, width: size.width, height: 2))
            // Faint glow halo alongside the core lines.
            let halo = UIColor(red: 0.40, green: 0.80, blue: 0.95, alpha: 0.22)
            cg.setFillColor(halo.cgColor)
            cg.fill(CGRect(x: 2, y: 0, width: 4, height: size.height))
            cg.fill(CGRect(x: 0, y: 2, width: size.width, height: 4))
        }
    }
}
