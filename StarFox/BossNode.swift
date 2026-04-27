//
//  BossNode.swift
//  StarFox
//

import SceneKit

class BossNode: SCNNode {
    var health: Int = 20
    private var movementAngle: Float = 0

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
        boss.name = "boss"

        let bodyGeom = SCNSphere(radius: 3.0)
        bodyGeom.segmentCount = 6
        bodyGeom.materials = [silhouetteMaterial()]
        boss.geometry = bodyGeom

        let accentColor = UIColor(red: 0.6, green: 0.25, blue: 0.15, alpha: 1)
        let ringMat = SCNMaterial()
        ringMat.lightingModel = .constant
        ringMat.diffuse.contents = accentColor
        ringMat.emission.contents = accentColor.withAlphaComponent(0.4)

        let ringGeom = SCNTorus(ringRadius: 4.8, pipeRadius: 0.38)
        ringGeom.materials = [ringMat]
        let ringNode = SCNNode(geometry: ringGeom)
        ringNode.name = "bossRing"
        ringNode.eulerAngles = SCNVector3(Float.pi / 5, 0, Float.pi / 8)
        boss.addChildNode(ringNode)
        ringNode.runAction(SCNAction.repeatForever(
            SCNAction.rotate(by: .pi * 2, around: SCNVector3(0.2, 1, 0.4), duration: 2.2)
        ))

        let spikeAxes: [SCNVector3] = [
            SCNVector3(1, 0, 0), SCNVector3(-1, 0, 0),
            SCNVector3(0, 1, 0), SCNVector3(0, -1, 0),
            SCNVector3(0.7, 0.7, 0), SCNVector3(-0.7, 0.7, 0)
        ]
        let spikeMat = SCNMaterial()
        spikeMat.lightingModel = .constant
        spikeMat.diffuse.contents = accentColor
        spikeMat.emission.contents = accentColor.withAlphaComponent(0.5)

        for axis in spikeAxes {
            let spike = SCNNode()
            let spikeGeom = SCNCone(topRadius: 0, bottomRadius: 0.48, height: 2.2)
            spikeGeom.materials = [spikeMat]
            spike.geometry = spikeGeom

            let len = sqrt(axis.x * axis.x + axis.y * axis.y + axis.z * axis.z)
            let norm = SCNVector3(axis.x / len * 3.2, axis.y / len * 3.2, axis.z / len * 3.2)
            spike.position = norm
            spike.look(
                at: SCNVector3(norm.x * 2, norm.y * 2, norm.z * 2),
                up: SCNVector3(0, 1, 0),
                localFront: SCNVector3(0, 1, 0)
            )
            boss.addChildNode(spike)
        }

        let coreLight = SCNLight()
        coreLight.type = .omni
        coreLight.color = accentColor
        coreLight.attenuationStartDistance = 0
        coreLight.attenuationEndDistance = 14
        coreLight.intensity = 600
        let coreNode = SCNNode()
        coreNode.light = coreLight
        boss.addChildNode(coreNode)

        let pulseUp = SCNAction.customAction(duration: 0.5) { node, t in
            node.light?.intensity = 400 + CGFloat(t / 0.5) * 500
        }
        let pulseDown = SCNAction.customAction(duration: 0.5) { node, t in
            node.light?.intensity = 900 - CGFloat(t / 0.5) * 500
        }
        coreNode.runAction(SCNAction.repeatForever(SCNAction.sequence([pulseUp, pulseDown])))

        let shape = SCNPhysicsShape(geometry: SCNSphere(radius: 3.5), options: nil)
        let body = SCNPhysicsBody(type: .kinematic, shape: shape)
        body.categoryBitMask = PhysicsCategory.obstacle
        body.contactTestBitMask = PhysicsCategory.ship | PhysicsCategory.projectile
        body.collisionBitMask = PhysicsCategory.none
        boss.physicsBody = body

        return boss
    }

    func update(dt: TimeInterval) {
        movementAngle += Float(dt) * 0.85
        let radius: Float = 5.5
        position.x = cos(movementAngle) * radius
        position.y = sin(movementAngle * 0.55) * 2.4
        eulerAngles.y += Float(dt) * 0.65
        eulerAngles.z += Float(dt) * 0.28
    }

    func takeDamage() -> Bool {
        health -= 1

        let flashColor = UIColor(red: 0.9, green: 0.5, blue: 0.2, alpha: 1)
        let baseColor = UIColor(white: 0.05, alpha: 1)

        geometry?.firstMaterial?.diffuse.contents = flashColor
        geometry?.firstMaterial?.emission.contents = flashColor

        removeAction(forKey: "bossFlash")
        let restore = SCNAction.sequence([
            SCNAction.wait(duration: 0.13),
            SCNAction.run { node in
                node.geometry?.firstMaterial?.diffuse.contents = baseColor
                node.geometry?.firstMaterial?.emission.contents = UIColor(white: 0.02, alpha: 1)
            }
        ])
        runAction(restore, forKey: "bossFlash")

        return health <= 0
    }
}
