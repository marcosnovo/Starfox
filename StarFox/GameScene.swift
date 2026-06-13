//
//  GameScene.swift
//  StarFox
//
//  SNES-style rail shooter: the Arwing flies down a scrolling corridor,
//  a wave director scripts enemy squadrons / asteroids / gates, lasers
//  converge on a dual reticle, barrel rolls deflect enemy fire, and every
//  sector ends with a phased boss guardian.
//

import SceneKit
import UIKit

/// A laser bolt (player or enemy) carrying its own velocity.
final class BoltNode: SCNNode {
    var velocity = SCNVector3Zero
}

/// Shared geometry, materials and physics shapes for bolts. Everything in
/// the corridor uses constant-lighting materials, so bolts carry no
/// dynamic lights — emission does all the visual work for free.
private enum BoltAssets {
    // Bright cyan-mint energy bolt — over-bright emission so the camera
    // bloom blows it into a glowing tracer that reads clearly as "ours"
    // against the orange enemy fire.
    static let laserGeometry: SCNGeometry = {
        let geom = SCNCapsule(capRadius: 0.085, height: 2.2)
        let m = SCNMaterial()
        m.lightingModel = .constant
        m.diffuse.contents = UIColor(red: 0.75, green: 1.0, blue: 0.95, alpha: 1)
        m.emission.contents = UIColor(red: 0.45, green: 1.0, blue: 0.92, alpha: 1)
        m.writesToDepthBuffer = false
        geom.materials = [m]
        return geom
    }()
    static let laserShape = SCNPhysicsShape(
        geometry: SCNCylinder(radius: 0.18, height: 2.4), options: nil
    )

    // Hot orange enemy bolt.
    static let enemyGeometry: SCNGeometry = {
        let geom = SCNSphere(radius: 0.34)
        let m = SCNMaterial()
        m.lightingModel = .constant
        m.diffuse.contents = UIColor(red: 1.0, green: 0.62, blue: 0.32, alpha: 1)
        m.emission.contents = UIColor(red: 1.0, green: 0.50, blue: 0.22, alpha: 1)
        m.writesToDepthBuffer = false
        geom.materials = [m]
        return geom
    }()
    static let enemyShape = SCNPhysicsShape(
        geometry: SCNSphere(radius: 0.4), options: nil
    )
}

class GameScene: SCNScene {

    // MARK: - Public

    let state = GameState()
    /// Main-thread mirror of the state, observed by SwiftUI.
    let hud = HUDModel()
    var cameraNode: SCNNode!
    var onPhaseChanged: ((GamePhase) -> Void)?

    // MARK: - Systems

    private var skySystem: SkySystem!
    private var environment: EnvironmentSystem!
    private var particleFX: ParticleFXSystem!

    // MARK: - Input (written on main thread, consumed on render thread)

    private let inputLock = NSLock()
    private var pendingDragDelta: CGPoint = .zero
    private var pendingIsDragging = false
    private var pendingFiringHeld = false
    private var pendingBoostHeld = false
    private var pendingBrakeHeld = false
    private var pendingRollRequest = false
    private var pendingBombRequest = false
    private var pendingStartRequest = false
    private var pendingContinueRequest = false
    private var pendingResumeRequest = false
    private var pendingPauseRequest = false
    private var pendingExitRequest = false

    private var dragDelta: CGPoint = .zero
    private var isDragging = false
    private var firingHeld = false
    private var boostHeld = false
    private var brakeHeld = false

    // MARK: - Nodes

    private var shipNode: ShipNode!
    private var obstacleContainer: SCNNode!
    private var projectileContainer: SCNNode!
    private var bossNode: BossNode?
    private var reticleNear: SCNNode!
    private var reticleFar: SCNNode!

    // MARK: - Game loop state

    private var lastUpdateTime: TimeInterval = 0
    private var eventTimer: TimeInterval = 0
    private var fireTimer: TimeInterval = 0
    private var bossFireTimer: TimeInterval = 0
    private var phaseTimer: TimeInterval = 0
    private var cameraBaseFOV: CGFloat = 54
    private var cameraCurrentFOV: CGFloat = 54
    private var cameraShakeImpulse: CGFloat = 0
    private var cameraShakePhase: TimeInterval = 0
    private var enginePowerCurrent: CGFloat = 0.68
    private var forwardSpeedCurrent: Float = 16
    private var invulnTimer: TimeInterval = 0
    private var hudSyncAccumulator: TimeInterval = 0
    private var speedLines: SCNParticleSystem?

    private var activeObstacles: [ObstacleNode] = []
    private var activeBolts: [BoltNode] = []
    private var activeEnemyBolts: [BoltNode] = []

    // Formation bookkeeping: id → (alive, total). Wipe one for a bonus.
    private var nextFormationID = 1
    private var formations: [Int: (alive: Int, total: Int)] = [:]

    // Once-per-level radio flags.
    private var radioRollTipSent = false
    private var radioLowShieldSent = false

    private var lastPublishedPhase: GamePhase?
    private var fireCooldown: TimeInterval { state.twinLaserTimer > 0 ? 0.16 : 0.24 }
    private let cinematicMinimalMode = true

    // MARK: - Flight constants

    private let baseForwardSpeed: Float = 16
    private let boostBonus: Float = 13
    private let brakePenalty: Float = 8
    private let corridorX: ClosedRange<Float> = -8.5...8.5
    private let corridorY: ClosedRange<Float> = -4.0...4.5
    private let reticleNearZ: Float = 14
    private let reticleFarZ: Float = 28

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
        setupReticles()
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

    func setFiring(_ firing: Bool) {
        inputLock.lock()
        pendingFiringHeld = firing
        inputLock.unlock()
    }

    func setBoosting(_ boosting: Bool) {
        inputLock.lock()
        pendingBoostHeld = boosting
        inputLock.unlock()
    }

    func setBraking(_ braking: Bool) {
        inputLock.lock()
        pendingBrakeHeld = braking
        inputLock.unlock()
    }

    func requestBarrelRoll() {
        inputLock.lock()
        pendingRollRequest = true
        inputLock.unlock()
    }

    func requestBomb() {
        inputLock.lock()
        pendingBombRequest = true
        inputLock.unlock()
    }

    func requestStartNewGame() {
        inputLock.lock()
        pendingStartRequest = true
        inputLock.unlock()
    }

