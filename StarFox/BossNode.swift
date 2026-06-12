//
//  BossNode.swift
//  StarFox
//
//  Sector guardian: an orange reactor core behind a cage of rotating
//  charcoal armor plates. Three phases — as damage accumulates it moves
//  faster, spins its armor harder and fires denser patterns.
//

import SceneKit

enum BossAttack {
    case aimedShot          // single bolt at the player
    case spreadBurst        // 3-shot fan at the player
    case radialRing         // ring of bolts in the corridor plane
}

class BossNode: SCNNode {
    var health: Int = 20
    private(set) var maxHealth: Int = 20

    private var movementAngle: Float = 0
    private var plateRig = SCNNode()
    private var coreMaterial: SCNMaterial?

    /// 1 (fresh) → 3 (enraged).
    var phase: Int {
        let ratio = Float(health) / Float(max(1, maxHealth))
        if ratio > 0.66 { return 1 }
        if ratio > 0.33 { return 2 }
        return 3
    }

    var attackInterval: TimeInterval {
        switch phase {
        case 1: return 2.2
        case 2: return 1.5
        default: return 1.0
        }
    }

    func nextAttack() -> BossAttack {
        switch phase {
        case 1:
            return .aimedShot
        case 2:
            return Bool.random() ? .spreadBurst : .aimedShot
        default:
            let roll = Double.random(in: 0...1)
            if roll < 0.35 { return .radialRing }
            if roll < 0.75 { return .spreadBurst }
            return .aimedShot
        }
    }

    private static func silhouetteMaterial() -> SCNMaterial {
        let material = SCNMaterial()
        material.lightingModel = .constant
        material.diffuse.contents = UIColor(white: 0.05, alpha: 1)
        material.emission.contents = UIColor(white: 0.02, alpha: 1)
        material.isDoubleSided = true
        return material
    }

    static func create(health: Int) -> BossNode {
        let boss = BossNode()
        boss.health = health
        boss.maxHealth = health
        boss.name = "boss"

        let accentColor = UIColor.cSafetyOrange

        // Reactor core — the glowing weak point.
        let coreGeom = SCNSphere(radius: 1.7)
        coreGeom.segmentCount = 10
        let coreMat = SCNMaterial()
        coreMat.lightingModel = .constant
        coreMat.diffuse.contents = accentColor
        coreMat.emission.contents = accentColor.withAlphaComponent(0.7)
        coreGeom.materials = [coreMat]
        boss.geometry = coreGeom
        boss.coreMaterial = coreMat

        // Cage of armor plates orbiting the core.
        let rig = boss.plateRig
        boss.addChildNode(rig)
        let plateCount = 6
        for i in 0..<plateCount {
            let angle = Float(i) * (.pi * 2) / Float(plateCount)
            let plateGeom = SCNBox(width: 2.4, height: 3.4, length: 0.45, chamferRadius: 0.06)
            plateGeom.materials = [silhouetteMaterial()]
            let plate = SCNNode(geometry: plateGeom)
            plate.position = SCNVector3(cos(angle) * 3.4, 0, sin(angle) * 3.4)
            plate.eulerAngles.y = -angle + .pi / 2
            rig.addChildNode(plate)
        }

        // Upper and lower armor caps.
        for sign: Float in [-1, 1] {
            let capGeom = SCNCone(topRadius: 0.2, bottomRadius: 2.1, height: 1.6)
            capGeom.materials = [silhouetteMaterial()]
            let cap = SCNNode(geometry: capGeom)
            cap.position = SCNVector3(0, sign * 2.9, 0)
            if sign < 0 { cap.eulerAngles.x = .pi }
            boss.addChildNode(cap)
        }

        // Core light pulse.
        let coreLight = SCNLight()
        coreLight.type = .omni
        coreLight.color = accentColor
        coreLight.attenuationStartDistance = 0
        coreLight.attenuationEndDistance = 18
        coreLight.intensity = 600
        let coreLightNode = SCNNode()
        coreLightNode.light = coreLight
        boss.addChildNode(coreLightNode)

        let pulseUp = SCNAction.customAction(duration: 0.5) { node, t in
            node.light?.intensity = 400 + CGFloat(t / 0.5) * 500
        }
        let pulseDown = SCNAction.customAction(duration: 0.5) { node, t in
            node.light?.intensity = 900 - CGFloat(t / 0.5) * 500
        }
        coreLightNode.runAction(SCNAction.repeatForever(SCNAction.sequence([pulseUp, pulseDown])))

        let shape = SCNPhysicsShape(geometry: SCNSphere(radius: 3.6), options: nil)
        let body = SCNPhysicsBody(type: .kinematic, shape: shape)
        body.categoryBitMask = PhysicsCategory.obstacle
        body.contactTestBitMask = PhysicsCategory.ship | PhysicsCategory.projectile
        body.collisionBitMask = PhysicsCategory.none
        boss.physicsBody = body

        return boss
    }

    func update(dt: TimeInterval) {
        let speed: Float = 0.6 + Float(phase) * 0.30
        movementAngle += Float(dt) * speed
        let radius: Float = 5.0 + Float(phase)
        position.x = cos(movementAngle) * radius
        position.y = sin(movementAngle * 0.55) * 2.6

        plateRig.eulerAngles.y += Float(dt) * (0.8 + Float(phase) * 0.55)
    }

    func takeDamage() -> Bool {
        health -= 1

        let flashColor = UIColor(red: 1.0, green: 0.85, blue: 0.6, alpha: 1)
        let baseColor = UIColor.cSafetyOrange
        coreMaterial?.diffuse.contents = flashColor
        coreMaterial?.emission.contents = flashColor

        removeAction(forKey: "bossFlash")
        let restore = SCNAction.sequence([
            SCNAction.wait(duration: 0.13),
            SCNAction.run { [weak self] _ in
                self?.coreMaterial?.diffuse.contents = baseColor
                self?.coreMaterial?.emission.contents = baseColor.withAlphaComponent(0.7)
            }
        ])
        runAction(restore, forKey: "bossFlash")

        return health <= 0
    }
}
