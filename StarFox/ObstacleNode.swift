//
//  ObstacleNode.swift
//  StarFox
//
//  Hazards, enemies and pickups for the rail corridor, all rendered as
//  charcoal silhouettes with safety-orange / mint glow accents.
//

import SceneKit

enum ObstacleKind {
    case asteroid       // tumbling low-poly rock, shoot or dodge
    case pillar         // tall tower rising from below the corridor
    case gate           // arch — fly through the middle for a bonus
    case enemyFighter   // weaving fighter that shoots back
    case ring           // gold ring, restores shield
    case powerShield    // pickup: +2 shield cells
    case powerTwin      // pickup: twin lasers for a while
    case powerBomb      // pickup: +1 smart bomb
}

class ObstacleNode: SCNNode {
    var kind: ObstacleKind = .asteroid
    var health: Int = 1

    /// Set once a collision with the ship has been processed, so repeated
    /// physics contacts against the same node don't drain the whole shield.
    var hasHarmedShip = false
    /// Gate-only: the center sensor was crossed.
    var gateCleared = false

    /// Enemy formation bookkeeping (group kill bonus, SNES style).
    var formationID: Int = 0

    /// Enemy flight behavior.
    var weavePhase: Float = 0
    var weaveAmplitude: Float = 0
    var weaveFrequency: Float = 1.2
    var baseX: Float = 0
    var baseY: Float = 0
    var approachSpeed: Float = 0
    var fireCooldown: TimeInterval = 2.0
    private var age: TimeInterval = 0

    var isEnemy: Bool { kind == .enemyFighter }
    var isPowerUp: Bool { kind == .powerShield || kind == .powerTwin || kind == .powerBomb }
    var isHostile: Bool { kind == .asteroid || kind == .pillar || kind == .enemyFighter }

    // MARK: - Materials

    private static func silhouetteMaterial(_ tint: UIColor = UIColor(white: 0.05, alpha: 1)) -> SCNMaterial {
        let material = SCNMaterial()
        material.lightingModel = .constant
        material.diffuse.contents = tint
        material.emission.contents = UIColor(white: 0.02, alpha: 1)
        material.isDoubleSided = true
        return material
    }

    private static func glowMaterial(_ color: UIColor, emission: UIColor) -> SCNMaterial {
        let material = SCNMaterial()
        material.lightingModel = .constant
        material.diffuse.contents = color
        material.emission.contents = emission
        material.isDoubleSided = true
        return material
    }

    private static let orangeAccent = UIColor.cSafetyOrange
    private static let mintAccent = UIColor.cMintMetal
    private static let goldRing = UIColor(red: 0.85, green: 0.62, blue: 0.28, alpha: 1)

    // MARK: - Factory

    static func create(kind: ObstacleKind, at position: SCNVector3) -> ObstacleNode {
        let node = ObstacleNode()
        node.kind = kind
        node.position = position

        switch kind {
        case .asteroid:      buildAsteroid(node)
        case .pillar:        buildPillar(node)
        case .gate:          buildGate(node)
        case .enemyFighter:  buildEnemyFighter(node)
        case .ring:          buildRing(node)
        case .powerShield:   buildPowerUp(node, color: mintAccent, symbolSides: 3)
        case .powerTwin:     buildPowerUp(node, color: orangeAccent, symbolSides: 4)
        case .powerBomb:     buildPowerUp(node, color: goldRing, symbolSides: 5)
        }
        return node
    }

    private static func attachBody(
        _ node: SCNNode,
        geometry: SCNGeometry,
        category: Int,
        name: String
    ) {
        node.name = name
        let shape = SCNPhysicsShape(geometry: geometry, options: nil)
        let body = SCNPhysicsBody(type: .kinematic, shape: shape)
        body.categoryBitMask = category
        body.contactTestBitMask = PhysicsCategory.ship | PhysicsCategory.projectile
        body.collisionBitMask = PhysicsCategory.none
        node.physicsBody = body
    }

    // MARK: - Builders

    private static func buildAsteroid(_ node: ObstacleNode) {
        node.health = 2
        let radius = CGFloat.random(in: 1.0...1.9)
        let geom = SCNSphere(radius: radius)
        geom.segmentCount = 5
        geom.materials = [silhouetteMaterial()]
        node.geometry = geom

        // Orange ember veins.
        for _ in 0..<3 {
            let emberGeom = SCNBox(width: radius * 0.5, height: 0.08, length: 0.08, chamferRadius: 0)
            emberGeom.materials = [glowMaterial(orangeAccent, emission: orangeAccent.withAlphaComponent(0.35))]
            let ember = SCNNode(geometry: emberGeom)
            ember.position = SCNVector3(
                Float.random(in: -0.4...0.4) * Float(radius),
                Float.random(in: -0.4...0.4) * Float(radius),
                Float(radius) * 0.82
            )
            ember.eulerAngles = SCNVector3(
                Float.random(in: 0...Float.pi),
                Float.random(in: 0...Float.pi),
                Float.random(in: 0...Float.pi)
            )
            node.addChildNode(ember)
        }

        node.runAction(SCNAction.repeatForever(
            SCNAction.rotate(by: .pi, around: SCNVector3(0.4, 1, 0.3), duration: Double.random(in: 2.4...4.0))
        ))
        attachBody(node, geometry: SCNSphere(radius: radius), category: PhysicsCategory.obstacle, name: "obstacle")
    }