    /// Continue from the game-over screen: same sector, score resets.
    func requestContinue() {
        inputLock.lock()
        pendingContinueRequest = true
        inputLock.unlock()
    }

    func requestResumeGame() {
        inputLock.lock()
        pendingResumeRequest = true
        inputLock.unlock()
    }

    func requestPauseGame() {
        inputLock.lock()
        pendingPauseRequest = true
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
        cam.wantsExposureAdaptation = false

        // Cinematic post-processing — this is what makes the sun, engine
        // glow, lasers and accent lights actually *bloom* against the
        // sunset instead of reading as flat cutouts.
        //
        // Disabled on Simulator: as of iOS 26 the HDR + bloom + colorFringe
        // combo trips Metal's "cannot create View from Memoryless texture"
        // validation assertion. Real devices are fine.
        #if !targetEnvironment(simulator)
        cam.wantsHDR = true
        cam.bloomThreshold = 0.78
        cam.bloomIntensity = 1.35
        cam.bloomBlurRadius = 14.0
        cam.bloomIterationCount = 3
        cam.exposureOffset = 0.10
        cam.saturation = 1.18
        cam.contrast = 0.08
        cam.vignettingIntensity = 0.55
        cam.vignettingPower = 1.4
        cam.colorFringeStrength = 0.25
        cam.colorFringeIntensity = 0.7
        #endif

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

        setupSpeedLines()
        rootNode.addChildNode(cameraNode)
    }

