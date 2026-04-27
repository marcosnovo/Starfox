//
//  GameScene.swift
//  StarFox
//

import SceneKit
import UIKit

class GameScene: SCNScene {

    // MARK: - Public

    let state = GameState()
    var cameraNode: SCNNode!
    var onPhaseChanged: ((GamePhase) -> Void)?

    // MARK: - Systems

    private var skySystem: SkySystem!
    private var environment: EnvironmentSystem!
    private var particleFX: ParticleFXSystem!

    // MARK: - Input (written on main thread, consumed on render thread)

    private let inputLock = NSLock()
    private var pendingDragDelta: CGPoint = .zero
    private var pendingIsDragging: Bool = false
    private var pendingFireRequest: Bool = false
    private var pendingStartRequest: Bool = false
    private var pendingRestartRequest: Bool = false
    private var pendingResumeRequest: Bool = false
    private var pendingExitRequest: Bool = false

    private var dragDelta: CGPoint = .zero
    private var isDragging: Bool = false

    // MARK: - Nodes

    private var shipNode: ShipNode!
    private var obstacleContainer: SCNNode!
    private var projectileContainer: SCNNode!
    private var bossNode: BossNode?

    // MARK: - Game loop state

    private var lastUpdateTime: TimeInterval = 0
    private var spawnTimer: TimeInterval     = 0
    private var fireTimer: TimeInterval      = 0
    private var bossFireTimer: TimeInterval  = 0
    private var cameraBaseFOV: CGFloat = 54
    private var cameraCurrentFOV: CGFloat = 54
    private var cameraShakeImpulse: CGFloat = 0
    private var cameraShakePhase: TimeInterval = 0
    private var enginePowerCurrent: CGFloat = 0.68

    private var activeObstacles: [ObstacleNode] = []
    private var activeProjectiles: [SCNNode]    = []
    private var activeBossBullets: [SCNNode]    = []

    private var lastPublishedPhase: GamePhase?
    private var fireCooldown: TimeInterval { state.fireBoostTimer > 0 ? 0.10 : 0.25 }
    private let cinematicMinimalMode = true
    private let keepCenterCorridorClear = true

    // MARK: - Camera constants

    private let cameraOffsetY: Float = 2.0
    private let cameraOffsetZ: Float = -12.0
    private let cameraLookOffsetY: Float = 2.2
    private let cameraLookOffsetZ: Float = 8.0

    // MARK: - Setup

    func setup() {
        physicsWorld.gravity = SCNVector3(0, 0, 0)
        physicsWorld.contactDelegate = self

        skySystem = SkySystem(rootNode: rootNode)
        environment = EnvironmentSystem(rootNode: rootNode, minimalMode: cinematicMinimalMode)
        particleFX = ParticleFXSystem(rootNode: rootNode, minimalMode: cinematicMinimalMode)

        skySystem.setupBackground(scene: self)
        skySystem.setupLighting(scene: self)
        setupCamera()
        setupShip()
        skySystem.setupSunNodes()
        skySystem.update(dt: 0, shipPosition: shipNode.position, weatherPreset: particleFX.blendedWeatherPreset())

        if !cinematicMinimalMode {
            particleFX.setupWeather()
        }
        particleFX.setupAtmosphere()
        if !cinematicMinimalMode {
            environment.setupAmbientLife()
        }
        environment.setupParallaxLandscape(shipPosition: shipNode.position)
        fireTimer = fireCooldown
    }

    // MARK: - Public Input API

    func enqueueDragDelta(_ delta: CGPoint) {
        inputLock.lock()
        pendingDragDelta.x += delta.x
        pendingDragDelta.y += delta.y
        inputLock.unlock()
    }

    func setDragging(_ dragging: Bool) {
        inputLock.lock()
        pendingIsDragging = dragging
        if !dragging { pendingDragDelta = .zero }
        inputLock.unlock()
    }

    func requestFire() {
        inputLock.lock()
        pendingFireRequest = true
        inputLock.unlock()
    }

    func requestStartNewGame() {
        inputLock.lock()
        pendingStartRequest = true
        inputLock.unlock()
    }

    func requestRestartGame() {
        inputLock.lock()
        pendingRestartRequest = true
        inputLock.unlock()
    }