    private static func buildPillar(_ node: ObstacleNode) {
        node.health = 3
        let height = CGFloat.random(in: 7...11)
        let geom = SCNBox(width: 1.7, height: height, length: 1.7, chamferRadius: 0.05)
        geom.materials = [silhouetteMaterial()]
        node.geometry = geom

        // Beacon light on top.
        let beaconGeom = SCNSphere(radius: 0.18)
        beaconGeom.materials = [glowMaterial(orangeAccent, emission: orangeAccent.withAlphaComponent(0.6))]
        let beacon = SCNNode(geometry: beaconGeom)
        beacon.position = SCNVector3(0, Float(height) / 2 + 0.2, 0)
        node.addChildNode(beacon)
        beacon.runAction(SCNAction.repeatForever(SCNAction.sequence([
            SCNAction.fadeOpacity(to: 0.25, duration: 0.5),
            SCNAction.fadeOpacity(to: 1.0, duration: 0.5)
        ])))

        attachBody(
            node,
            geometry: SCNBox(width: 1.7, height: height, length: 1.7, chamferRadius: 0),
            category: PhysicsCategory.obstacle,
            name: "obstacle"
        )
    }

    private static func buildGate(_ node: ObstacleNode) {
        node.health = 999
        node.name = "gateRoot"
        let frameMat = silhouetteMaterial()

        let innerHalfWidth: CGFloat = 3.1
        let innerHeight: CGFloat = 5.2
        let beam: CGFloat = 0.9

        // Two uprights + lintel, each with its own collision body.
        for side: CGFloat in [-1, 1] {
            let postGeom = SCNBox(width: beam, height: innerHeight + beam, length: beam, chamferRadius: 0.04)
            postGeom.materials = [frameMat]
            let post = SCNNode(geometry: postGeom)
            post.position = SCNVector3(Float(side * (innerHalfWidth + beam / 2)), 0, 0)
            attachBody(post, geometry: postGeom, category: PhysicsCategory.obstacle, name: "gateFrame")
            node.addChildNode(post)
        }
        let lintelGeom = SCNBox(width: (innerHalfWidth + beam) * 2, height: beam, length: beam, chamferRadius: 0.04)
        lintelGeom.materials = [frameMat]
        let lintel = SCNNode(geometry: lintelGeom)
        lintel.position = SCNVector3(0, Float(innerHeight / 2 + beam / 2), 0)
        attachBody(lintel, geometry: lintelGeom, category: PhysicsCategory.obstacle, name: "gateFrame")
        node.addChildNode(lintel)

        // Mint marker lights along the inside edge.
        for side: CGFloat in [-1, 1] {
            let lampGeom = SCNBox(width: 0.14, height: 1.6, length: 0.14, chamferRadius: 0.02)
            lampGeom.materials = [glowMaterial(mintAccent, emission: mintAccent.withAlphaComponent(0.6))]
            let lamp = SCNNode(geometry: lampGeom)
            lamp.position = SCNVector3(Float(side * innerHalfWidth), 0, 0)
            node.addChildNode(lamp)
        }

        // Invisible center sensor: crossing it scores the gate bonus.
        let sensorGeom = SCNBox(width: innerHalfWidth * 2 - 0.6, height: innerHeight - 0.6, length: 0.5, chamferRadius: 0)
        let sensor = SCNNode()
        sensor.name = "gateCenter"
        let sensorShape = SCNPhysicsShape(geometry: sensorGeom, options: nil)
        let sensorBody = SCNPhysicsBody(type: .kinematic, shape: sensorShape)
        sensorBody.categoryBitMask = PhysicsCategory.powerUp
        sensorBody.contactTestBitMask = PhysicsCategory.ship
        sensorBody.collisionBitMask = PhysicsCategory.none
        sensor.physicsBody = sensorBody
        node.addChildNode(sensor)
    }