    /// Mint streaks that rush past the camera while boosting.
    private func setupSpeedLines() {
        let lines = SCNParticleSystem()
        lines.birthRate = 0
        lines.particleLifeSpan = 0.35
        lines.particleLifeSpanVariation = 0.08
        lines.particleSize = 0.05
        lines.particleColor = UIColor.cMintHighlight.withAlphaComponent(0.40)
        lines.blendMode = .additive
        lines.emittingDirection = SCNVector3(0, 0, -1)
        lines.particleVelocity = 55
        lines.particleVelocityVariation = 10
        lines.stretchFactor = 9
        lines.isAffectedByGravity = false
        lines.isLightingEnabled = false
        lines.emitterShape = SCNBox(width: 16, height: 10, length: 1, chamferRadius: 0)

        let emitter = SCNNode()
        emitter.position = SCNVector3(0, 0, 26)
        emitter.addParticleSystem(lines)
        cameraNode.addChildNode(emitter)
        speedLines = lines
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

        let rollInfluence = CGFloat(min(1.0, abs(shipNode.airframe.eulerAngles.z)))
        let boostInfluence: CGFloat = boostHeld && state.boostGauge > 0 ? 1 : 0
        let brakeInfluence: CGFloat = brakeHeld ? 1 : 0
        let targetFOV = cameraBaseFOV + (rollInfluence * 2.5) + (boostInfluence * 6.0) - (brakeInfluence * 3.0)
        cameraCurrentFOV += (targetFOV - cameraCurrentFOV) * 0.07
        cameraNode.camera?.fieldOfView = cameraCurrentFOV

        let combat = state.phase == .playing || state.phase == .bossEncounter
        speedLines?.birthRate = (combat && boostInfluence > 0) ? 130 : 0

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

    // MARK: - Ship & reticles

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

    private func makeReticle(radius: CGFloat, opacity: CGFloat, spinning: Bool) -> SCNNode {
        let node = SCNNode()
        let mint = UIColor.cMintHighlight

        let torusGeom = SCNTorus(ringRadius: radius, pipeRadius: 0.03)
        let m = SCNMaterial()
        m.lightingModel = .constant
        m.diffuse.contents = mint.withAlphaComponent(opacity)
        m.emission.contents = mint.withAlphaComponent(opacity * 0.8)
        torusGeom.materials = [m]
        let torus = SCNNode(geometry: torusGeom)
        torus.eulerAngles.x = .pi / 2
        node.addChildNode(torus)

        // Four corner ticks, SNES targeting bracket style, in their own
        // container so the bracket can orbit as a unit.
        let bracket = SCNNode()
        for i in 0..<4 {
            let angle = Float(i) * .pi / 2 + .pi / 4
            let tickGeom = SCNBox(width: 0.04, height: CGFloat(radius) * 0.45, length: 0.04, chamferRadius: 0)
            tickGeom.materials = [m]
            let tick = SCNNode(geometry: tickGeom)
            tick.position = SCNVector3(cos(angle) * Float(radius) * 1.25, sin(angle) * Float(radius) * 1.25, 0)
            tick.eulerAngles.z = angle + .pi / 2
            bracket.addChildNode(tick)
        }
        node.addChildNode(bracket)
        if spinning {
            bracket.runAction(SCNAction.repeatForever(
                SCNAction.rotateBy(x: 0, y: 0, z: .pi * 2, duration: 6.0)
            ))
        }

        let billboard = SCNBillboardConstraint()
        billboard.freeAxes = .all
        node.constraints = [billboard]
        node.renderingOrder = 40
        node.castsShadow = false
        return node
    }

    private func setupReticles() {
        reticleNear = makeReticle(radius: 0.55, opacity: 0.75, spinning: false)
        reticleFar = makeReticle(radius: 0.9, opacity: 0.45, spinning: true)
        rootNode.addChildNode(reticleNear)
        rootNode.addChildNode(reticleFar)
        reticleNear.isHidden = true
        reticleFar.isHidden = true
    }

    private func updateReticles() {
        let visible = state.phase == .playing || state.phase == .bossEncounter
        reticleNear.isHidden = !visible
        reticleFar.isHidden = !visible
        guard visible else { return }
        reticleNear.position = SCNVector3(
            shipNode.position.x, shipNode.position.y, shipNode.position.z + reticleNearZ
        )
        reticleFar.position = SCNVector3(
            shipNode.position.x, shipNode.position.y, shipNode.position.z + reticleFarZ
        )
    }

    // MARK: - Flight

    private func advanceShip(dt: TimeInterval, speedScale: Float = 1) {
        var targetSpeed = baseForwardSpeed
        if boostHeld && state.boostGauge > 0.05 {
            targetSpeed += boostBonus
            state.boostGauge = max(0, state.boostGauge - 0.45 * dt)
        } else if brakeHeld && state.boostGauge > 0.05 {
            targetSpeed -= brakePenalty
            state.boostGauge = max(0, state.boostGauge - 0.28 * dt)
        } else {
            state.boostGauge = min(1, state.boostGauge + 0.22 * dt)
        }
        targetSpeed *= speedScale
        forwardSpeedCurrent += (targetSpeed - forwardSpeedCurrent) * Float(min(1, dt * 5))
        shipNode.position.z += forwardSpeedCurrent * Float(dt)
    }

    private func applyTouchInput() {
        guard isDragging else {
            shipNode.applyTilt(0, dy: 0)
            return
        }
        let dx = Float(dragDelta.x) * 0.022
        let dy = Float(dragDelta.y) * 0.022
        dragDelta = .zero

        shipNode.position.x = (shipNode.position.x + dx).clamped(to: corridorX)
        shipNode.position.y = (shipNode.position.y - dy).clamped(to: corridorY)
        shipNode.applyTilt(dx * 5.5, dy: dy * 5.5)
    }

    /// SNES-style sideways slide while barrel rolling.
    private func applyRollDrift(dt: TimeInterval) {
        guard shipNode.isRolling else { return }
        let drift = shipNode.rollDirection * 5.5 * Float(dt)
        shipNode.position.x = (shipNode.position.x + drift).clamped(to: corridorX)
    }

    /// A broken wing pulls the ship toward the stump until repaired.
    private func applyWingDrag(dt: TimeInterval) {
        guard shipNode.hasBrokenWing else { return }
        let pull = shipNode.brokenWingSide * 0.7 * Float(dt)
        shipNode.position.x = (shipNode.position.x + pull).clamped(to: corridorX)
    }

    private func updateEnginePower(dt: TimeInterval, extraBoost: CGFloat) {
        let normalizedSpeed = CGFloat((forwardSpeedCurrent - 8.0) / 24.0).smoothStep01
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
        firingHeld = pendingFiringHeld
        boostHeld = pendingBoostHeld
        brakeHeld = pendingBrakeHeld

        let shouldStart = pendingStartRequest
        let shouldContinue = pendingContinueRequest
        let shouldResume = pendingResumeRequest
        let shouldPause = pendingPauseRequest
        let shouldExit = pendingExitRequest
        let shouldRoll = pendingRollRequest
        let shouldBomb = pendingBombRequest

        pendingStartRequest = false
        pendingContinueRequest = false
        pendingResumeRequest = false
        pendingPauseRequest = false
        pendingExitRequest = false
        pendingRollRequest = false
        pendingBombRequest = false
        inputLock.unlock()

        if shouldExit {
            resetScene()
            state.phase = .menu
            return
        }

        if shouldContinue, state.phase == .gameOver {
            resetScene()
            state.continueGame()
            phaseTimer = 0
        } else if shouldStart, state.phase == .menu {
            resetScene()
            state.startNewGame()
            phaseTimer = 0
        } else if shouldResume, state.phase == .paused {
            // Resume into the boss fight if one is in progress, otherwise
            // updatePlaying would spawn a duplicate full-health boss.
            state.phase = bossNode != nil ? .bossEncounter : .playing
        } else if shouldPause, state.phase == .playing || state.phase == .bossEncounter {
            state.phase = .paused
        }

        let inCombat = state.phase == .playing || state.phase == .bossEncounter
        if shouldRoll, inCombat {
            performBarrelRoll()
        }
        if shouldBomb, inCombat {
            detonateBomb()
        }
    }

    private func performBarrelRoll() {
        guard !shipNode.isRolling else { return }
        let direction: Float = shipNode.airframe.eulerAngles.z >= 0 ? 1 : -1
        shipNode.barrelRoll(direction: direction)
        SoundSystem.shared.play(.roll, volume: 0.6)
        Haptics.shared.play(.roll)
    }

    // MARK: - Reset

    func resetScene() {
        for o in activeObstacles { o.removeFromParentNode() }
        activeObstacles.removeAll()
        for p in activeBolts { p.removeFromParentNode() }
        activeBolts.removeAll()
        for b in activeEnemyBolts { b.removeFromParentNode() }
        activeEnemyBolts.removeAll()
        bossNode?.removeFromParentNode()
        bossNode = nil
        formations.removeAll()

        shipNode.position = SCNVector3(0, 0, 0)
        shipNode.resetAttitude()
        shipNode.repairWings()
        cameraNode.position = SCNVector3(0, cameraOffsetY, cameraOffsetZ)
        cameraNode.look(at: SCNVector3(0, cameraLookOffsetY, cameraLookOffsetZ))
        cameraCurrentFOV = cameraBaseFOV
        cameraNode.camera?.fieldOfView = cameraCurrentFOV
        cameraShakeImpulse = 0
        cameraShakePhase = 0
        forwardSpeedCurrent = baseForwardSpeed

        lastUpdateTime = 0
        eventTimer = 0
        fireTimer = fireCooldown
        bossFireTimer = 0
        phaseTimer = 0
        invulnTimer = 0
        speedLines?.birthRate = 0
        radioRollTipSent = false
        radioLowShieldSent = false

        particleFX.reset()
        environment.resetAmbientLife()
        environment.resetParallaxLandscape(shipPosition: shipNode.position)
        skySystem.reset()
    }

    private func publishPhaseIfNeeded() {
        guard state.phase != lastPublishedPhase else { return }
        lastPublishedPhase = state.phase
        syncHUD(dt: 0, force: true)

        switch state.phase {
        case .menu:
            SoundSystem.shared.playMusic(.menu)
        case .levelIntro:
            SoundSystem.shared.playMusic(.combat)
        case .gameOver:
            SoundSystem.shared.stopMusic()
        default:
            break // keep whatever is playing
        }

        let phase = state.phase
        DispatchQueue.main.async { [weak self] in
            self?.onPhaseChanged?(phase)
        }
    }

    // MARK: - HUD bridge (render thread → main)

    /// Pushes a snapshot of the game state to the HUD at ~10 Hz (or
    /// immediately when forced, e.g. on phase changes).
    private func syncHUD(dt: TimeInterval, force: Bool = false) {
        hudSyncAccumulator += dt
        guard force || hudSyncAccumulator >= 0.1 else { return }
        hudSyncAccumulator = 0
        let snapshot = state.makeHUDSnapshot()
        let hudRef = hud
        DispatchQueue.main.async {
            hudRef.apply(snapshot)
        }
    }

    private func postRadio(_ callsign: String, _ text: String, duration: TimeInterval = 3.4) {
        let message = RadioMessage(callsign: callsign, text: text)
        let hudRef = hud
        SoundSystem.shared.play(.radio, volume: 0.4)
        DispatchQueue.main.async {
            hudRef.showRadio(message, duration: duration)
        }
    }

    // MARK: - Wave director

    private enum WaveEvent: CaseIterable {
        case enemyFormation, asteroidCluster, ringLine, gate, pillars, powerUp
    }

    /// Each sector has its own flavor: Corneria is urban (gates, pillars),
    /// the Asteroid Belt is rock-heavy, the Space Armada is fighter swarms,
    /// Sector X is a twisting gauntlet, and Venom throws everything at you.
    private func pickWaveEvent() -> WaveEvent {
        let weights: [(WaveEvent, Double)]
        switch (state.level - 1) % GameState.sectorNames.count {
        case 0: // CORNERIA
            weights = [(.enemyFormation, 0.30), (.asteroidCluster, 0.08), (.ringLine, 0.14),
                       (.gate, 0.18), (.pillars, 0.20), (.powerUp, 0.10)]
        case 1: // ASTEROID BELT
            weights = [(.enemyFormation, 0.22), (.asteroidCluster, 0.48), (.ringLine, 0.12),
                       (.gate, 0.06), (.pillars, 0.00), (.powerUp, 0.12)]
        case 2: // SPACE ARMADA
            weights = [(.enemyFormation, 0.52), (.asteroidCluster, 0.12), (.ringLine, 0.12),
                       (.gate, 0.08), (.pillars, 0.06), (.powerUp, 0.10)]
        case 3: // SECTOR X
            weights = [(.enemyFormation, 0.32), (.asteroidCluster, 0.20), (.ringLine, 0.10),
                       (.gate, 0.20), (.pillars, 0.10), (.powerUp, 0.08)]
        default: // VENOM
            weights = [(.enemyFormation, 0.42), (.asteroidCluster, 0.24), (.ringLine, 0.08),
                       (.gate, 0.08), (.pillars, 0.12), (.powerUp, 0.06)]
        }

        var roll = Double.random(in: 0..<1)
        for (event, weight) in weights {
            if roll < weight { return event }
            roll -= weight
        }
        return .enemyFormation
    }

    private func runWaveDirector(dt: TimeInterval) {
        eventTimer += dt
        guard eventTimer >= state.eventInterval else { return }
        eventTimer = 0

        switch pickWaveEvent() {
        case .enemyFormation:  spawnEnemyFormation()
        case .asteroidCluster: spawnAsteroidCluster()
        case .ringLine:        spawnRingLine()
        case .gate:            spawnGate()
        case .pillars:         spawnPillars()
        case .powerUp:         spawnPowerUp()
        }
    }

    private var spawnZ: Float { shipNode.position.z + 95 }

    private func spawnEnemyFormation() {
        let count = Int.random(in: 3...5)
        let formationID = nextFormationID
        nextFormationID += 1
        formations[formationID] = (alive: count, total: count)

        let centerX = Float.random(in: -4...4)
        let centerY = Float.random(in: -1.5...2.5)
        let vFormation = Bool.random()
        let amplitude = Float.random(in: 1.2...2.6)
        let frequency = Float.random(in: 0.9...1.6)
        let speed = Float.random(in: 6...9) + Float(state.level - 1) * 0.8

        for i in 0..<count {
            let offsetIndex = Float(i) - Float(count - 1) / 2
            let x = centerX + offsetIndex * 2.4
            let y = vFormation ? centerY + abs(offsetIndex) * 0.9 : centerY
            let z = spawnZ + (vFormation ? abs(offsetIndex) * 4.5 : Float(i % 2) * 3.0)

            let enemy = ObstacleNode.create(kind: .enemyFighter, at: SCNVector3(x, y, z))
            enemy.formationID = formationID
            enemy.baseX = x
            enemy.baseY = y
            enemy.weaveAmplitude = amplitude
            enemy.weaveFrequency = frequency
            enemy.weavePhase = Float(i) * 0.7
            enemy.approachSpeed = speed
            enemy.fireCooldown = Double.random(in: 1.4...3.0)
            obstacleContainer.addChildNode(enemy)
            activeObstacles.append(enemy)
        }
    }

    private func spawnAsteroidCluster() {
        let count = Int.random(in: 3...6)
        for _ in 0..<count {
            let pos = SCNVector3(
                Float.random(in: -8...8),
                Float.random(in: -3...4),
                spawnZ + Float.random(in: 0...22)
            )
            let asteroid = ObstacleNode.create(kind: .asteroid, at: pos)
            asteroid.approachSpeed = Float.random(in: 2...5)
            obstacleContainer.addChildNode(asteroid)
            activeObstacles.append(asteroid)
        }
    }

    private func spawnRingLine() {
        let x = Float.random(in: -5...5)
        let y = Float.random(in: -2...3)
        for i in 0..<3 {
            let pos = SCNVector3(
                x + Float(i) * Float.random(in: -1.2...1.2),
                y + Float(i) * Float.random(in: -0.6...0.6),
                spawnZ + Float(i) * 14
            )
            let ring = ObstacleNode.create(kind: .ring, at: pos)
            obstacleContainer.addChildNode(ring)
            activeObstacles.append(ring)
        }
    }

    private func spawnGate() {
        let pos = SCNVector3(Float.random(in: -3...3), Float.random(in: -1...1), spawnZ)
        let gate = ObstacleNode.create(kind: .gate, at: pos)
        obstacleContainer.addChildNode(gate)
        activeObstacles.append(gate)
    }

    private func spawnPillars() {
        let count = Int.random(in: 2...3)
        var usedX: [Float] = []
        for _ in 0..<count {
            var x = Float.random(in: -7...7)
            // Keep pillars from stacking on the same lane.
            var attempts = 0
            while usedX.contains(where: { abs($0 - x) < 3 }) && attempts < 6 {
                x = Float.random(in: -7...7)
                attempts += 1
            }
            usedX.append(x)
            let pillar = ObstacleNode.create(kind: .pillar, at: SCNVector3(x, 0, spawnZ + Float.random(in: 0...10)))
            // Root the pillar in the lower half of the corridor.
            if let box = pillar.geometry as? SCNBox {
                pillar.position.y = Float(-7 + box.height / 2)
            }
            obstacleContainer.addChildNode(pillar)
            activeObstacles.append(pillar)
        }
    }

    private func spawnPowerUp() {
        let roll = Double.random(in: 0...1)
        let kind: ObstacleKind
        if roll < 0.45 { kind = .powerShield }
        else if roll < 0.80 { kind = .powerTwin }
        else { kind = .powerBomb }

        let pos = SCNVector3(Float.random(in: -5...5), Float.random(in: -2...3), spawnZ)
        let powerUp = ObstacleNode.create(kind: kind, at: pos)
        obstacleContainer.addChildNode(powerUp)
        activeObstacles.append(powerUp)
    }

    private func moveObstacles(dt: TimeInterval) {
        let scroll = state.scrollSpeed * Float(dt)
        for obs in activeObstacles {
            obs.position.z -= scroll
            obs.update(dt: dt, shipPosition: shipNode.position)
        }
    }

    // MARK: - Enemy fire

    private func updateEnemyFire(dt: TimeInterval) {
        guard activeEnemyBolts.count < 14 else { return }
        for enemy in activeObstacles where enemy.kind == .enemyFighter {
            let distanceAhead = enemy.position.z - shipNode.position.z
            guard distanceAhead > 18 && distanceAhead < 70 else { continue }
            enemy.fireCooldown -= dt
            guard enemy.fireCooldown <= 0 else { continue }
            enemy.fireCooldown = Double.random(in: 1.8...3.2)
            spawnEnemyBolt(from: enemy.position, speed: 24)

            if !radioRollTipSent {
                radioRollTipSent = true
                postRadio("HARE", "Do a barrel roll!")
            }
        }
    }

    private func spawnEnemyBolt(from origin: SCNVector3, speed: Float, direction: SCNVector3? = nil) {
        let bolt = BoltNode()
        bolt.geometry = BoltAssets.enemyGeometry
        bolt.position = origin
        bolt.name = "enemyBolt"

        let dir: SCNVector3
        if let direction {
            dir = direction
        } else {
            // Aim at where the ship will roughly be.
            let lead = forwardSpeedCurrent * 0.35
            let target = SCNVector3(shipNode.position.x, shipNode.position.y, shipNode.position.z + lead)
            dir = normalized(SCNVector3(
                target.x - origin.x, target.y - origin.y, target.z - origin.z
            ))
        }
        bolt.velocity = SCNVector3(dir.x * speed, dir.y * speed, dir.z * speed)

        let body = SCNPhysicsBody(type: .kinematic, shape: BoltAssets.enemyShape)
        body.categoryBitMask = PhysicsCategory.enemyBullet
        body.contactTestBitMask = PhysicsCategory.ship
        body.collisionBitMask = PhysicsCategory.none
        bolt.physicsBody = body

        rootNode.addChildNode(bolt)
        activeEnemyBolts.append(bolt)
        SoundSystem.shared.play(.enemyLaser, volume: 0.22)
    }

    // MARK: - Player fire

    private func tryAutoFire() {
        guard firingHeld else { return }
        guard state.phase == .playing || state.phase == .bossEncounter else { return }
        guard fireTimer >= fireCooldown else { return }
        fireTimer = 0
        fireLasers()
        cameraShakeImpulse = min(0.04, cameraShakeImpulse + 0.014)
        enginePowerCurrent = min(1.0, enginePowerCurrent + 0.07)
    }

    private func fireLasers() {
        // All bolts converge on the far reticle.
        let aim = SCNVector3(
            shipNode.position.x,
            shipNode.position.y,
            shipNode.position.z + reticleFarZ
        )
        // Twin lasers need both wings intact.
        if state.twinLaserTimer > 0 && !shipNode.hasBrokenWing {
            spawnLaserBolt(from: shipNode.muzzleWorldPosition(ShipNode.leftMuzzleLocal), toward: aim)
            spawnLaserBolt(from: shipNode.muzzleWorldPosition(ShipNode.rightMuzzleLocal), toward: aim)
        } else {
            spawnLaserBolt(from: shipNode.muzzleWorldPosition(ShipNode.noseMuzzleLocal), toward: aim)
        }
        SoundSystem.shared.play(.laser, volume: 0.5)
    }

    private func spawnLaserBolt(from origin: SCNVector3, toward target: SCNVector3) {
        let bolt = BoltNode()
        bolt.geometry = BoltAssets.laserGeometry
        bolt.position = origin
        bolt.name = "projectile"

        let dir = normalized(SCNVector3(
            target.x - origin.x, target.y - origin.y, target.z - origin.z
        ))
        let speed: Float = 70
        bolt.velocity = SCNVector3(dir.x * speed, dir.y * speed, dir.z * speed)
        // Capsule axis is +Y; a fixed +90° pitch maps it to +Z (forward).
        // Bolts travel almost straight ahead, so a fixed orientation reads
        // clean — and avoids the degenerate look(at:) basis that made the
        // bolts spray in random directions.
        bolt.eulerAngles = SCNVector3(Float.pi / 2, 0, 0)

        let body = SCNPhysicsBody(type: .kinematic, shape: BoltAssets.laserShape)
        body.categoryBitMask = PhysicsCategory.projectile
        body.contactTestBitMask = PhysicsCategory.obstacle
        body.collisionBitMask = PhysicsCategory.none
        bolt.physicsBody = body

        projectileContainer.addChildNode(bolt)
        activeBolts.append(bolt)
    }

    private func moveBolts(dt: TimeInterval) {
        let f = Float(dt)
        for p in activeBolts {
            p.position.x += p.velocity.x * f
            p.position.y += p.velocity.y * f
            p.position.z += p.velocity.z * f
        }
        for b in activeEnemyBolts {
            b.position.x += b.velocity.x * f
            b.position.y += b.velocity.y * f
            b.position.z += b.velocity.z * f
        }
    }

    private func normalized(_ v: SCNVector3) -> SCNVector3 {
        let len = sqrt(v.x * v.x + v.y * v.y + v.z * v.z)
        guard len > 0.0001 else { return SCNVector3(0, 0, 1) }
        return SCNVector3(v.x / len, v.y / len, v.z / len)
    }

    // MARK: - Bomb

    private func detonateBomb() {
        guard state.bombs > 0 else { return }
        state.bombs -= 1
        cameraShakeImpulse = 0.05
        SoundSystem.shared.play(.bomb, volume: 1.0)
        Haptics.shared.play(.bomb)

        let shipZ = shipNode.position.z
        let victims = activeObstacles.filter {
            $0.isHostile && $0.position.z > shipZ && $0.position.z < shipZ + 100
        }
        for victim in victims {
            particleFX.explode(at: victim.position)
            registerKill(victim)
            victim.removeFromParentNode()
        }
        activeObstacles.removeAll { victims.contains($0) }

        for bolt in activeEnemyBolts { bolt.removeFromParentNode() }
        activeEnemyBolts.removeAll()

        if let boss = bossNode {
            particleFX.explode(at: boss.position)
            for _ in 0..<4 {
                if boss.takeDamage() {
                    bossDefeated()
                    break
                }
            }
        }
    }

    // MARK: - Boss

    private func startBossEncounter() {
        guard bossNode == nil else { return }
        state.phase = .bossEncounter
        // Venom sectors drop the rail: all-range duel with the guardian.
        state.allRangeBoss = state.level % GameState.sectorNames.count == 0
        for o in activeObstacles { o.removeFromParentNode() }
        activeObstacles.removeAll()
        formations.removeAll()

        let boss = BossNode.create(health: state.bossHealth)
        boss.position = SCNVector3(0, 0, shipNode.position.z + 45)
        // Dramatic warp-in: scale up from a point.
        boss.scale = SCNVector3(0.01, 0.01, 0.01)
        let grow = SCNAction.scale(to: 1.0, duration: 0.8)
        grow.timingMode = .easeOut
        boss.runAction(grow)
        rootNode.addChildNode(boss)
        bossNode = boss
        bossFireTimer = 0
        state.bossHealthRemaining = boss.health
        SoundSystem.shared.play(.bossAlarm, volume: 0.7)
        if state.allRangeBoss {
            postRadio("HQ", "All-range mode — engage freely!")
        } else {
            postRadio("HQ", "Enemy guardian ahead — aim for the core!")
        }
    }

    private func bossAttack(_ boss: BossNode) {
        switch boss.nextAttack() {
        case .aimedShot:
            spawnEnemyBolt(from: boss.position, speed: 22)
        case .spreadBurst:
            let origin = boss.position
            let target = shipNode.position
            let baseDir = normalized(SCNVector3(
                target.x - origin.x, target.y - origin.y, target.z - origin.z
            ))
            for offset: Float in [-0.30, 0, 0.30] {
                let dir = normalized(SCNVector3(baseDir.x + offset, baseDir.y, baseDir.z))
                spawnEnemyBolt(from: origin, speed: 20, direction: dir)
            }
        case .radialRing:
            let count = 8
            for i in 0..<count {
                let angle = Float(i) * (.pi * 2) / Float(count)
                let dir = normalized(SCNVector3(cos(angle) * 0.8, sin(angle) * 0.8, -0.9))
                spawnEnemyBolt(from: boss.position, speed: 16, direction: dir)
            }
        }
    }

    private func bossDefeated() {
        guard let boss = bossNode else { return }
        particleFX.explode(at: boss.position)
        let scatter: [SCNVector3] = (0..<4).map { _ in
            SCNVector3(
                boss.position.x + Float.random(in: -3...3),
                boss.position.y + Float.random(in: -3...3),
                boss.position.z + Float.random(in: -2...2)
            )
        }
        for point in scatter { particleFX.explode(at: point) }

        boss.removeFromParentNode()
        bossNode = nil
        state.bossHealthRemaining = 0
        SoundSystem.shared.play(.explosion, volume: 1.0)
        Haptics.shared.play(.bomb)

        let bonus = 1000 + state.hits * 10
        state.score += bonus
        postRadio("HQ", "Mission complete! Returning to base.")
        state.phase = .levelComplete
        phaseTimer = 0
    }

    // MARK: - Cleanup

    private func cleanupAll() {
        let shipZ = shipNode.position.z
        let farBehind = shipZ - 25

        let deadObs = activeObstacles.filter { $0.position.z < farBehind || $0.parent == nil }
        for o in deadObs {
            if o.isEnemy { formationLoss(o) }
            o.removeFromParentNode()
        }
        activeObstacles.removeAll { $0.position.z < farBehind || $0.parent == nil }

        let deadBolts = activeBolts.filter { $0.position.z > shipZ + 120 || $0.parent == nil }
        for p in deadBolts { p.removeFromParentNode() }
        activeBolts.removeAll { $0.position.z > shipZ + 120 || $0.parent == nil }

        let deadEnemyBolts = activeEnemyBolts.filter { abs($0.position.z - shipZ) > 80 || $0.parent == nil }
        for b in deadEnemyBolts { b.removeFromParentNode() }
        activeEnemyBolts.removeAll { abs($0.position.z - shipZ) > 80 || $0.parent == nil }
    }

    // MARK: - Score popups

    private var popupImageCache: [String: UIImage] = [:]

    private func popupImage(text: String, accent: Bool) -> UIImage {
        let key = "\(text)|\(accent)"
        if let cached = popupImageCache[key] { return cached }
        let color = accent
            ? UIColor(red: 0.95, green: 0.58, blue: 0.33, alpha: 1)
            : UIColor.cMintHighlight
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedSystemFont(ofSize: 28, weight: .heavy),
            .foregroundColor: color
        ]
        let size = (text as NSString).size(withAttributes: attributes)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { _ in
            (text as NSString).draw(at: .zero, withAttributes: attributes)
        }
        popupImageCache[key] = image
        return image
    }