    func requestResumeGame() {
        inputLock.lock()
        pendingResumeRequest = true
        inputLock.unlock()
    }

    func requestExitToMenu() {
        inputLock.lock()
        pendingExitRequest = true
        inputLock.unlock()
    }

    // MARK: - Camera

    private func setupCamera() {
        cameraNode = SCNNode()
        let cam = SCNCamera()
        cam.fieldOfView = cameraBaseFOV
        cam.zFar = 500
        cam.wantsHDR = false
        cam.wantsExposureAdaptation = false
        cameraNode.camera = cam
        cameraCurrentFOV = cameraBaseFOV
        cameraNode.position = SCNVector3(0, cameraOffsetY, cameraOffsetZ)
        cameraNode.look(at: SCNVector3(0, cameraLookOffsetY, cameraLookOffsetZ))

        let cameraFill = SCNNode()
        let cameraFillLight = SCNLight()
        cameraFillLight.type = .omni
        cameraFillLight.intensity = 60
        cameraFillLight.attenuationStartDistance = 0
        cameraFillLight.attenuationEndDistance = 14
        cameraFillLight.color = UIColor(hex: "#D97854")
        cameraFill.light = cameraFillLight
        cameraNode.addChildNode(cameraFill)

        rootNode.addChildNode(cameraNode)
    }

    private func updateCamera(dt: TimeInterval) {
        let targetX = shipNode.position.x * 0.15
        let targetY = shipNode.position.y * 0.08 + cameraOffsetY
        let targetZ = shipNode.position.z + cameraOffsetZ

        let lookX = shipNode.position.x * 0.05
        let lookY = shipNode.position.y * 0.02 + cameraLookOffsetY
        let lookZ = shipNode.position.z + cameraLookOffsetZ

        let posSmooth: Float = 0.08
        cameraNode.position.x += (targetX - cameraNode.position.x) * posSmooth
        cameraNode.position.y += (targetY - cameraNode.position.y) * posSmooth
        cameraNode.position.z += (targetZ - cameraNode.position.z) * posSmooth

        let rollInfluence = CGFloat(min(1.0, abs(shipNode.eulerAngles.z)))
        let boostInfluence: CGFloat = state.fireBoostTimer > 0 ? 1 : 0
        let targetFOV = cameraBaseFOV + (rollInfluence * 2.5) + (boostInfluence * 1.8)
        cameraCurrentFOV += (targetFOV - cameraCurrentFOV) * 0.07
        cameraNode.camera?.fieldOfView = cameraCurrentFOV

        cameraShakeImpulse = max(0, cameraShakeImpulse - CGFloat(dt) * 2.8)
        let totalShake = min(0.05, cameraShakeImpulse)
        if totalShake > 0.001 {
            cameraShakePhase += dt * 9.5
            let sx = Float(sin(cameraShakePhase * 2.2) * totalShake * 0.65)
            let sy = Float(cos(cameraShakePhase * 1.7) * totalShake * 0.45)
            cameraNode.position.x += sx
            cameraNode.position.y += sy
            cameraNode.look(at: SCNVector3(lookX + sx * 0.15, lookY + sy * 0.12, lookZ))
        } else {
            cameraNode.look(at: SCNVector3(lookX, lookY, lookZ))
        }
    }

    // MARK: - Ship

    private func setupShip() {
        shipNode = ShipNode.create()
        shipNode.position = SCNVector3(0, 0, 0)
        rootNode.addChildNode(shipNode)

        obstacleContainer = SCNNode()
        obstacleContainer.name = "obstacles"
        rootNode.addChildNode(obstacleContainer)

        projectileContainer = SCNNode()
        projectileContainer.name = "projectiles"
        rootNode.addChildNode(projectileContainer)
    }

    private func advanceShip(dt: TimeInterval) {
        shipNode.position.z += 15.0 * Float(dt)
    }

    private func applyTouchInput() {
        guard isDragging else {
            shipNode.applyTilt(0, dy: 0)
            return
        }
        let dx = Float(dragDelta.x) * 0.022
        let dy = Float(dragDelta.y) * 0.022
        dragDelta = .zero

        shipNode.position.x = (shipNode.position.x + dx).clamped(to: -8.5...8.5)
        shipNode.position.y = (shipNode.position.y - dy).clamped(to: -4.0...4.5)
        shipNode.applyTilt(dx * 5.5, dy: dy * 5.5)
    }

