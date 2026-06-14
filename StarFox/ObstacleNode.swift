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

    // Shared materials — every silhouette/glow in the corridor reuses these
    // instead of allocating per spawn.
    private static let sharedSilhouette = silhouetteMaterial()
    private static let sharedOrangeGlow = glowMaterial(orangeAccent, emission: orangeAccent.withAlphaComponent(0.5))
    private static let sharedMintGlow = glowMaterial(mintAccent, emission: mintAccent.withAlphaComponent(0.6))
    private static let sharedGoldGlow = glowMaterial(goldRing, emission: goldRing.withAlphaComponent(0.5))

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
        case .powerShield:   buildPowerUp(node, material: sharedMintGlow, symbolSides: 3)
        case .powerTwin:     buildPowerUp(node, material: sharedOrangeGlow, symbolSides: 4)
        case .powerBomb:     buildPowerUp(node, material: sharedGoldGlow, symbolSides: 5)
        }
        return node
    }

    /// Quick scale pulse for non-lethal laser hits — readable feedback
    /// that works with shared materials (no per-node material flash).
    func hitPop() {
        removeAction(forKey: "hitPop")
        let pop = SCNAction.sequence([
            SCNAction.scale(to: 1.18, duration: 0.06),
            SCNAction.scale(to: 1.0, duration: 0.10)
        ])
        runAction(pop, forKey: "hitPop")
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
        geom.materials = [sharedSilhouette]
        node.geometry = geom

        // Orange ember veins.
        for _ in 0..<3 {
            let emberGeom = SCNBox(width: radius * 0.5, height: 0.08, length: 0.08, chamferRadius: 0)
            emberGeom.materials = [sharedOrangeGlow]
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
        let width: CGFloat = CGFloat.random(in: 1.5...2.1)
        let height = CGFloat.random(in: 7...12)
        let geom = SCNBox(width: width, height: height, length: width, chamferRadius: 0.08)
        geom.materials = [sharedSilhouette]
        node.geometry = geom

        // A stepped cap gives the tower a built silhouette instead of a
        // plain bar against the sky.
        let capGeom = SCNBox(width: width * 1.25, height: 0.5, length: width * 1.25, chamferRadius: 0.04)
        capGeom.materials = [sharedSilhouette]
        let cap = SCNNode(geometry: capGeom)
        cap.position = SCNVector3(0, Float(height) / 2 + 0.25, 0)
        node.addChildNode(cap)

        // Rows of lit "windows" climbing two faces — reads as a structure
        // and the bloom makes them glow.
        let rows = Int(height / 1.4)
        for r in 0..<rows {
            let y = Float(-height / 2) + 1.0 + Float(r) * 1.4
            for face: Float in [1, -1] {
                let winGeom = SCNBox(width: width * 0.5, height: 0.18, length: 0.06, chamferRadius: 0)
                winGeom.materials = [r % 3 == 0 ? sharedMintGlow : sharedOrangeGlow]
                let win = SCNNode(geometry: winGeom)
                win.position = SCNVector3(0, y, face * Float(width / 2 + 0.01))
                win.opacity = CGFloat.random(in: 0.45...1.0)
                node.addChildNode(win)
            }
        }

        // Beacon light on top.
        let beaconGeom = SCNSphere(radius: 0.18)
        beaconGeom.materials = [sharedOrangeGlow]
        let beacon = SCNNode(geometry: beaconGeom)
        beacon.position = SCNVector3(0, Float(height) / 2 + 0.6, 0)
        node.addChildNode(beacon)
        beacon.runAction(SCNAction.repeatForever(SCNAction.sequence([
            SCNAction.fadeOpacity(to: 0.25, duration: 0.5),
            SCNAction.fadeOpacity(to: 1.0, duration: 0.5)
        ])))

        attachBody(
            node,
            geometry: SCNBox(width: width, height: height, length: width, chamferRadius: 0),
            category: PhysicsCategory.obstacle,
            name: "obstacle"
        )
    }

    private static func buildGate(_ node: ObstacleNode) {
        node.health = 999
        node.name = "gateRoot"
        let frameMat = sharedSilhouette

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
            lampGeom.materials = [sharedMintGlow]
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

    /// Prototype enemy fighter, cloned per spawn. clone() shares all the
    /// geometry/materials, so a 5-ship formation costs one node tree copy
    /// instead of rebuilding four geometries per fighter. The exhaust is an
    /// emissive sphere, not a light: silhouettes use constant lighting, so
    /// dynamic lights cost GPU time without changing the picture.
    private static let enemyFighterPrototype: SCNNode = {
        let proto = SCNNode()

        // Angular dart body.
        let bodyGeom = SCNBox(width: 0.8, height: 0.4, length: 1.5, chamferRadius: 0.02)
        bodyGeom.materials = [sharedSilhouette]
        let body = SCNNode(geometry: bodyGeom)
        proto.addChildNode(body)

        // Swept wings.
        let wingGeom = SCNBox(width: 3.4, height: 0.09, length: 0.9, chamferRadius: 0)
        wingGeom.materials = [sharedSilhouette]
        let wings = SCNNode(geometry: wingGeom)
        wings.position = SCNVector3(0, 0, 0.25)
        proto.addChildNode(wings)

        // Orange nose spike facing the player (-Z, they fly toward us).
        let noseGeom = SCNCone(topRadius: 0, bottomRadius: 0.22, height: 0.8)
        noseGeom.materials = [sharedOrangeGlow]
        let nose = SCNNode(geometry: noseGeom)
        nose.eulerAngles.x = -.pi / 2
        nose.position = SCNVector3(0, 0, -0.95)
        proto.addChildNode(nose)

        // Emissive exhaust at the back.
        let exhaustGeom = SCNSphere(radius: 0.16)
        exhaustGeom.materials = [sharedOrangeGlow]
        let exhaust = SCNNode(geometry: exhaustGeom)
        exhaust.position = SCNVector3(0, 0, 0.9)
        proto.addChildNode(exhaust)

        return proto
    }()

    private static func buildEnemyFighter(_ node: ObstacleNode) {
        node.health = 2
        let copy = enemyFighterPrototype.clone()
        for child in copy.childNodes {
            node.addChildNode(child)
        }

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
        geom.materials = [sharedGoldGlow]
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

    private static func buildPowerUp(_ node: ObstacleNode, material: SCNMaterial, symbolSides: Int) {
        node.health = 999
        let geom = SCNBox(width: 0.95, height: 0.95, length: 0.95, chamferRadius: 0.14)
        geom.materials = [material]
        node.geometry = geom
        node.runAction(SCNAction.repeatForever(
            SCNAction.rotate(by: .pi * 2, around: SCNVector3(0.4, 1, 0.3), duration: 1.6)
        ))

        for i in 0..<symbolSides {
            let angle = Float(i) * (.pi * 2) / Float(symbolSides)
            let sparkGeom = SCNSphere(radius: 0.10)
            sparkGeom.materials = [material]
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