    /// Floating "+150" style score feedback at the kill position.
    private func showScorePopup(_ amount: Int, at position: SCNVector3, accent: Bool = false) {
        let image = popupImage(text: "+\(amount)", accent: accent)
        let aspect = image.size.width / max(1, image.size.height)
        let plane = SCNPlane(width: 0.55 * aspect, height: 0.55)
        let m = SCNMaterial()
        m.lightingModel = .constant
        m.diffuse.contents = image
        m.isDoubleSided = true
        m.writesToDepthBuffer = false
        plane.materials = [m]

        let node = SCNNode(geometry: plane)
        node.position = position
        node.constraints = [SCNBillboardConstraint()]
        node.renderingOrder = 50
        node.castsShadow = false
        rootNode.addChildNode(node)

        let rise = SCNAction.moveBy(x: 0, y: 1.6, z: 0, duration: 0.8)
        rise.timingMode = .easeOut
        let fade = SCNAction.sequence([
            SCNAction.wait(duration: 0.35),
            SCNAction.fadeOut(duration: 0.45)
        ])
        node.runAction(SCNAction.sequence([
            SCNAction.group([rise, fade]),
            SCNAction.removeFromParentNode()
        ]))
    }

    // MARK: - Scoring & formations

    private func scoreValue(for kind: ObstacleKind) -> Int {
        switch kind {
        case .enemyFighter: return 150
        case .asteroid:     return 60
        case .pillar:       return 100
        default:            return 0
        }
    }