    private func updateEnginePower(dt: TimeInterval, previousPosition: SCNVector3, extraBoost: CGFloat) {
        let dx = shipNode.position.x - previousPosition.x
        let dy = shipNode.position.y - previousPosition.y
        let dz = shipNode.position.z - previousPosition.z
        let distance = sqrt(dx * dx + dy * dy + dz * dz)
        let speed = CGFloat(distance / max(Float(dt), 0.001))
        let normalizedSpeed = min(1.0, max(0.0, (speed - 8.0) / 18.0))
        let fireBoost: CGFloat = max(0, (cameraShakeImpulse - 0.010) * 9.0)
        let targetPower = min(1.0, 0.56 + (normalizedSpeed * 0.34) + fireBoost + extraBoost)
        enginePowerCurrent += (targetPower - enginePowerCurrent) * 0.10
        shipNode.setEnginePower(enginePowerCurrent)
    }

    // MARK: - Input Processing

    private func consumePendingInput() {
        inputLock.lock()
        dragDelta = pendingDragDelta
        pendingDragDelta = .zero
        isDragging = pendingIsDragging

        let shouldStart = pendingStartRequest
        let shouldRestart = pendingRestartRequest
        let shouldResume = pendingResumeRequest
        let shouldExit = pendingExitRequest
        let shouldFire = pendingFireRequest

        pendingStartRequest = false
        pendingRestartRequest = false
        pendingResumeRequest = false
        pendingExitRequest = false
        pendingFireRequest = false
        inputLock.unlock()

        if shouldExit {
            resetScene()
            state.phase = .menu
            return
        }

        if shouldRestart {
            resetScene()
            state.startNewGame()
        } else if shouldStart, state.phase == .menu {
            state.startNewGame()
        } else if shouldResume, state.phase == .paused {
            state.phase = .playing
        }

        if shouldFire {
            requestFireFromGameLoop()
        }
    }

    // MARK: - Reset

    func resetScene() {
        for o in activeObstacles   { o.removeFromParentNode() }
        activeObstacles.removeAll()
        for p in activeProjectiles { p.removeFromParentNode() }
        activeProjectiles.removeAll()
        for b in activeBossBullets { b.removeFromParentNode() }
        activeBossBullets.removeAll()
        bossNode?.removeFromParentNode()
        bossNode = nil

        shipNode.position = SCNVector3(0, 0, 0)
        cameraNode.position = SCNVector3(0, cameraOffsetY, cameraOffsetZ)
        cameraNode.look(at: SCNVector3(0, cameraLookOffsetY, cameraLookOffsetZ))
        cameraCurrentFOV = cameraBaseFOV
        cameraNode.camera?.fieldOfView = cameraCurrentFOV
        cameraShakeImpulse = 0
        cameraShakePhase = 0

        lastUpdateTime = 0
        spawnTimer = 0
        fireTimer = fireCooldown
        bossFireTimer = 0

        particleFX.reset()
        environment.resetAmbientLife()
        environment.resetParallaxLandscape(shipPosition: shipNode.position)
        skySystem.reset()
    }

