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
    private var glowNode: SCNNode?
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
        glowNode?.removeFromParentNode()

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
        mat.blendMode = .add
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

        // Soft warm wash just above the grid so the floor reads as a glowing
        // surface, not just lines floating in space.
        let glowPlane = SCNPlane(width: planeWidth, height: planeLength)
        let glowMat = SCNMaterial()
        glowMat.lightingModel = .constant
        glowMat.diffuse.contents = Self.glowImage()
        glowMat.blendMode = .add
        glowMat.isDoubleSided = true
        glowMat.writesToDepthBuffer = false
        glowMat.readsFromDepthBuffer = false
        glowPlane.materials = [glowMat]
        let glow = SCNNode(geometry: glowPlane)
        glow.eulerAngles.x = -.pi / 2
        glow.position = SCNVector3(0, Self.groundY + 0.05, 0)
        glow.renderingOrder = -121
        glow.castsShadow = false
        rootNode.addChildNode(glow)
        glowNode = glow

        applyTransform(shipZ: 0)
    }

    func update(shipPosition: SCNVector3) {
        gridNode?.position = SCNVector3(shipPosition.x * 0.4, Self.groundY, shipPosition.z)
        glowNode?.position = SCNVector3(shipPosition.x * 0.4, Self.groundY + 0.05, shipPosition.z)
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

    /// One grid cell: transparent fill with a bright line on two edges, so
    /// repeating it builds a continuous glowing lattice.
    private static func gridImage() -> UIImage {
        let size = CGSize(width: 128, height: 128)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let cg = ctx.cgContext
            cg.clear(CGRect(origin: .zero, size: size))

            let line = UIColor(red: 1.0, green: 0.86, blue: 0.66, alpha: 0.9)
            // Bright thin core lines on the left and bottom edges.
            cg.setFillColor(line.cgColor)
            cg.fill(CGRect(x: 0, y: 0, width: 3, height: size.height))
            cg.fill(CGRect(x: 0, y: 0, width: size.width, height: 3))
            // Faint glow halo alongside the core lines.
            let halo = UIColor(red: 1.0, green: 0.78, blue: 0.55, alpha: 0.28)
            cg.setFillColor(halo.cgColor)
            cg.fill(CGRect(x: 3, y: 0, width: 5, height: size.height))
            cg.fill(CGRect(x: 0, y: 3, width: size.width, height: 5))
        }
    }

    /// Vertical falloff: warm near the camera, transparent toward the
    /// horizon, giving the floor a glowing wash without a hard far edge.
    private static func glowImage() -> UIImage {
        let size = CGSize(width: 8, height: 256)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let cg = ctx.cgContext
            let space = CGColorSpaceCreateDeviceRGB()
            let colors = [
                UIColor(red: 1.0, green: 0.55, blue: 0.32, alpha: 0.0).cgColor,
                UIColor(red: 1.0, green: 0.58, blue: 0.34, alpha: 0.16).cgColor,
                UIColor(red: 1.0, green: 0.66, blue: 0.42, alpha: 0.30).cgColor
            ] as CFArray
            let locations: [CGFloat] = [0.0, 0.55, 1.0]
            guard let gradient = CGGradient(colorsSpace: space, colors: colors, locations: locations) else { return }
            cg.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: 0, y: size.height),
                options: []
            )
        }
    }
}