    /// Counts the kill for score/hits and handles formation wipe bonuses.
    private func registerKill(_ obs: ObstacleNode) {
        let value = scoreValue(for: obs.kind)
        state.score += value
        state.hits += 1
        showScorePopup(value, at: obs.position)

        guard obs.isEnemy, obs.formationID != 0,
              var record = formations[obs.formationID] else { return }
        record.alive -= 1
        if record.alive <= 0 {
            formations[obs.formationID] = nil
            let bonus = record.total * 100
            state.score += bonus
            showScorePopup(bonus, at: SCNVector3(obs.position.x, obs.position.y + 1.2, obs.position.z), accent: true)
            postRadio("FALCON", "Squadron wiped — nice shooting!")
        } else {
            formations[obs.formationID] = record
        }
    }

    /// Enemy escaped or crashed into the ship: the wipe bonus is forfeit,
    /// so the formation record is simply dropped.
    private func formationLoss(_ obs: ObstacleNode) {
        guard obs.formationID != 0 else { return }
        formations[obs.formationID] = nil
    }

    // MARK: - Collision Handlers

    private func handleProjectileHitBoss(projectile: SCNNode) {
        projectile.removeFromParentNode()
        activeBolts.removeAll { $0 === projectile }
        guard let boss = bossNode else { return }
        state.score += 25
        SoundSystem.shared.play(.hit, volume: 0.35)
        if boss.takeDamage() { bossDefeated() }
    }