    private static func buildEnemyFighter(_ node: ObstacleNode) {
        node.health = 2
        let dark = silhouetteMaterial()

        // Angular dart body.
        let bodyGeom = SCNBox(width: 0.8, height: 0.4, length: 1.5, chamferRadius: 0.02)
        bodyGeom.materials = [dark]
        let body = SCNNode(geometry: bodyGeom)
        node.addChildNode(body)

        // Swept wings.
        let wingGeom = SCNBox(width: 3.4, height: 0.09, length: 0.9, chamferRadius: 0)
        wingGeom.materials = [dark]
        let wings = SCNNode(geometry: wingGeom)
        wings.position = SCNVector3(0, 0, 0.25)
        wings.eulerAngles.y = 0.0
        node.addChildNode(wings)

        // Orange nose spike facing the player (-Z, they fly toward us).
        let noseGeom = SCNCone(topRadius: 0, bottomRadius: 0.22, height: 0.8)
        noseGeom.materials = [glowMaterial(orangeAccent, emission: orangeAccent.withAlphaComponent(0.55))]
        let nose = SCNNode(geometry: noseGeom)
        nose.eulerAngles.x = -.pi / 2
        nose.position = SCNVector3(0, 0, -0.95)
        node.addChildNode(nose)

        // Engine glow at the back.
        let engineLight = SCNLight()
        engineLight.type = .omni
        engineLight.color = orangeAccent
        engineLight.attenuationStartDistance = 0
        engineLight.attenuationEndDistance = 3
        engineLight.intensity = 200
        let engineGlowNode = SCNNode()
        engineGlowNode.light = engineLight
        engineGlowNode.position = SCNVector3(0, 0, 0.9)
        node.addChildNode(engineGlowNode)

        attachBody(
            node,
            geometry: SCNBox(width: 3.2, height: 0.6, length: 1.6, chamferRadius: 0),
            category: PhysicsCategory.obstacle,
            name: "enemy"
        )
    }

    private static func buildRing(_ node: ObstacleNode) {
        node.health = 999
        let geom = SCNTorus(ringRadius: 1.9, pipeRadius: 0.22)
        geom.materials = [glowMaterial(goldRing, emission: goldRing.withAlphaComponent(0.5))]
        node.geometry = geom
        node.eulerAngles.x = .pi / 2

        node.runAction(SCNAction.repeatForever(SCNAction.sequence([
            SCNAction.scale(to: 1.07, duration: 0.6),
            SCNAction.scale(to: 0.95, duration: 0.6)
        ])))

        attachBody(
            node,
            geometry: SCNBox(width: 3.4, height: 0.8, length: 3.4, chamferRadius: 0),
            category: PhysicsCategory.powerUp,
            name: "ring"
        )
    }

    private static func buildPowerUp(_ node: ObstacleNode, color: UIColor, symbolSides: Int) {
        node.health = 999
        let geom = SCNBox(width: 0.95, height: 0.95, length: 0.95, chamferRadius: 0.14)
        geom.materials = [glowMaterial(color, emission: color.withAlphaComponent(0.45))]
        node.geometry = geom
        node.runAction(SCNAction.repeatForever(
            SCNAction.rotate(by: .pi * 2, around: SCNVector3(0.4, 1, 0.3), duration: 1.6)
        ))

        for i in 0..<symbolSides {
            let angle = Float(i) * (.pi * 2) / Float(symbolSides)
            let sparkGeom = SCNSphere(radius: 0.10)
            sparkGeom.materials = [glowMaterial(color, emission: color.withAlphaComponent(0.35))]
            let spark = SCNNode(geometry: sparkGeom)
            spark.position = SCNVector3(cos(angle) * 1.05, sin(angle) * 1.05, 0)
            node.addChildNode(spark)
        }

        attachBody(
            node,
            geometry: SCNSphere(radius: 0.9),
            category: PhysicsCategory.powerUp,
            name: "powerUp"
        )
    }

    // MARK: - Behavior

    /// Per-frame flight behavior. World scrolling is applied by GameScene;
    /// this adds the obstacle's own motion on top of it.
    func update(dt: TimeInterval, shipPosition: SCNVector3) {
        age += dt
        switch kind {
        case .enemyFighter:
            position.z -= approachSpeed * Float(dt)
            weavePhase += weaveFrequency * Float(dt)
            position.x = baseX + sin(weavePhase) * weaveAmplitude
            position.y = baseY + cos(weavePhase * 0.7) * weaveAmplitude * 0.35
            // Bank into the weave; the nose already points at the player (-Z).
            eulerAngles = SCNVector3(0, 0, -cos(weavePhase) * 0.45)
        case .asteroid:
            position.z -= approachSpeed * Float(dt)
        default:
            break
        }
    }

    /// Walks up the node hierarchy to find the owning ObstacleNode —
    /// gate frames and sensors report contacts on child nodes.
    static func owner(of node: SCNNode) -> ObstacleNode? {
        var current: SCNNode? = node
        while let n = current {
            if let obstacle = n as? ObstacleNode { return obstacle }
            current = n.parent
        }
        return nil
    }
}
