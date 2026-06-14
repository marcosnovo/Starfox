//
//  ShipNode.swift
//  StarFox
//
//  Arwing-style fighter built from charcoal silhouettes with safety-orange
//  engine glow and mint accents, in keeping with the project's comic style.
//  Forward is +Z. All visible geometry hangs off `airframe` so the barrel
//  roll and bank/pitch tilt never disturb the physics body on the root.
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

    private(set) var airframe = SCNNode()
    private(set) var isRolling = false
    private(set) var rollDirection: Float = 0

    // Wing damage (SNES style): -1 left broken, +1 right broken, 0 intact.
    private(set) var brokenWingSide: Float = 0
    var hasBrokenWing: Bool { brokenWingSide != 0 }
    private var leftWingParts: [SCNNode] = []
    private var rightWingParts: [SCNNode] = []
    private var wingSparkEmitter: SCNNode?

    private var engineGlowLight: SCNLight?
    private var engineCoreMaterials: [SCNMaterial] = []
    private var engineJetSystems: [SCNParticleSystem] = []
    private var engineTrailSystems: [SCNParticleSystem] = []
    private var currentBank: Float = 0
    private var currentPitch: Float = 0

    private static let engineCoreColor  = UIColor(red: 1.0, green: 0.9647, blue: 0.8157, alpha: 1.0) // #FFF6D0
    private static let engineGlowColor  = UIColor(red: 1.0, green: 0.6039, blue: 0.2706, alpha: 1.0) // #FF9A45
    private static let engineTrailColor = UIColor(red: 0.9412, green: 0.4157, blue: 0.3020, alpha: 1.0) // #F06A4D

    // Local muzzle positions on the airframe (wing cannons and nose gun).
    static let leftMuzzleLocal  = SCNVector3(-1.55, -0.18, 1.05)
    static let rightMuzzleLocal = SCNVector3( 1.55, -0.18, 1.05)
    static let noseMuzzleLocal  = SCNVector3( 0.0,   0.0,  2.9)

    // MARK: - Materials

    /// Dark gunmetal hull, physically lit so the warm sun-rim and cool
    /// under-fill model its form — the difference between a 3D craft and a
    /// flat cutout.
    private static func silhouetteMaterial() -> SCNMaterial {
        let material = SCNMaterial()
        material.lightingModel = .physicallyBased
        material.diffuse.contents = UIColor(red: 0.13, green: 0.15, blue: 0.20, alpha: 1)
        material.metalness.contents = 0.55
        material.roughness.contents = 0.40
        material.isDoubleSided = true
        return material
    }

    /// Lighter brushed-metal panels for the upper surfaces, catching more
    /// of the sunset so the silhouette has tonal variation.
    private static func panelMaterial() -> SCNMaterial {
        let material = SCNMaterial()
        material.lightingModel = .physicallyBased
        material.diffuse.contents = UIColor(red: 0.24, green: 0.27, blue: 0.33, alpha: 1)
        material.metalness.contents = 0.45
        material.roughness.contents = 0.55
        material.isDoubleSided = true
        return material
    }

    private static func mintAccentMaterial() -> SCNMaterial {
        let material = SCNMaterial()
        material.lightingModel = .constant
        // Bright emissive so the bloom turns the wing edges and cockpit
        // into glowing trim against the dark silhouette.
        material.diffuse.contents = UIColor(red: 0.6, green: 1.0, blue: 0.92, alpha: 1)
        material.emission.contents = UIColor(red: 0.45, green: 1.0, blue: 0.9, alpha: 1)
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
                startCenter: center, startRadius: 1,
                endCenter: center, endRadius: size.width / 2,
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
                startCenter: center, startRadius: 0.5,
                endCenter: center, endRadius: size.width / 2,
                options: []
            )
        }
    }

    // MARK: - Construction

    static func create() -> ShipNode {
        let ship = ShipNode()
        ship.name = "ship"

        let frame = ship.airframe
        frame.name = "airframe"
        frame.scale = SCNVector3(1.15, 1.15, 1.15)
        ship.addChildNode(frame)

        let black = silhouetteMaterial()
        let panel = panelMaterial()
        let mint = mintAccentMaterial()

        // Fuselage — elongated hexagon (top view), extruded for thickness.
        // Drawn in XY with +Y as forward, then rotated so +Y maps to +Z.
        let fuselagePath = UIBezierPath()
        fuselagePath.move(to: CGPoint(x: 0, y: 2.45))
        fuselagePath.addLine(to: CGPoint(x: 0.30, y: 0.85))
        fuselagePath.addLine(to: CGPoint(x: 0.38, y: -0.25))
        fuselagePath.addLine(to: CGPoint(x: 0.22, y: -1.30))
        fuselagePath.addLine(to: CGPoint(x: -0.22, y: -1.30))
        fuselagePath.addLine(to: CGPoint(x: -0.38, y: -0.25))
        fuselagePath.addLine(to: CGPoint(x: -0.30, y: 0.85))
        fuselagePath.close()
        let fuselageGeom = SCNShape(path: fuselagePath, extrusionDepth: 0.26)
        fuselageGeom.materials = [black]
        let fuselage = SCNNode(geometry: fuselageGeom)
        fuselage.eulerAngles.x = .pi / 2
        fuselage.position = SCNVector3(0, 0, 0)
        frame.addChildNode(fuselage)

        // Nose cone — long needle ahead of the fuselage.
        let noseGeom = SCNCone(topRadius: 0.005, bottomRadius: 0.13, height: 1.1)
        noseGeom.materials = [black]
        let nose = SCNNode(geometry: noseGeom)
        nose.eulerAngles.x = .pi / 2
        nose.position = SCNVector3(0, 0.0, 2.85)
        frame.addChildNode(nose)

        // Canopy — small raised wedge behind the nose.
        let canopyGeom = SCNPyramid(width: 0.34, height: 0.24, length: 0.85)
        canopyGeom.materials = [panel]
        let canopy = SCNNode(geometry: canopyGeom)
        canopy.position = SCNVector3(0, 0.13, 0.85)
        frame.addChildNode(canopy)

        // Glowing cockpit dome — focal point so the silhouette reads as a
        // ship, not a blob. Pulses gently.
        let domeGeom = SCNSphere(radius: 0.14)
        domeGeom.materials = [mint]
        let dome = SCNNode(geometry: domeGeom)
        dome.scale = SCNVector3(1.0, 0.6, 1.4)
        dome.position = SCNVector3(0, 0.2, 0.95)
        dome.runAction(SCNAction.repeatForever(SCNAction.sequence([
            SCNAction.fadeOpacity(to: 0.65, duration: 1.1),
            SCNAction.fadeOpacity(to: 1.0, duration: 1.1)
        ])))
        frame.addChildNode(dome)

        // Canopy mint strip — tiny visor accent.
        let visorGeom = SCNBox(width: 0.20, height: 0.05, length: 0.30, chamferRadius: 0.01)
        visorGeom.materials = [mint]
        let visor = SCNNode(geometry: visorGeom)
        visor.position = SCNVector3(0, 0.20, 1.05)
        frame.addChildNode(visor)

        // Wings — forward-swept deltas with downward dihedral (Arwing read).
        // Drawn in XY (top view, +Y forward), rotated flat, then banked.
        for side: Float in [-1, 1] {
            let wingPath = UIBezierPath()
            wingPath.move(to: CGPoint(x: 0, y: 0.55))
            wingPath.addLine(to: CGPoint(x: CGFloat(side) * 2.25, y: 1.05))
            wingPath.addLine(to: CGPoint(x: CGFloat(side) * 2.45, y: 0.25))
            wingPath.addLine(to: CGPoint(x: 0, y: -0.70))
            wingPath.close()
            let wingGeom = SCNShape(path: wingPath, extrusionDepth: 0.07)
            wingGeom.materials = [black]
            let wing = SCNNode(geometry: wingGeom)
            wing.eulerAngles = SCNVector3(Float.pi / 2, 0, side * 0.20)
            wing.position = SCNVector3(side * 0.18, -0.04, -0.10)
            frame.addChildNode(wing)

            // Wingtip fin (G-diffuser style vertical blade).
            let finGeom = SCNBox(width: 0.06, height: 0.46, length: 0.85, chamferRadius: 0.01)
            finGeom.materials = [black]
            let fin = SCNNode(geometry: finGeom)
            fin.position = SCNVector3(side * 2.45, -0.50, 0.55)
            fin.eulerAngles.z = side * 0.12
            frame.addChildNode(fin)

            // Mint leading-edge strip on each wing.
            let stripGeom = SCNBox(width: 1.7, height: 0.035, length: 0.09, chamferRadius: 0.01)
            stripGeom.materials = [mint]
            let strip = SCNNode(geometry: stripGeom)
            strip.position = SCNVector3(side * 1.15, -0.22, 0.62)
            strip.eulerAngles = SCNVector3(0, side * -0.21, side * -0.20)
            frame.addChildNode(strip)

            // Wing cannon nub at the tip.
            let cannonGeom = SCNCylinder(radius: 0.045, height: 0.55)
            cannonGeom.materials = [black]
            let cannon = SCNNode(geometry: cannonGeom)
            cannon.eulerAngles.x = .pi / 2
            cannon.position = SCNVector3(side * 1.55, -0.18, 0.95)
            frame.addChildNode(cannon)

            // Navigation light — red to port, green to starboard, like a
            // real aircraft. Pulses softly.
            let navColor = side < 0
                ? UIColor(red: 1.0, green: 0.22, blue: 0.22, alpha: 1)
                : UIColor(red: 0.30, green: 1.0, blue: 0.40, alpha: 1)
            let navMat = SCNMaterial()
            navMat.lightingModel = .constant
            navMat.diffuse.contents = navColor
            navMat.emission.contents = navColor
            let navGeom = SCNSphere(radius: 0.06)
            navGeom.materials = [navMat]
            let nav = SCNNode(geometry: navGeom)
            nav.position = SCNVector3(side * 2.48, -0.50, 0.95)
            nav.runAction(SCNAction.repeatForever(SCNAction.sequence([
                SCNAction.fadeOpacity(to: 0.35, duration: 0.7),
                SCNAction.fadeOpacity(to: 1.0, duration: 0.7)
            ])))
            frame.addChildNode(nav)

            let parts = [wing, fin, strip, cannon, nav]
            if side < 0 {
                ship.leftWingParts = parts
            } else {
                ship.rightWingParts = parts
            }
        }

        // Twin tail fins — angled outward at the rear.
        for side: Float in [-1, 1] {
            let finPath = UIBezierPath()
            finPath.move(to: CGPoint(x: 0, y: 0))
            finPath.addLine(to: CGPoint(x: CGFloat(side) * 0.10, y: 0.55))
            finPath.addLine(to: CGPoint(x: CGFloat(side) * -0.20, y: 0.42))
            finPath.addLine(to: CGPoint(x: CGFloat(side) * -0.24, y: 0))
            finPath.close()
            let finGeom = SCNShape(path: finPath, extrusionDepth: 0.05)
            finGeom.materials = [black]
            let fin = SCNNode(geometry: finGeom)
            fin.position = SCNVector3(side * 0.34, 0.12, -0.85)
            fin.eulerAngles = SCNVector3(0, .pi / 2, side * 0.24)
            frame.addChildNode(fin)
        }

        // Rear engine housings + nozzles.
        for x: Float in [-0.32, 0.32] {
            let housingGeom = SCNBox(width: 0.30, height: 0.16, length: 0.85, chamferRadius: 0.02)
            housingGeom.materials = [black]
            let housing = SCNNode(geometry: housingGeom)
            housing.position = SCNVector3(x, -0.02, -0.95)
            frame.addChildNode(housing)

            let nozzleGeom = SCNCone(topRadius: 0.12, bottomRadius: 0.08, height: 0.22)
            nozzleGeom.materials = [black]
            let nozzle = SCNNode(geometry: nozzleGeom)
            nozzle.eulerAngles.x = .pi / 2
            nozzle.position = SCNVector3(x, -0.02, -1.42)
            frame.addChildNode(nozzle)
        }

        // Engine cores (glowing spheres in the nozzles).
        let engineCoreGeom = SCNSphere(radius: 0.09)
        engineCoreGeom.materials = [engineCoreMaterial()]
        for x: Float in [-0.32, 0.32] {
            let core = SCNNode(geometry: engineCoreGeom.copy() as! SCNGeometry)
            core.position = SCNVector3(x, -0.02, -1.45)
            if let material = core.geometry?.firstMaterial {
                ship.engineCoreMaterials.append(material)
            }
            frame.addChildNode(core)
        }

        let glowLight = SCNLight()
        glowLight.type = .omni
        glowLight.color = engineGlowColor
        glowLight.attenuationStartDistance = 0
        glowLight.attenuationEndDistance = 12
        glowLight.intensity = 1050
        let glowNode = SCNNode()
        glowNode.light = glowLight
        glowNode.position = SCNVector3(0, 0.02, -1.50)
        ship.engineGlowLight = glowLight
        frame.addChildNode(glowNode)

        // Engine exhaust particles, emitting backwards (-Z).
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

        // Two tight blue-hot flames. Short lifespan + low stretch keeps the
        // exhaust as compact cones behind the ship rather than a screen-
        // filling starburst (the camera sits right behind, so anything
        // long-lived and stretched smears across the whole view).
        for x: Float in [-0.32, 0.32] {
            let jet = SCNParticleSystem()
            jet.birthRate = 90
            jet.particleLifeSpan = 0.07
            jet.particleLifeSpanVariation = 0.02
            jet.particleSize = 0.16
            jet.particleSizeVariation = 0.03
            jet.particleColor = engineCoreColor.withAlphaComponent(0.95)
            jet.particleImage = jetImage
            jet.blendMode = .additive
            jet.emittingDirection = SCNVector3(0, 0, -1)
            jet.particleVelocity = 8
            jet.particleVelocityVariation = 1.0
            jet.acceleration = SCNVector3(0, 0, -1.5)
            jet.spreadingAngle = 4
            jet.stretchFactor = 1.6
            jet.fresnelExponent = 0
            jet.isAffectedByGravity = false
            jet.isLightingEnabled = false

            let trail = SCNParticleSystem()
            trail.birthRate = 45
            trail.particleLifeSpan = 0.20
            trail.particleLifeSpanVariation = 0.05
            trail.particleSize = 0.12
            trail.particleSizeVariation = 0.025
            trail.particleColor = engineGlowColor.withAlphaComponent(0.45)
            trail.particleImage = trailImage
            trail.blendMode = .additive
            trail.emittingDirection = SCNVector3(0, 0, -1)
            trail.particleVelocity = 4.0
            trail.particleVelocityVariation = 0.6
            trail.acceleration = SCNVector3(0, 0, -0.4)
            trail.spreadingAngle = 2
            trail.stretchFactor = 1.4
            trail.fresnelExponent = 0
            trail.isAffectedByGravity = false
            trail.isLightingEnabled = false
            trail.propertyControllers = [.color: trailColorController]

            let emitter = SCNNode()
            emitter.position = SCNVector3(x, -0.02, -1.55)
            emitter.addParticleSystem(jet)
            emitter.addParticleSystem(trail)
            ship.engineJetSystems.append(jet)
            ship.engineTrailSystems.append(trail)
            frame.addChildNode(emitter)
        }

        // Wingtip vapor contrails — thin mint streaks that sell the speed.
        for x: Float in [-2.45, 2.45] {
            let vapor = SCNParticleSystem()
            vapor.birthRate = 60
            vapor.particleLifeSpan = 0.5
            vapor.particleLifeSpanVariation = 0.12
            vapor.particleSize = 0.07
            vapor.particleSizeVariation = 0.02
            vapor.particleColor = UIColor(red: 0.7, green: 1.0, blue: 0.95, alpha: 0.22)
            vapor.particleImage = trailImage
            vapor.blendMode = .additive
            vapor.emittingDirection = SCNVector3(0, 0, -1)
            vapor.particleVelocity = 3
            vapor.particleVelocityVariation = 0.5
            vapor.spreadingAngle = 1.5
            vapor.stretchFactor = 2.2
            vapor.isAffectedByGravity = false
            vapor.isLightingEnabled = false
            let vNode = SCNNode()
            vNode.position = SCNVector3(x, -0.45, 0.4)
            vNode.addParticleSystem(vapor)
            frame.addChildNode(vNode)
        }

        ship.setEnginePower(0.65)

        for child in frame.childNodes where child.geometry != nil {
            child.renderingOrder = 30
        }
        frame.renderingOrder = 30

        let shape = SCNPhysicsShape(
            geometry: SCNBox(width: 4.2, height: 0.9, length: 3.6, chamferRadius: 0),
            options: nil
        )
        let physicsBody = SCNPhysicsBody(type: .kinematic, shape: shape)
        physicsBody.categoryBitMask = PhysicsCategory.ship
        physicsBody.contactTestBitMask = PhysicsCategory.obstacle | PhysicsCategory.enemyBullet | PhysicsCategory.powerUp
        physicsBody.collisionBitMask = PhysicsCategory.none
        ship.physicsBody = physicsBody

        return ship
    }

    // MARK: - Muzzles

    func muzzleWorldPosition(_ local: SCNVector3) -> SCNVector3 {
        airframe.convertPosition(local, to: nil)
    }

    // MARK: - Engine

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
            jet.birthRate = (80 + (p * 90)) * flicker
            jet.particleVelocity = 7 + (p * 5)
            jet.particleSize = 0.14 + (p * 0.05)
            jet.stretchFactor = 1.4 + (p * 0.8)
        }
        for trail in engineTrailSystems {
            trail.birthRate = (38 + (p * 40)) * flicker
            trail.particleVelocity = 3.5 + (p * 2.0)
            trail.particleLifeSpan = 0.18 + (p * 0.08)
            trail.particleSize = 0.11 + (p * 0.04)
            trail.stretchFactor = 1.3 + (p * 0.6)
        }
    }

    // MARK: - Flight attitude

    func applyTilt(_ dx: Float, dy: Float = 0) {
        guard !isRolling else { return }
        let targetBank = (-dx * 0.32).clamped(to: -0.75...0.75)
        let targetPitch = (dy * 0.26).clamped(to: -0.35...0.35)
        currentBank += (targetBank - currentBank) * 0.18
        currentPitch += (targetPitch - currentPitch) * 0.18
        airframe.eulerAngles = SCNVector3(currentPitch, 0, currentBank)
    }

    /// SNES-style barrel roll: full 360° spin on the longitudinal axis.
    /// While rolling, incoming fire is deflected (handled by GameScene).
    func barrelRoll(direction: Float) {
        guard !isRolling else { return }
        isRolling = true
        rollDirection = direction
        let spin = SCNAction.rotateBy(
            x: 0, y: 0,
            z: CGFloat(direction) * .pi * 2,
            duration: 0.55
        )
        spin.timingMode = .easeInEaseOut
        let settle = SCNAction.run { [weak self] _ in
            guard let self else { return }
            self.airframe.eulerAngles = SCNVector3(self.currentPitch, 0, self.currentBank)
            self.isRolling = false
        }
        airframe.runAction(SCNAction.sequence([spin, settle]), forKey: "barrelRoll")
    }

    /// Cancels any roll in flight and levels the airframe (scene resets).
    func resetAttitude() {
        airframe.removeAction(forKey: "barrelRoll")
        airframe.removeAction(forKey: "invulnBlink")
        airframe.opacity = 1.0
        isRolling = false
        rollDirection = 0
        currentBank = 0
        currentPitch = 0
        airframe.eulerAngles = SCNVector3Zero
    }

    // MARK: - Wing damage

    /// Scraping a structure shears off the wing on that side: twin lasers
    /// go offline and the ship pulls toward the stump until repaired.
    func breakWing(side: Float) {
        guard brokenWingSide == 0 else { return }
        brokenWingSide = side >= 0 ? 1 : -1
        let parts = brokenWingSide < 0 ? leftWingParts : rightWingParts
        for part in parts { part.isHidden = true }

        let sparks = SCNParticleSystem()
        sparks.birthRate = 55
        sparks.particleLifeSpan = 0.25
        sparks.particleLifeSpanVariation = 0.08
        sparks.particleSize = 0.06
        sparks.particleColor = Self.engineGlowColor.withAlphaComponent(0.8)
        sparks.blendMode = .additive
        sparks.emittingDirection = SCNVector3(0, 0, -1)
        sparks.particleVelocity = 3
        sparks.particleVelocityVariation = 1.5
        sparks.spreadingAngle = 40
        sparks.stretchFactor = 2
        sparks.isAffectedByGravity = false
        sparks.isLightingEnabled = false

        let emitter = SCNNode()
        emitter.position = SCNVector3(brokenWingSide * 0.9, -0.1, 0.2)
        emitter.addParticleSystem(sparks)
        airframe.addChildNode(emitter)
        wingSparkEmitter = emitter
    }

    func repairWings() {
        guard brokenWingSide != 0 else { return }
        brokenWingSide = 0
        for part in leftWingParts + rightWingParts { part.isHidden = false }
        wingSparkEmitter?.removeFromParentNode()
        wingSparkEmitter = nil
    }

    /// Post-damage invulnerability blink, SNES style.
    func flashInvulnerable(duration: TimeInterval) {
        airframe.removeAction(forKey: "invulnBlink")
        let blink = SCNAction.sequence([
            SCNAction.fadeOpacity(to: 0.25, duration: 0.08),
            SCNAction.fadeOpacity(to: 1.0, duration: 0.08)
        ])
        let count = max(1, Int(duration / 0.16))
        let settle = SCNAction.fadeOpacity(to: 1.0, duration: 0.05)
        airframe.runAction(
            SCNAction.sequence([SCNAction.repeat(blink, count: count), settle]),
            forKey: "invulnBlink"
        )
    }
}

extension Float {
    func clamped(to range: ClosedRange<Float>) -> Float {
        Swift.max(range.lowerBound, Swift.min(range.upperBound, self))
    }
}