    private func publishPhaseIfNeeded() {
        guard state.phase != lastPublishedPhase else { return }
        lastPublishedPhase = state.phase
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.onPhaseChanged?(self.state.phase)
        }
    }

    // MARK: - Obstacles

    private func spawnObstacles(dt: TimeInterval) {
        spawnTimer += dt
        let spawnInterval = cinematicMinimalMode ? (state.spawnInterval * 1.35) : state.spawnInterval
        guard spawnTimer >= spawnInterval else { return }
        spawnTimer = 0

        let spawnZ = shipNode.position.z + 85
        let x: Float
        if keepCenterCorridorClear {
            let lanes: [Float] = [-7.0, -5.6, -4.2, -3.0, 3.0, 4.2, 5.6, 7.0]
            x = lanes.randomElement() ?? Float.random(in: -7...7)
        } else {
            x = Float.random(in: -7...7)
        }
        let y = Float.random(in: -2.4...2.8)

        let roll = Double.random(in: 0...1)
        let kind: ObstacleKind
        if cinematicMinimalMode {
            switch roll {
            case ..<0.04:  kind = .powerUpShield
            case ..<0.08:  kind = .powerUpFire
            case ..<0.22:  kind = .enemy
            case ..<0.38:  kind = .ring
            case ..<0.55:  kind = .pyramid
            default:       kind = .cube
            }
        } else {
            switch roll {
            case ..<0.07:  kind = .powerUpShield
            case ..<0.12:  kind = .powerUpFire
            case ..<0.30:  kind = .enemy
            case ..<0.48:  kind = .ring
            case ..<0.66:  kind = .pyramid
            default:       kind = .cube
            }
        }

        let obstacle = ObstacleNode.create(kind: kind, at: SCNVector3(x, y, spawnZ))
        if kind != .ring && !obstacle.isPowerUp {
            obstacle.runAction(SCNAction.repeatForever(
                SCNAction.rotate(by: .pi, around: SCNVector3(0.3, 1, 0.2), duration: 2.2)
            ))
        }
        obstacleContainer.addChildNode(obstacle)
        activeObstacles.append(obstacle)
    }

    private func moveObstacles(dt: TimeInterval) {
        let speed = state.obstacleSpeed * Float(dt)
        for obs in activeObstacles { obs.position.z -= speed }
    }

    // MARK: - Firing

    private func requestFireFromGameLoop() {
        guard state.phase == .playing || state.phase == .bossEncounter else { return }
        guard fireTimer >= fireCooldown else { return }
        fireTimer = 0
        fireProjectile()
        cameraShakeImpulse = min(0.04, cameraShakeImpulse + 0.018)
        enginePowerCurrent = min(1.0, enginePowerCurrent + 0.09)
    }

    private func fireProjectile() {
        let node = SCNNode()
        let geom = SCNCylinder(radius: 0.06, height: 2.8)
        let m = SCNMaterial()
        m.lightingModel = .constant
        m.diffuse.contents = UIColor(hex: "#E8905A")
        m.emission.contents = UIColor(hex: "#C07040")
        geom.materials = [m]
        node.geometry = geom
        node.eulerAngles.x = Float.pi / 2
        node.position = SCNVector3(
            shipNode.position.x,
            shipNode.position.y,
            shipNode.position.z + 2.5
        )
        node.name = "projectile"

        let bolt = SCNLight()
        bolt.type = .omni
        bolt.color = UIColor(hex: "#E8905A")
        bolt.attenuationStartDistance = 0
        bolt.attenuationEndDistance = 3
        bolt.intensity = 250
        let boltLightNode = SCNNode()
        boltLightNode.light = bolt
        node.addChildNode(boltLightNode)

        let shape = SCNPhysicsShape(geometry: SCNCylinder(radius: 0.15, height: 3.0), options: nil)
        let body = SCNPhysicsBody(type: .kinematic, shape: shape)
        body.categoryBitMask = PhysicsCategory.projectile
        body.contactTestBitMask = PhysicsCategory.obstacle
        body.collisionBitMask = PhysicsCategory.none
        node.physicsBody = body

        projectileContainer.addChildNode(node)
        activeProjectiles.append(node)
    }

    private func moveProjectiles(dt: TimeInterval) {
        let speed = 65.0 * Float(dt)
        for p in activeProjectiles { p.position.z += speed }
    }

    // MARK: - Boss

    private func startBossEncounter() {
        state.phase = .bossEncounter
        for o in activeObstacles { o.removeFromParentNode() }
        activeObstacles.removeAll()

        let boss = BossNode.create(health: state.bossHealth)
        boss.position = SCNVector3(0, 0, shipNode.position.z + 45)
        rootNode.addChildNode(boss)
        bossNode = boss
        bossFireTimer = 0
    }

    private func spawnBossBullet(from origin: SCNVector3) {
        let node = SCNNode()
        let geom = SCNSphere(radius: 0.45)
        let m = SCNMaterial()
        m.lightingModel = .constant
        m.diffuse.contents = UIColor(hex: "#D07040")
        m.emission.contents = UIColor(hex: "#A05030")
        geom.materials = [m]
        node.geometry = geom
        node.position = origin
        node.name = "bossBullet"

        let bl = SCNLight()
        bl.type = .omni
        bl.color = UIColor(hex: "#D07040")
        bl.attenuationStartDistance = 0
        bl.attenuationEndDistance = 4
        bl.intensity = 300
        let blNode = SCNNode()
        blNode.light = bl
        node.addChildNode(blNode)

        let shape = SCNPhysicsShape(geometry: SCNSphere(radius: 0.45), options: nil)
        let body = SCNPhysicsBody(type: .kinematic, shape: shape)
        body.categoryBitMask = PhysicsCategory.enemyBullet
        body.contactTestBitMask = PhysicsCategory.ship
        body.collisionBitMask = PhysicsCategory.none
        node.physicsBody = body

        rootNode.addChildNode(node)
        activeBossBullets.append(node)
    }

    private func moveBossBullets(dt: TimeInterval) {
        let speed = 14.0 * Float(dt)
        for bullet in activeBossBullets {
            let dx = shipNode.position.x - bullet.position.x
            let dy = shipNode.position.y - bullet.position.y
            let dz = shipNode.position.z - bullet.position.z
            let len = sqrt(dx*dx + dy*dy + dz*dz)
            guard len > 0.001 else { continue }
            bullet.position.x += (dx / len) * speed
            bullet.position.y += (dy / len) * speed
            bullet.position.z += (dz / len) * speed
        }
    }

    // MARK: - Cleanup

    private func cleanupAll() {
        let shipZ = shipNode.position.z
        let farBehind = shipZ - 22

        let deadObs = activeObstacles.filter { $0.position.z < farBehind || $0.parent == nil }
        for o in deadObs {
            if !o.isPowerUp && o.parent != nil {
                state.score += 10
            }
            o.removeFromParentNode()
        }
        activeObstacles.removeAll { $0.position.z < farBehind || $0.parent == nil }

        let deadProj = activeProjectiles.filter { $0.position.z > shipZ + 110 || $0.parent == nil }
        for p in deadProj { p.removeFromParentNode() }
        activeProjectiles.removeAll { $0.position.z > shipZ + 110 || $0.parent == nil }

        let deadBullets = activeBossBullets.filter { abs($0.position.z - shipZ) > 70 || $0.parent == nil }
        for b in deadBullets { b.removeFromParentNode() }
        activeBossBullets.removeAll { abs($0.position.z - shipZ) > 70 || $0.parent == nil }
    }

    // MARK: - Collision Handlers

    private func handleProjectileHitBoss() {
        guard let boss = bossNode else { return }
        if boss.takeDamage() { bossDefeated() }
    }

    private func handleProjectileHitObstacle(_ obs: ObstacleNode, projectile: SCNNode) {
        obs.health -= 1
        guard obs.health <= 0 else { return }

        particleFX.explode(at: obs.position)
        obs.removeFromParentNode()
        activeObstacles.removeAll { $0 === obs }
        state.score += obs.isEnemy ? 100 : 50

        projectile.removeFromParentNode()
        activeProjectiles.removeAll { $0 === projectile }
    }

    private func handleShipHitObstacle(_ obs: ObstacleNode) {
        obs.removeFromParentNode()
        activeObstacles.removeAll { $0 === obs }
        if obs.kind == .ring {
            state.rings += 1
            state.multiplier = min(9.9, state.multiplier + 0.1)
            state.score += Int(Double(50) * state.multiplier)
        } else {
            applyDamage()
        }
    }

    private func handleShipHitPowerUp(_ pu: ObstacleNode) {
        pu.removeFromParentNode()
        activeObstacles.removeAll { $0 === pu }

        if pu.kind == .powerUpShield {
            state.shield = min(state.shield + 1, state.maxShield)
        } else if pu.kind == .powerUpFire {
            state.fireBoostTimer = 5.0
        }
    }

    private func handleShipHitBossBullet(_ bullet: SCNNode) {
        bullet.removeFromParentNode()
        activeBossBullets.removeAll { $0 === bullet }
        applyDamage()
    }

    private func applyDamage() {
        cameraShakeImpulse = min(0.05, cameraShakeImpulse + 0.04)
        state.shield -= 1
        if state.shield <= 0 {
            state.lives -= 1
            if state.lives <= 0 {
                state.phase = .gameOver
                bossNode?.removeFromParentNode()
                bossNode = nil
            } else {
                state.shield = state.maxShield
            }
        }
    }

    private func bossDefeated() {
        particleFX.explode(at: bossNode?.position ?? SCNVector3Zero)
        bossNode?.removeFromParentNode()
        bossNode = nil
        state.nextLevel()
        state.phase = .playing
    }
}

