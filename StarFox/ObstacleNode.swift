//
//  ObstacleNode.swift
//  StarFox
//

import SceneKit

enum ObstacleKind {
    case cube, pyramid, ring, enemy, powerUpShield, powerUpFire
}

class ObstacleNode: SCNNode {
    var kind: ObstacleKind = .cube
    var health: Int = 1

    var isEnemy: Bool { kind == .enemy }
    var isPowerUp: Bool { kind == .powerUpShield || kind == .powerUpFire }

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

    static func create(kind: ObstacleKind, at position: SCNVector3) -> ObstacleNode {
        let node = ObstacleNode()
        node.kind = kind
        node.position = position
        node.health = kind == .enemy ? 2 : 1

        let dark = silhouetteMaterial()
        let collisionGeom: SCNGeometry

        switch kind {
        case .cube:
            let geom = SCNBox(width: 1.5, height: 1.5, length: 1.5, chamferRadius: 0)
            geom.materials = [dark]
            node.geometry = geom
            node.name = "obstacle"
            collisionGeom = SCNBox(width: 1.5, height: 1.5, length: 1.5, chamferRadius: 0)

        case .pyramid:
            let geom = SCNPyramid(width: 2.2, height: 2.8, length: 2.2)
            geom.materials = [dark]
            node.geometry = geom
            node.name = "obstacle"
            collisionGeom = SCNBox(width: 2.2, height: 2.8, length: 2.2, chamferRadius: 0)

        case .ring:
            let ringColor = UIColor(red: 0.55, green: 0.32, blue: 0.18, alpha: 1)
            let geom = SCNTorus(ringRadius: 1.8, pipeRadius: 0.28)
            geom.materials = [glowMaterial(ringColor, emission: ringColor.withAlphaComponent(0.4))]
            node.geometry = geom
            node.name = "obstacle"
            node.eulerAngles.x = Float.pi / 2
            collisionGeom = SCNBox(width: 4.2, height: 4.2, length: 0.7, chamferRadius: 0)

        case .enemy:
            let bodyGeom = SCNBox(width: 1.2, height: 0.5, length: 1.0, chamferRadius: 0)
            bodyGeom.materials = [dark]
            let bodyNode = SCNNode(geometry: bodyGeom)
            node.addChildNode(bodyNode)

            let wingGeom = SCNBox(width: 3.2, height: 0.1, length: 0.7, chamferRadius: 0)
            wingGeom.materials = [dark]
            let wingNode = SCNNode(geometry: wingGeom)
            node.addChildNode(wingNode)

            let noseGeom = SCNCone(topRadius: 0, bottomRadius: 0.2, height: 0.6)
            let noseColor = UIColor(red: 0.6, green: 0.25, blue: 0.15, alpha: 1)
            noseGeom.materials = [glowMaterial(noseColor, emission: noseColor.withAlphaComponent(0.5))]
            let noseNode = SCNNode(geometry: noseGeom)
            noseNode.eulerAngles.x = Float.pi / 2
            noseNode.position = SCNVector3(0, 0, -0.7)
            node.addChildNode(noseNode)

            let engineLight = SCNLight()
            engineLight.type = .omni
            engineLight.color = UIColor(red: 0.7, green: 0.35, blue: 0.15, alpha: 1)
            engineLight.attenuationStartDistance = 0
            engineLight.attenuationEndDistance = 3
            engineLight.intensity = 200
            let engineGlowNode = SCNNode()
            engineGlowNode.light = engineLight
            engineGlowNode.position = SCNVector3(0, 0, 0.6)
            node.addChildNode(engineGlowNode)

            node.name = "enemy"
            collisionGeom = SCNBox(width: 3.0, height: 0.6, length: 1.0, chamferRadius: 0)

        case .powerUpShield:
            let glowColor = UIColor(red: 0.3, green: 0.6, blue: 0.5, alpha: 1)
            let geom = SCNSphere(radius: 0.65)
            geom.materials = [glowMaterial(glowColor, emission: glowColor.withAlphaComponent(0.4))]
            node.geometry = geom
            node.name = "powerUp"

            let pulse = SCNAction.sequence([
                SCNAction.scale(to: 1.35, duration: 0.42),
                SCNAction.scale(to: 0.82, duration: 0.42)
            ])
            node.runAction(SCNAction.repeatForever(pulse))

            for i in 0..<3 {
                let angle = Float(i) * Float.pi * 2 / 3
                let dot = SCNNode()
                let dg = SCNSphere(radius: 0.10)
                dg.materials = [glowMaterial(glowColor, emission: glowColor.withAlphaComponent(0.3))]
                dot.geometry = dg
                dot.position = SCNVector3(cos(angle) * 1.0, sin(angle) * 1.0, 0)
                node.addChildNode(dot)
            }
            node.runAction(SCNAction.repeatForever(
                SCNAction.rotate(by: .pi * 2, around: SCNVector3(0.3, 1, 0.2), duration: 2.0)
            ))

            collisionGeom = SCNSphere(radius: 0.65)

        case .powerUpFire:
            let fireColor = UIColor(red: 0.7, green: 0.35, blue: 0.15, alpha: 1)
            let geom = SCNBox(width: 0.90, height: 0.90, length: 0.90, chamferRadius: 0.12)
            geom.materials = [glowMaterial(fireColor, emission: fireColor.withAlphaComponent(0.45))]
            node.geometry = geom
            node.name = "powerUp"
            node.runAction(SCNAction.repeatForever(
                SCNAction.rotate(by: .pi * 2, around: SCNVector3(1, 1, 0.5), duration: 1.2)
            ))

            for i in 0..<4 {
                let angle = Float(i) * Float.pi / 2
                let spark = SCNNode()
                let sg = SCNBox(width: 0.12, height: 0.12, length: 0.12, chamferRadius: 0.02)
                sg.materials = [glowMaterial(fireColor, emission: fireColor.withAlphaComponent(0.3))]
                spark.geometry = sg
                spark.position = SCNVector3(cos(angle) * 1.1, sin(angle) * 1.1, 0)
                node.addChildNode(spark)
            }

            collisionGeom = SCNBox(width: 0.9, height: 0.9, length: 0.9, chamferRadius: 0)
        }

        let category: Int = node.isPowerUp ? PhysicsCategory.powerUp : PhysicsCategory.obstacle
        let shape = SCNPhysicsShape(geometry: collisionGeom, options: nil)
        let body = SCNPhysicsBody(type: .kinematic, shape: shape)
        body.categoryBitMask = category
        body.contactTestBitMask = PhysicsCategory.ship | PhysicsCategory.projectile
        body.collisionBitMask = PhysicsCategory.none
        node.physicsBody = body

        return node
    }
}