    private func handleProjectileHitObstacle(_ obs: ObstacleNode, projectile: SCNNode) {
        projectile.removeFromParentNode()
        activeBolts.removeAll { $0 === projectile }

        guard obs.isHostile else { return }
        obs.health -= 1
        guard obs.health <= 0 else {
            obs.hitPop()
            SoundSystem.shared.play(.hit, volume: 0.5)
            return
        }

        particleFX.explode(at: obs.position)
        SoundSystem.shared.play(.explosion, volume: 0.55)
        Haptics.shared.play(.kill)
        registerKill(obs)
        obs.removeFromParentNode()
        activeObstacles.removeAll { $0 === obs }
    }

    private func handleShipHitObstacle(_ obs: ObstacleNode) {
        guard !obs.hasHarmedShip else { return }
        obs.hasHarmedShip = true

        switch obs.kind {
        case .asteroid, .enemyFighter:
            particleFX.explode(at: obs.position)
            if obs.isEnemy { formationLoss(obs) }
            obs.removeFromParentNode()
            activeObstacles.removeAll { $0 === obs }
            applyDamage()
        case .pillar, .gate:
            // Solid structures stay; the scrape shears off the wing on
            // the obstacle's side.
            applyDamage()
            if !shipNode.hasBrokenWing {
                let side: Float = obs.presentation.worldPosition.x >= shipNode.position.x ? 1 : -1
                shipNode.breakWing(side: side)
                state.wingDamaged = true
                postRadio("TOAD", "Your wing's hit! Grab a shield unit!")
            }
        default:
            break
        }
    }

