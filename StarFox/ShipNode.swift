//
//  ShipNode.swift
//  StarFox
//

import SceneKit
import UIKit
import QuartzCore

struct PhysicsCategory {
    static let none        = 0
    static let ship        = 1
    static let obstacle    = 2
    static let projectile  = 4
    static let powerUp     = 8
    static let enemyBullet = 16
}

class ShipNode: SCNNode {
    private var engineGlowLight: SCNLight?
    private var engineCoreMaterials: [SCNMaterial] = []
    private var engineJetSystems: [SCNParticleSystem] = []
    private var engineTrailSystems: [SCNParticleSystem] = []
    private static let engineCoreColor = UIColor(red: 1.0, green: 0.9647, blue: 0.8157, alpha: 1.0)   // #FFF6D0
    private static let engineGlowColor = UIColor(red: 1.0, green: 0.6039, blue: 0.2706, alpha: 1.0)   // #FF9A45
    private static let engineTrailColor = UIColor(red: 0.9412, green: 0.4157, blue: 0.3020, alpha: 1.0) // #F06A4D

    private static func silhouetteMaterial() -> SCNMaterial {
        let material = SCNMaterial()
        material.lightingModel = .constant
        material.diffuse.contents = UIColor.black
        material.emission.contents = UIColor.black
        material.specular.contents = UIColor.black
        material.isDoubleSided = true
        return material
    }

    private static func engineCoreMaterial() -> SCNMaterial {
        let material = SCNMaterial()
        material.lightingModel = .constant
        material.diffuse.contents = engineCoreColor
        material.emission.contents = engineGlowColor
        return material
    }