// MARK: - SCNSceneRendererDelegate

extension GameScene: SCNSceneRendererDelegate {

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        let dt: TimeInterval
        if lastUpdateTime == 0 {
            dt = 0
        } else {
            dt = min(time - lastUpdateTime, 0.05)
        }
        lastUpdateTime = time

        consumePendingInput()
        particleFX.updateWeather(dt: dt, shipPosition: shipNode.position)
        particleFX.updateAtmosphere(shipPosition: shipNode.position)
        skySystem.update(dt: dt, shipPosition: shipNode.position, weatherPreset: particleFX.blendedWeatherPreset())
        environment.updateAmbientLife(dt: dt, shipPosition: shipNode.position)

        switch state.phase {
        case .menu, .gameOver, .paused:
            updateCamera(dt: dt)
        case .playing:
            updatePlaying(dt: dt)
        case .bossEncounter:
            updateBossEncounter(dt: dt)
        }
        environment.updateParallaxLandscape(dt: dt, shipPosition: shipNode.position)

        publishPhaseIfNeeded()
    }

    private func updatePlaying(dt: TimeInterval) {
        let previousPosition = shipNode.position
        advanceShip(dt: dt)
        applyTouchInput()
        updateEnginePower(dt: dt, previousPosition: previousPosition, extraBoost: 0)
        updateCamera(dt: dt)

        fireTimer = min(fireCooldown, fireTimer + dt)
        state.levelTimer += dt
        spawnObstacles(dt: dt)
        moveObstacles(dt: dt)
        moveProjectiles(dt: dt)
        cleanupAll()

        if state.fireBoostTimer > 0 { state.fireBoostTimer -= dt }
        if state.levelTimer >= state.levelDuration { startBossEncounter() }
    }

    private func updateBossEncounter(dt: TimeInterval) {
        let previousPosition = shipNode.position
        advanceShip(dt: dt)
        applyTouchInput()
        updateEnginePower(dt: dt, previousPosition: previousPosition, extraBoost: 0.08)
        updateCamera(dt: dt)

        fireTimer = min(fireCooldown, fireTimer + dt)

        if let boss = bossNode {
            boss.position.z = shipNode.position.z + 30
            boss.update(dt: dt)

            bossFireTimer += dt
            let fireInterval = max(0.8, 3.0 - Double(state.level - 1) * 0.25)
            if bossFireTimer >= fireInterval {
                bossFireTimer = 0
                spawnBossBullet(from: boss.position)
            }
        }

        moveProjectiles(dt: dt)
        moveBossBullets(dt: dt)
        cleanupAll()

        if state.fireBoostTimer > 0 { state.fireBoostTimer -= dt }
    }
}

// MARK: - SCNPhysicsContactDelegate

extension GameScene: SCNPhysicsContactDelegate {

    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        let a = contact.nodeA
        let b = contact.nodeB

        let projectile = [a, b].first { $0.name == "projectile" }
        let ship       = [a, b].first { $0.name == "ship" }
        let boss       = [a, b].first { $0.name == "boss" }
        let obstacle   = [a, b].first { $0.name == "obstacle" || $0.name == "enemy" }
        let powerUp    = [a, b].first { $0.name == "powerUp" }
        let bossBullet = [a, b].first { $0.name == "bossBullet" }

        if projectile != nil {
            if boss != nil {
                handleProjectileHitBoss()
            } else if let obs = obstacle as? ObstacleNode {
                handleProjectileHitObstacle(obs, projectile: projectile!)
            }
        }

        if ship != nil {
            if let obs = obstacle as? ObstacleNode { handleShipHitObstacle(obs) }
            if let pu  = powerUp as? ObstacleNode  { handleShipHitPowerUp(pu) }
            if let bb  = bossBullet                { handleShipHitBossBullet(bb) }
        }
    }
}