    private func handleShipCrossedGate(_ gate: ObstacleNode) {
        guard !gate.gateCleared else { return }
        gate.gateCleared = true
        state.score += 300
        showScorePopup(300, at: SCNVector3(gate.position.x, gate.position.y + 2.2, gate.position.z), accent: true)
        SoundSystem.shared.play(.ring, volume: 0.45)
        postRadio("HARE", "Threaded the gate — bonus!", duration: 2.2)
    }

    private func handleShipHitRing(_ ring: ObstacleNode) {
        ring.removeFromParentNode()
        activeObstacles.removeAll { $0 === ring }
        state.rings += 1
        state.shield = min(state.shield + 1, state.maxShield)
        state.score += 50
        showScorePopup(50, at: ring.position)
        SoundSystem.shared.play(.ring, volume: 0.6)
        Haptics.shared.play(.pickup)
    }

    private func handleShipHitPowerUp(_ pu: ObstacleNode) {
        pu.removeFromParentNode()
        activeObstacles.removeAll { $0 === pu }
        SoundSystem.shared.play(.powerUp, volume: 0.7)
        Haptics.shared.play(.pickup)

        switch pu.kind {
        case .powerShield:
            state.shield = min(state.shield + 2, state.maxShield)
            if shipNode.hasBrokenWing {
                shipNode.repairWings()
                state.wingDamaged = false
                postRadio("TOAD", "Wing repaired — twin lasers back!", duration: 2.2)
            }
        case .powerTwin:
            state.twinLaserTimer = 8.0
            state.twinLaserActive = true
            postRadio("TOAD", "Twin lasers online!", duration: 2.2)
        case .powerBomb:
            state.bombs = min(state.bombs + 1, state.maxBombs)
        default:
            break
        }
    }

    private func handleShipHitEnemyBolt(_ bolt: SCNNode) {
        bolt.removeFromParentNode()
        activeEnemyBolts.removeAll { $0 === bolt }

        if shipNode.isRolling {
            // Barrel roll deflects incoming fire.
            state.score += 25
            cameraShakeImpulse = min(0.03, cameraShakeImpulse + 0.012)
            SoundSystem.shared.play(.hit, volume: 0.6)
        } else {
            applyDamage()
        }
    }