    private static func softTrailImage() -> UIImage {
        let size = CGSize(width: 48, height: 48)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let cg = context.cgContext
            let colors = [
                engineCoreColor.withAlphaComponent(0.62).cgColor,
                engineTrailColor.withAlphaComponent(0.22).cgColor,
                engineTrailColor.withAlphaComponent(0.0).cgColor
            ] as CFArray
            let locations: [CGFloat] = [0.0, 0.52, 1.0]
            let space = CGColorSpaceCreateDeviceRGB()
            guard let gradient = CGGradient(colorsSpace: space, colors: colors, locations: locations) else { return }
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            cg.drawRadialGradient(
                gradient,
                startCenter: center,
                startRadius: 1,
                endCenter: center,
                endRadius: size.width / 2,
                options: []
            )
        }
    }

    private static func jetCoreImage() -> UIImage {
        let size = CGSize(width: 56, height: 56)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let cg = context.cgContext
            let colors = [
                engineCoreColor.withAlphaComponent(0.98).cgColor,
                engineGlowColor.withAlphaComponent(0.80).cgColor,
                engineGlowColor.withAlphaComponent(0.0).cgColor
            ] as CFArray
            let locations: [CGFloat] = [0.0, 0.38, 1.0]
            let space = CGColorSpaceCreateDeviceRGB()
            guard let gradient = CGGradient(colorsSpace: space, colors: colors, locations: locations) else { return }
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            cg.drawRadialGradient(
                gradient,
                startCenter: center,
                startRadius: 0.5,
                endCenter: center,
                endRadius: size.width / 2,
                options: []
            )
        }
    }

    private static let baseEuler = SCNVector3(0.03, Float.pi * 0.96, -0.08)

    static func create() -> ShipNode {
        let ship = ShipNode()
        ship.name = "ship"
        ship.scale = SCNVector3(1.35, 1.35, 1.35)
        ship.eulerAngles = baseEuler

        let black = silhouetteMaterial()

        // Fuselage — long tapered body
        let fuselagePath = UIBezierPath()
        fuselagePath.move(to: CGPoint(x: 0, y: -2.6))
        fuselagePath.addLine(to: CGPoint(x: 0.20, y: -1.4))
        fuselagePath.addLine(to: CGPoint(x: 0.22, y: 0.0))
        fuselagePath.addLine(to: CGPoint(x: 0.18, y: 1.0))
        fuselagePath.addLine(to: CGPoint(x: 0, y: 1.1))
        fuselagePath.addLine(to: CGPoint(x: -0.18, y: 1.0))
        fuselagePath.addLine(to: CGPoint(x: -0.22, y: 0.0))
        fuselagePath.addLine(to: CGPoint(x: -0.20, y: -1.4))
        fuselagePath.close()
        let fuselageGeom = SCNShape(path: fuselagePath, extrusionDepth: 0.12)
        fuselageGeom.materials = [black]
        let fuselage = SCNNode(geometry: fuselageGeom)
        fuselage.eulerAngles.x = -.pi / 2
        fuselage.position = SCNVector3(0, 0.02, -0.12)
        ship.addChildNode(fuselage)

        // Nose — sharp pointed cone
        let noseGeom = SCNCone(topRadius: 0.003, bottomRadius: 0.10, height: 1.20)
        noseGeom.materials = [black]
        let nose = SCNNode(geometry: noseGeom)
        nose.position = SCNVector3(0, 0.01, -2.20)
        nose.eulerAngles.x = .pi / 2
        ship.addChildNode(nose)

        // Left wing — swept-back delta
        let leftWingPath = UIBezierPath()
        leftWingPath.move(to: CGPoint(x: 0, y: 0.3))
        leftWingPath.addLine(to: CGPoint(x: -2.30, y: -0.10))
        leftWingPath.addLine(to: CGPoint(x: -1.80, y: -0.45))
        leftWingPath.addLine(to: CGPoint(x: 0, y: -0.40))
        leftWingPath.close()
        let leftWingGeom = SCNShape(path: leftWingPath, extrusionDepth: 0.05)
        leftWingGeom.materials = [black]
        let leftWing = SCNNode(geometry: leftWingGeom)
        leftWing.eulerAngles.x = -.pi / 2
        leftWing.position = SCNVector3(-0.10, -0.02, 0.10)
        ship.addChildNode(leftWing)

        // Right wing — swept-back delta (mirrored)
        let rightWingPath = UIBezierPath()
        rightWingPath.move(to: CGPoint(x: 0, y: 0.3))
        rightWingPath.addLine(to: CGPoint(x: 2.30, y: -0.10))
        rightWingPath.addLine(to: CGPoint(x: 1.80, y: -0.45))
        rightWingPath.addLine(to: CGPoint(x: 0, y: -0.40))
        rightWingPath.close()
        let rightWingGeom = SCNShape(path: rightWingPath, extrusionDepth: 0.05)
        rightWingGeom.materials = [black]
        let rightWing = SCNNode(geometry: rightWingGeom)
        rightWing.eulerAngles.x = -.pi / 2
        rightWing.position = SCNVector3(0.10, -0.02, 0.10)
        ship.addChildNode(rightWing)

        // Left wing tip accent — sharp trailing edge
        let leftTipGeom = SCNBox(width: 0.40, height: 0.04, length: 0.18, chamferRadius: 0)
        leftTipGeom.materials = [black]
        let leftTip = SCNNode(geometry: leftTipGeom)
        leftTip.position = SCNVector3(-2.10, -0.02, 0.0)
        leftTip.eulerAngles.y = 0.25
        ship.addChildNode(leftTip)

        // Right wing tip accent
        let rightTipGeom = SCNBox(width: 0.40, height: 0.04, length: 0.18, chamferRadius: 0)
        rightTipGeom.materials = [black]
        let rightTip = SCNNode(geometry: rightTipGeom)
        rightTip.position = SCNVector3(2.10, -0.02, 0.0)
        rightTip.eulerAngles.y = -0.25
        ship.addChildNode(rightTip)

        // Rear engine housings
        for x: Float in [-0.34, 0.34] {
            let housingGeom = SCNBox(width: 0.30, height: 0.14, length: 0.80, chamferRadius: 0.02)
            housingGeom.materials = [black]
            let housing = SCNNode(geometry: housingGeom)
            housing.position = SCNVector3(x, 0.05, 0.65)
            ship.addChildNode(housing)
        }

        // Engine nozzles
        for x: Float in [-0.34, 0.34] {
            let nozzleGeom = SCNCone(topRadius: 0.08, bottomRadius: 0.12, height: 0.22)
            nozzleGeom.materials = [black]
            let nozzle = SCNNode(geometry: nozzleGeom)
            nozzle.position = SCNVector3(x, 0.05, 1.06)
            nozzle.eulerAngles.x = -.pi / 2
            ship.addChildNode(nozzle)
        }

        // Vertical stabilizers — angled outward
        let leftFinPath = UIBezierPath()
        leftFinPath.move(to: CGPoint(x: 0, y: 0))
        leftFinPath.addLine(to: CGPoint(x: -0.08, y: 0.50))
        leftFinPath.addLine(to: CGPoint(x: 0.18, y: 0.38))
        leftFinPath.addLine(to: CGPoint(x: 0.22, y: 0))
        leftFinPath.close()
        let leftFinGeom = SCNShape(path: leftFinPath, extrusionDepth: 0.04)
        leftFinGeom.materials = [black]
        let leftFin = SCNNode(geometry: leftFinGeom)
        leftFin.position = SCNVector3(-0.38, 0.12, 0.52)
        leftFin.eulerAngles.z = 0.18
        ship.addChildNode(leftFin)

        let rightFinPath = UIBezierPath()
        rightFinPath.move(to: CGPoint(x: 0, y: 0))
        rightFinPath.addLine(to: CGPoint(x: 0.08, y: 0.50))
        rightFinPath.addLine(to: CGPoint(x: -0.18, y: 0.38))
        rightFinPath.addLine(to: CGPoint(x: -0.22, y: 0))
        rightFinPath.close()
        let rightFinGeom = SCNShape(path: rightFinPath, extrusionDepth: 0.04)
        rightFinGeom.materials = [black]
        let rightFin = SCNNode(geometry: rightFinGeom)
        rightFin.position = SCNVector3(0.38, 0.12, 0.52)
        rightFin.eulerAngles.z = -0.18
        ship.addChildNode(rightFin)

        // Rim light shell for visibility against dark backgrounds
        let rimPath = UIBezierPath()
        rimPath.move(to: CGPoint(x: 0, y: -2.5))
        rimPath.addLine(to: CGPoint(x: 0.24, y: -1.2))
        rimPath.addLine(to: CGPoint(x: 0.24, y: 1.0))
        rimPath.addLine(to: CGPoint(x: 0, y: 1.1))
        rimPath.addLine(to: CGPoint(x: -0.24, y: 1.0))
        rimPath.addLine(to: CGPoint(x: -0.24, y: -1.2))
        rimPath.close()
        let rimGeom = SCNShape(path: rimPath, extrusionDepth: 0.14)
        let rimMaterial = SCNMaterial()
        rimMaterial.lightingModel = .constant
        rimMaterial.diffuse.contents = UIColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1)
        rimMaterial.emission.contents = UIColor(red: 0.165, green: 0.137, blue: 0.157, alpha: 1)
        rimMaterial.transparency = 0.18
        rimMaterial.isDoubleSided = true
        rimGeom.materials = [rimMaterial]
        let rim = SCNNode(geometry: rimGeom)
        rim.eulerAngles.x = -.pi / 2
        rim.position = SCNVector3(0, 0.02, -0.12)
        ship.addChildNode(rim)

        let engineCoreGeom = SCNSphere(radius: 0.08)
        engineCoreGeom.materials = [engineCoreMaterial()]
        for x in [-0.34, 0.34] {
            let core = SCNNode(geometry: engineCoreGeom)
            core.position = SCNVector3(Float(x), 0.05, 1.08)
            if let material = core.geometry?.firstMaterial {
                ship.engineCoreMaterials.append(material)
            }
            ship.addChildNode(core)
        }

        let glowLight = SCNLight()
        glowLight.type = .omni
        glowLight.color = engineGlowColor
        glowLight.attenuationStartDistance = 0
        glowLight.attenuationEndDistance = 12
        glowLight.intensity = 1050
        let glowNode = SCNNode()
        glowNode.light = glowLight
        glowNode.position = SCNVector3(0, 0.06, 1.10)
        ship.engineGlowLight = glowLight
        ship.addChildNode(glowNode)

        let trailImage = softTrailImage()
        let jetImage = jetCoreImage()

        let trailColorAnim = CAKeyframeAnimation()
        trailColorAnim.values = [
            engineGlowColor.withAlphaComponent(0.52),
            engineTrailColor.withAlphaComponent(0.24),
            engineTrailColor.withAlphaComponent(0.0)
        ]
        trailColorAnim.keyTimes = [0, 0.55, 1.0]
        trailColorAnim.duration = 1.0
        let trailColorController = SCNParticlePropertyController(animation: trailColorAnim)

        for x in [-0.34, 0.34] {
            let jet = SCNParticleSystem()
            jet.birthRate = 150
            jet.particleLifeSpan = 0.11
            jet.particleLifeSpanVariation = 0.03
            jet.particleSize = 0.13
            jet.particleSizeVariation = 0.03
            jet.particleColor = engineCoreColor.withAlphaComponent(0.95)
            jet.particleImage = jetImage
            jet.blendMode = .additive
            jet.emittingDirection = SCNVector3(0, 0, 1)
            jet.particleVelocity = 14
            jet.particleVelocityVariation = 2.0
            jet.acceleration = SCNVector3(0, -0.06, 3.0)
            jet.spreadingAngle = 5
            jet.stretchFactor = 5.5
            jet.fresnelExponent = 0
            jet.isAffectedByGravity = false
            jet.isLightingEnabled = false

            let trail = SCNParticleSystem()
            trail.birthRate = 70
            trail.particleLifeSpan = 0.44
            trail.particleLifeSpanVariation = 0.08
            trail.particleSize = 0.10
            trail.particleSizeVariation = 0.025
            trail.particleColor = engineGlowColor.withAlphaComponent(0.52)
            trail.particleImage = trailImage
            trail.blendMode = .alpha
            trail.emittingDirection = SCNVector3(0, 0, 1)
            trail.particleVelocity = 6.0
            trail.particleVelocityVariation = 1.0
            trail.acceleration = SCNVector3(0, -0.04, 0.6)
            trail.spreadingAngle = 3
            trail.stretchFactor = 4.2
            trail.fresnelExponent = 0
            trail.isAffectedByGravity = false
            trail.isLightingEnabled = false
            trail.propertyControllers = [.color: trailColorController]

            let emitter = SCNNode()
            emitter.position = SCNVector3(Float(x), 0.05, 1.10)
            emitter.eulerAngles.y = .pi
            emitter.addParticleSystem(jet)
            emitter.addParticleSystem(trail)
            ship.engineJetSystems.append(jet)
            ship.engineTrailSystems.append(trail)
            ship.addChildNode(emitter)
        }

        ship.setEnginePower(0.65)

        for child in ship.childNodes where child.geometry != nil {
            child.renderingOrder = 30
        }
        ship.renderingOrder = 30

        let shape = SCNPhysicsShape(
            geometry: SCNBox(width: 2.25, height: 0.64, length: 2.35, chamferRadius: 0),
            options: nil
        )
        let physicsBody = SCNPhysicsBody(type: .kinematic, shape: shape)
        physicsBody.categoryBitMask = PhysicsCategory.ship
        physicsBody.contactTestBitMask = PhysicsCategory.obstacle | PhysicsCategory.enemyBullet | PhysicsCategory.powerUp
        physicsBody.collisionBitMask = PhysicsCategory.none
        ship.physicsBody = physicsBody

        return ship
    }

    func setEnginePower(_ power: CGFloat) {
        let p = max(0, min(1, power))
        let flicker = 0.96 + 0.04 * sin(CGFloat(CACurrentMediaTime()) * 11.0)
        engineGlowLight?.intensity = (800 + (p * 2400)) * flicker
        engineGlowLight?.attenuationEndDistance = 9 + (p * 6)
        engineGlowLight?.color = Self.engineGlowColor

        let hot = Self.engineGlowColor
        let whiteHot = Self.engineCoreColor
        let coreColor = UIColor.lerp(from: hot, to: whiteHot, t: p * 0.75)
        for material in engineCoreMaterials {
            material.emission.contents = coreColor
            material.diffuse.contents = UIColor.lerp(from: Self.engineCoreColor, to: whiteHot, t: p * 0.25)
        }

        for jet in engineJetSystems {
            jet.birthRate = (100 + (p * 160)) * flicker
            jet.particleVelocity = 10 + (p * 8)
            jet.particleSize = 0.10 + (p * 0.05)
            jet.stretchFactor = 5.0 + (p * 1.8)
        }
        for trail in engineTrailSystems {
            trail.birthRate = (40 + (p * 60)) * flicker
            trail.particleVelocity = 5.0 + (p * 2.5)
            trail.particleLifeSpan = 0.35 + (p * 0.12)
            trail.particleSize = 0.09 + (p * 0.04)
        }
    }

    func applyTilt(_ dx: Float, dy: Float = 0) {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.12
        let bank = (-dx * 0.3).clamped(to: -0.6...0.6)
        let pitch = (dy * 0.25).clamped(to: -0.3...0.3)
        eulerAngles = SCNVector3(
            Self.baseEuler.x + pitch,
            Self.baseEuler.y,
            Self.baseEuler.z + bank
        )
        SCNTransaction.commit()
    }
}

extension Float {
    func clamped(to range: ClosedRange<Float>) -> Float {
        Swift.max(range.lowerBound, Swift.min(range.upperBound, self))
    }
}