    private func applyDamage() {
        // Brief post-hit invulnerability so overlapping bolts/spreads don't
        // strip several shield cells in a single instant.
        guard invulnTimer <= 0 else { return }
        invulnTimer = 1.1
        shipNode.flashInvulnerable(duration: 1.1)
        SoundSystem.shared.play(.damage, volume: 0.8)
        Haptics.shared.play(.damage)

        cameraShakeImpulse = min(0.05, cameraShakeImpulse + 0.04)
        state.shield -= 1

        if state.shield <= 2 && state.shield > 0 && !radioLowShieldSent {
            radioLowShieldSent = true
            postRadio("TOAD", "Shields critical — grab a ring!")
        }

        if state.shield <= 0 {
            state.lives -= 1
            if state.lives <= 0 {
                bossNode?.removeFromParentNode()
                bossNode = nil
                state.registerGameOver()
                Haptics.shared.play(.gameOver)
            } else {
                state.shield = state.maxShield
                postRadio("HQ", "Reserve ship deployed. Stay focused!")
            }
        }
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
        case .levelIntro:
            updateLevelIntro(dt: dt)
        case .playing:
            updatePlaying(dt: dt)
        case .bossEncounter:
            updateBossEncounter(dt: dt)
        case .levelComplete:
            updateLevelComplete(dt: dt)
        }
        environment.updateParallaxLandscape(dt: dt, shipPosition: shipNode.position)
        updateReticles()

        publishPhaseIfNeeded()
        syncHUD(dt: dt)
    }

    private func updateLevelIntro(dt: TimeInterval) {
        phaseTimer += dt
        shipNode.position.z += baseForwardSpeed * Float(dt)
        // Glide back to the corridor center for the fly-in.
        shipNode.position.x += (0 - shipNode.position.x) * Float(min(1, dt * 2))
        shipNode.position.y += (0 - shipNode.position.y) * Float(min(1, dt * 2))
        shipNode.applyTilt(0, dy: 0)
        updateEnginePower(dt: dt, extraBoost: 0.1)
        updateCamera(dt: dt)

        if phaseTimer >= 3.0 {
            phaseTimer = 0
            state.phase = .playing
            postRadio("HQ", "Entering \(state.sectorName). All ships check in!")
        }
    }

    private func updatePlaying(dt: TimeInterval) {
        advanceShip(dt: dt)
        applyTouchInput()
        applyRollDrift(dt: dt)
        applyWingDrag(dt: dt)
        updateEnginePower(dt: dt, extraBoost: boostHeld ? 0.12 : 0)
        updateCamera(dt: dt)
        invulnTimer = max(0, invulnTimer - dt)

        fireTimer = min(fireCooldown, fireTimer + dt)
        tryAutoFire()

        state.levelTimer += dt
        runWaveDirector(dt: dt)
        moveObstacles(dt: dt)
        updateEnemyFire(dt: dt)
        moveBolts(dt: dt)
        cleanupAll()

        tickTwinLaser(dt: dt)
        if state.levelTimer >= state.levelDuration { startBossEncounter() }
    }

    private func updateBossEncounter(dt: TimeInterval) {
        // All-range mode slows the rail to a crawl so the duel happens
        // in place; normal guardians keep full corridor speed.
        advanceShip(dt: dt, speedScale: state.allRangeBoss ? 0.3 : 1)
        applyTouchInput()
        applyRollDrift(dt: dt)
        applyWingDrag(dt: dt)
        updateEnginePower(dt: dt, extraBoost: 0.08)
        updateCamera(dt: dt)
        invulnTimer = max(0, invulnTimer - dt)

        fireTimer = min(fireCooldown, fireTimer + dt)
        tryAutoFire()

        if let boss = bossNode {
            boss.update(dt: dt, shipPosition: shipNode.position, allRange: state.allRangeBoss)
            state.bossHealthRemaining = boss.health

            bossFireTimer += dt
            if bossFireTimer >= boss.attackInterval {
                bossFireTimer = 0
                bossAttack(boss)
            }
        }

        moveBolts(dt: dt)
        cleanupAll()
        tickTwinLaser(dt: dt)
    }

    private func updateLevelComplete(dt: TimeInterval) {
        phaseTimer += dt
        shipNode.position.z += (baseForwardSpeed + 8) * Float(dt)
        shipNode.position.x += (0 - shipNode.position.x) * Float(min(1, dt * 1.5))
        shipNode.applyTilt(0, dy: 0)
        updateEnginePower(dt: dt, extraBoost: 0.2)
        updateCamera(dt: dt)
        moveBolts(dt: dt)
        cleanupAll()

        if phaseTimer >= 4.0 {
            phaseTimer = 0
            shipNode.repairWings() // hangar fixes the airframe between sectors
            state.nextLevel()      // sets phase to .levelIntro
            radioRollTipSent = true // only tip on the first sector
            radioLowShieldSent = false
        }
    }

    private func tickTwinLaser(dt: TimeInterval) {
        guard state.twinLaserTimer > 0 else { return }
        state.twinLaserTimer -= dt
        if state.twinLaserTimer <= 0 {
            state.twinLaserTimer = 0
            state.twinLaserActive = false
        }
    }
}

// MARK: - SCNPhysicsContactDelegate

extension GameScene: SCNPhysicsContactDelegate {

    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        // No combat consequences outside combat — keeps the ship safe
        // during mission intro/complete fly-bys and after game over.
        guard state.phase == .playing || state.phase == .bossEncounter else { return }

        let a = contact.nodeA
        let b = contact.nodeB

        let projectile = [a, b].first { $0.name == "projectile" }
        let ship       = [a, b].first { $0.name == "ship" }
        let boss       = [a, b].first { $0.name == "boss" }
        let solidNames: Set<String> = ["obstacle", "enemy", "gateFrame"]
        let solid      = [a, b].first { solidNames.contains($0.name ?? "") }
        let gateCenter = [a, b].first { $0.name == "gateCenter" }
        let ring       = [a, b].first { $0.name == "ring" }
        let powerUp    = [a, b].first { $0.name == "powerUp" }
        let enemyBolt  = [a, b].first { $0.name == "enemyBolt" }

        if let projectile {
            if boss != nil {
                handleProjectileHitBoss(projectile: projectile)
            } else if let solid, let obs = ObstacleNode.owner(of: solid) {
                handleProjectileHitObstacle(obs, projectile: projectile)
            }
        }

        if ship != nil {
            if let solid, let obs = ObstacleNode.owner(of: solid) {
                handleShipHitObstacle(obs)
            }
            if let gateCenter, let gate = ObstacleNode.owner(of: gateCenter) {
                handleShipCrossedGate(gate)
            }
            if let ring, let obs = ObstacleNode.owner(of: ring) {
                handleShipHitRing(obs)
            }
            if let powerUp, let obs = ObstacleNode.owner(of: powerUp) {
                handleShipHitPowerUp(obs)
            }
            if let enemyBolt {
                handleShipHitEnemyBolt(enemyBolt)
            }
            if boss != nil {
                applyDamage()
            }
        }
    }
}
