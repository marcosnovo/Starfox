//
//  EnvironmentSystem.swift
//  StarFox
//

import SceneKit
import UIKit

// MARK: - Supporting Types

struct ParallaxProfile {
    let color: UIColor
    let opacity: CGFloat
    let baseY: Float
    let height: CGFloat
    let peaks: Int
    let jitter: CGFloat
    let treeDensity: Int
    let ruinDensity: Int
    let valleyFactor: CGFloat
    let cloudDensity: Int
    let birdDensity: Int
}

struct ParallaxLayer {
    var nodes: [SCNNode]
    let speed: Float
    let segmentLength: Float
    let lateralFactor: Float
    let profile: ParallaxProfile
    let width: CGFloat
}

enum AmbientLifeKind {
    case bird
    case mote
}

struct AmbientLifeElement {
    let kind: AmbientLifeKind
    let node: SCNNode
    let baseX: Float
    let baseY: Float
    let amplitudeX: Float
    let amplitudeY: Float
    let frequency: Float
    var phase: Float
    let zDrift: Float
    let baseOpacity: CGFloat
    let opacityVariation: CGFloat
}

// MARK: - EnvironmentSystem

class EnvironmentSystem {

    // MARK: - State

    private(set) var parallaxContainer = SCNNode()
    private(set) var parallaxLayers: [ParallaxLayer] = []
    private(set) var ambientLifeContainer = SCNNode()
    private(set) var ambientLifeElements: [AmbientLifeElement] = []

    private var birdSpawnTimer: TimeInterval = 0
    private var moteSpawnTimer: TimeInterval = 0
    private var birdSpawnInterval: TimeInterval = 3.4
    private var moteSpawnInterval: TimeInterval = 0.75

    /// Mountain layer colour for the current sky phase, in the same
    /// index order as `parallaxLayers`. Updated by `tintToPalette` so
    /// the silhouettes drift through the dawn/day/dusk/night cycle.
    private var currentLayerColors: [UIColor] = []
    private var paletteTintAccumulator: TimeInterval = 0
    private let paletteTintInterval: TimeInterval = 0.4

    private let rootNode: SCNNode
    private let minimalMode: Bool

    // MARK: - Init

    init(rootNode: SCNNode, minimalMode: Bool) {
        self.rootNode = rootNode
        self.minimalMode = minimalMode
    }

    // MARK: - Parallax Landscape

    func setupParallaxLandscape(shipPosition: SCNVector3) {
        parallaxContainer.removeFromParentNode()
        parallaxContainer = SCNNode()
        parallaxContainer.name = "parallaxLandscape"
        rootNode.addChildNode(parallaxContainer)
        parallaxLayers.removeAll()

        // Alto's-style tonal ramp: warm desaturated rose near the
        // horizon, deepening to a near-black silhouette in the
        // foreground. Atmospheric perspective is encoded as VALUE,
        // not as additive haze.
        let far    = UIColor(hex: "#C58576")
        let farMid = UIColor(hex: "#8E5560")
        let mid    = UIColor(hex: "#5C3E55")
        let near   = UIColor(hex: "#2E2434")
        let front  = UIColor(hex: "#14111A")
        let width: CGFloat = 200
        let segmentsPerLayer = 8
        let shipZ = shipPosition.z
        let startZ = shipZ - 20

        let profiles: [(ParallaxProfile, speed: Float, segment: Float, lateral: Float)] = [
            (
                ParallaxProfile(
                    color: far,
                    opacity: 0.35,
                    baseY: -2.5,
                    height: 5.5,
                    peaks: 4,
                    jitter: 0.08,
                    treeDensity: 0,
                    ruinDensity: 0,
                    valleyFactor: 0.0,
                    cloudDensity: 2,
                    birdDensity: 1
                ),
                speed: 0.15,
                segment: 28,
                lateral: 0.05
            ),
            (
                ParallaxProfile(
                    color: farMid,
                    opacity: 0.45,
                    baseY: -3.2,
                    height: 5.7,
                    peaks: 5,
                    jitter: 0.12,
                    treeDensity: 0,
                    ruinDensity: 0,
                    valleyFactor: 0.10,
                    cloudDensity: 1,
                    birdDensity: 1
                ),
                speed: 0.30,
                segment: 24,
                lateral: 0.10
            ),
            (
                ParallaxProfile(
                    color: mid,
                    opacity: 0.65,
                    baseY: -4.5,
                    height: 6.0,
                    peaks: 6,
                    jitter: 0.16,
                    treeDensity: 3,
                    ruinDensity: 0,
                    valleyFactor: 0.25,
                    cloudDensity: 0,
                    birdDensity: 1
                ),
                speed: 0.54,
                segment: 20,
                lateral: 0.18
            ),
            (
                ParallaxProfile(
                    color: near,
                    opacity: 0.85,
                    baseY: -6.0,
                    height: 6.5,
                    peaks: 7,
                    jitter: 0.22,
                    treeDensity: 3,
                    ruinDensity: 0,
                    valleyFactor: 0.40,
                    cloudDensity: 0,
                    birdDensity: 0
                ),
                speed: 0.84,
                segment: 16,
                lateral: 0.28
            ),
            (
                ParallaxProfile(
                    color: front,
                    opacity: 1.0,
                    baseY: -8.0,
                    height: 6.5,
                    peaks: 5,
                    jitter: 0.18,
                    treeDensity: 0,
                    ruinDensity: 0,
                    valleyFactor: 0.50,
                    cloudDensity: 0,
                    birdDensity: 0
                ),
                speed: 1.20,
                segment: 12,
                lateral: 0.40
            )
        ]

        for (layerIndex, config) in profiles.enumerated() {
            var nodes: [SCNNode] = []
            for segment in 0..<segmentsPerLayer {
                let node = makeParallaxSegment(width: width, segmentLength: CGFloat(config.segment), profile: config.0)
                node.position = SCNVector3(
                    Float.random(in: -2.2...2.2),
                    config.0.baseY,
                    startZ + Float(segment) * config.segment
                )
                node.renderingOrder = -200 - (layerIndex * 10)
                node.setValue(node.position.x, forKey: "offsetX")
                decorateLandscapeSegment(node: node, profile: config.0)
                parallaxContainer.addChildNode(node)
                nodes.append(node)
            }

            parallaxLayers.append(
                ParallaxLayer(
                    nodes: nodes,
                    speed: config.speed,
                    segmentLength: config.segment,
                    lateralFactor: config.lateral,
                    profile: config.0,
                    width: width
                )
            )
        }
    }

    func updateParallaxLandscape(dt: TimeInterval, shipPosition: SCNVector3) {
        guard !parallaxLayers.isEmpty else { return }
        let shipZ = shipPosition.z
        let cutoff = shipZ - 45

        for layerIndex in parallaxLayers.indices {
            let layer = parallaxLayers[layerIndex]
            var maxZ = layer.nodes.map { $0.position.z }.max() ?? shipZ

            for node in layer.nodes {
                node.position.z -= layer.speed * Float(dt)

                let baseOffset = (node.value(forKey: "offsetX") as? NSNumber)?.floatValue ?? 0
                let targetX = baseOffset + shipPosition.x * layer.lateralFactor
                node.position.x += (targetX - node.position.x) * 0.08

                if node.position.z < cutoff {
                    maxZ += layer.segmentLength + Float.random(in: -4...4)
                    node.position.z = maxZ
                    let newOffset = Float.random(in: -2.2...2.2)
                    node.setValue(newOffset, forKey: "offsetX")
                    node.position.x = newOffset
                    let recycleColor = layerColor(at: layerIndex, fallback: layer.profile.color)
                    node.geometry = makeMountainGeometry(
                        width: layer.width,
                        height: layer.profile.height,
                        peaks: layer.profile.peaks,
                        jitter: layer.profile.jitter,
                        color: recycleColor,
                        atmosphereMix: max(0, 0.95 - layer.profile.opacity),
                        extrusionDepth: CGFloat(layer.segmentLength) * 1.15,
                        valleyFactor: layer.profile.valleyFactor
                    )
                    decorateLandscapeSegment(node: node, profile: layer.profile, colorOverride: recycleColor)
                }
            }
        }
    }

    func resetParallaxLandscape(shipPosition: SCNVector3) {
        guard !parallaxLayers.isEmpty else { return }
        let shipZ = shipPosition.z
        let startZ = shipZ - 20

        for layerIndex in parallaxLayers.indices {
            let layer = parallaxLayers[layerIndex]
            for (segmentIndex, node) in layer.nodes.enumerated() {
                node.position.z = startZ + Float(segmentIndex) * layer.segmentLength
                node.position.x = Float.random(in: -2.2...2.2)
                node.position.y = layer.profile.baseY
                node.setValue(node.position.x, forKey: "offsetX")
            }
        }
    }

    // MARK: - Sky-driven palette tint

    /// Re-tint the parallax silhouettes from the active sky palette so
    /// the mountains drift through the dawn/day/dusk/night cycle.
    /// Throttled — we don't need to repaint every frame; the sky
    /// gradient itself only refreshes a couple of times a second.
    func tintToPalette(_ horizon: UIColor, dt: TimeInterval) {
        guard !parallaxLayers.isEmpty else { return }
        paletteTintAccumulator += dt
        if paletteTintAccumulator < paletteTintInterval { return }
        paletteTintAccumulator = 0

        let void = UIColor(hex: "#0E0C18")
        // Per-layer darkness: far layers stay close to the horizon
        // value, near layers darken toward a pure silhouette void.
        let layerTs: [CGFloat] = [0.22, 0.46, 0.68, 0.86, 1.00]

        var newColors: [UIColor] = []
        newColors.reserveCapacity(parallaxLayers.count)

        for (i, layer) in parallaxLayers.enumerated() {
            let t = layerTs[min(i, layerTs.count - 1)]
            let layerColor = UIColor.lerp(from: horizon, to: void, t: t)
            newColors.append(layerColor)

            for segment in layer.nodes {
                segment.geometry?.firstMaterial?.diffuse.contents = layerColor
                for child in segment.childNodes where child.name != "__ink" {
                    child.geometry?.firstMaterial?.diffuse.contents = layerColor
                    for grand in child.childNodes where grand.name != "__ink" {
                        grand.geometry?.firstMaterial?.diffuse.contents = layerColor
                    }
                }
            }
        }
        currentLayerColors = newColors
    }

    private func layerColor(at index: Int, fallback: UIColor) -> UIColor {
        guard index >= 0, index < currentLayerColors.count else { return fallback }
        return currentLayerColors[index]
    }

    // MARK: - Ambient Life

    func setupAmbientLife() {
        ambientLifeContainer.removeFromParentNode()
        ambientLifeContainer = SCNNode()
        ambientLifeContainer.name = "ambientLifeContainer"
        ambientLifeContainer.renderingOrder = -130
        rootNode.addChildNode(ambientLifeContainer)

        ambientLifeElements.removeAll()
        birdSpawnTimer = 0
        moteSpawnTimer = 0
        birdSpawnInterval = TimeInterval.random(in: 2.8...5.2)
        moteSpawnInterval = TimeInterval.random(in: 0.85...1.60)
    }

    func updateAmbientLife(dt: TimeInterval, shipPosition: SCNVector3) {
        if minimalMode { return }
        birdSpawnTimer += dt
        moteSpawnTimer += dt

        if birdSpawnTimer >= birdSpawnInterval {
            birdSpawnTimer = 0
            birdSpawnInterval = TimeInterval.random(in: 2.8...5.2)
            if ambientLifeElements.filter({ $0.kind == .bird }).count < 7 {
                spawnAmbientBird(shipPosition: shipPosition)
            }
        }

        if moteSpawnTimer >= moteSpawnInterval {
            moteSpawnTimer = 0
            moteSpawnInterval = TimeInterval.random(in: 0.85...1.60)
            if ambientLifeElements.filter({ $0.kind == .mote }).count < 12 {
                spawnAmbientMote(shipPosition: shipPosition)
            }
        }

        let shipZ = shipPosition.z
        for index in ambientLifeElements.indices {
            var element = ambientLifeElements[index]
            element.phase += element.frequency * Float(dt)

            let waveX = sin(element.phase) * element.amplitudeX
            let waveY = cos(element.phase * 0.7) * element.amplitudeY
            element.node.position.x = element.baseX + waveX
            element.node.position.y = element.baseY + waveY
            element.node.position.z -= element.zDrift * Float(dt)

            let pulse = CGFloat((sin(Double(element.phase) * 0.8) + 1) * 0.5)
            element.node.opacity = max(
                0.06,
                min(0.40, element.baseOpacity + (pulse - 0.5) * element.opacityVariation)
            )

            if element.kind == .bird {
                element.node.eulerAngles.z = sin(element.phase * 1.7) * 0.14
            }

            ambientLifeElements[index] = element
        }

        let farBehind = shipZ - 34
        let farAhead = shipZ + 120
        let centerX = shipPosition.x
        ambientLifeElements.removeAll { element in
            let p = element.node.position
            let out = p.z < farBehind ||
                p.z > farAhead ||
                abs(p.x - centerX) > 38 ||
                p.y < -10 ||
                p.y > 18 ||
                element.node.parent == nil
            if out {
                element.node.removeFromParentNode()
            }
            return out
        }
    }

    func resetAmbientLife() {
        for element in ambientLifeElements {
            element.node.removeFromParentNode()
        }
        ambientLifeElements.removeAll()
        birdSpawnTimer = 0
        moteSpawnTimer = 0
        birdSpawnInterval = TimeInterval.random(in: 2.8...5.2)
        moteSpawnInterval = TimeInterval.random(in: 0.85...1.60)
    }

    // MARK: - Private Helpers — Parallax Segments

    private func makeParallaxSegment(width: CGFloat, segmentLength: CGFloat, profile: ParallaxProfile) -> SCNNode {
        let geometry = makeMountainGeometry(
            width: width,
            height: profile.height,
            peaks: profile.peaks,
            jitter: profile.jitter,
            color: profile.color,
            atmosphereMix: max(0, 0.95 - profile.opacity),
            extrusionDepth: segmentLength * 1.15,
            valleyFactor: profile.valleyFactor
        )
        let node = SCNNode(geometry: geometry)
        node.opacity = profile.opacity
        return node
    }

    private func makeMountainGeometry(
        width: CGFloat,
        height: CGFloat,
        peaks: Int,
        jitter: CGFloat,
        color: UIColor,
        atmosphereMix: CGFloat,
        extrusionDepth: CGFloat = 10.0,
        valleyFactor: CGFloat = 0.0
    ) -> SCNGeometry {
        let halfW = width * 0.5
        let baseY: CGFloat = 0
        let step = width / CGFloat(max(1, peaks))

        let path = UIBezierPath()
        path.move(to: CGPoint(x: -halfW, y: baseY))

        for i in 0...peaks {
            let x = -halfW + CGFloat(i) * step
            let ridge = CGFloat.random(in: 0.55...1.0)
            let variation = CGFloat.random(in: -jitter...jitter)
            let centerDist = abs(x) / halfW
            let valleyMult = 1.0 - valleyFactor * (1.0 - centerDist)
            let y = max(0.5, (ridge + variation) * height * valleyMult)
            path.addLine(to: CGPoint(x: x, y: y))
        }

        path.addLine(to: CGPoint(x: halfW, y: baseY))
        path.close()

        let shape = SCNShape(path: path, extrusionDepth: extrusionDepth)
        let material = SCNMaterial()
        material.lightingModel = .constant
        // Pure flat silhouette — no haze blend, no emission glow. The
        // atmospheric perspective comes from the layer's chosen tonal
        // value, not from additive warmth that would smear the silhouette.
        material.diffuse.contents = color
        material.isDoubleSided = true
        material.readsFromDepthBuffer = false
        material.writesToDepthBuffer = false
        shape.materials = [material]
        // `atmosphereMix` is intentionally unused now; the parameter is
        // kept so callers compile, and reads as a no-op.
        _ = atmosphereMix
        return shape
    }

    // MARK: - Private Helpers — Decoration

    private func decorateLandscapeSegment(node: SCNNode, profile: ParallaxProfile, colorOverride: UIColor? = nil) {
        node.childNodes.forEach { $0.removeFromParentNode() }
        guard profile.treeDensity > 0 || profile.ruinDensity > 0 || profile.cloudDensity > 0 || profile.birdDensity > 0 else { return }
        let color = colorOverride ?? profile.color

        for _ in 0..<profile.treeDensity {
            let tree = makeTreeSiluetteNode(color: color)
            let crestMinY = Float(profile.height * 0.58)
            let crestMaxY = Float(profile.height * 0.95)
            tree.position = SCNVector3(
                Float.random(in: -60...60),
                Float.random(in: crestMinY...crestMaxY),
                0.12
            )
            let nearFactor = Float(min(1.0, profile.opacity))
            tree.scale = SCNVector3(
                Float.random(in: 0.45...(0.80 + nearFactor * 0.90)),
                Float.random(in: 0.60...(1.20 + nearFactor * 2.50)),
                1
            )
            tree.opacity = CGFloat.random(in: 0.78...0.98)
            tree.renderingOrder = node.renderingOrder + 1
            node.addChildNode(tree)
        }

        for _ in 0..<profile.ruinDensity {
            let ruin = makeRuinArchNode(color: color)
            let crestMinY = Float(profile.height * 0.50)
            let crestMaxY = Float(profile.height * 0.82)
            ruin.position = SCNVector3(
                Float.random(in: -52...52),
                Float.random(in: crestMinY...crestMaxY),
                0.13
            )
            let s = Float.random(in: 0.8...1.4)
            ruin.scale = SCNVector3(s, s * Float.random(in: 0.75...1.20), 1)
            ruin.opacity = CGFloat.random(in: 0.76...0.94)
            ruin.renderingOrder = node.renderingOrder + 1
            node.addChildNode(ruin)
        }

        for _ in 0..<profile.cloudDensity {
            let cloud = makeCloudNode(color: color)
            cloud.position = SCNVector3(
                Float.random(in: -55...55),
                Float(profile.height * 0.85) + Float.random(in: 0.5...3.0),
                Float.random(in: -0.5...0.5)
            )
            let s = Float.random(in: 1.2...2.8)
            cloud.scale = SCNVector3(s, s * Float.random(in: 0.3...0.5), 1)
            cloud.opacity = CGFloat.random(in: 0.12...0.25)
            cloud.renderingOrder = node.renderingOrder - 1
            node.addChildNode(cloud)
        }

        for _ in 0..<profile.birdDensity {
            let flock = makeBirdGroupNode(color: color)
            flock.position = SCNVector3(
                Float.random(in: -40...40),
                Float(profile.height * 0.70) + Float.random(in: 1.0...4.0),
                Float.random(in: -0.3...0.3)
            )
            let s = Float.random(in: 0.6...1.2)
            flock.scale = SCNVector3(s, s, 1)
            flock.opacity = CGFloat.random(in: 0.30...0.55)
            flock.renderingOrder = node.renderingOrder - 1
            node.addChildNode(flock)
        }
    }

    private func makeTreeSiluetteNode(color: UIColor) -> SCNNode {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: -0.30, y: 0))
        path.addLine(to: CGPoint(x: 0, y: 1.35))
        path.addLine(to: CGPoint(x: 0.30, y: 0))
        path.close()

        let shape = SCNShape(path: path, extrusionDepth: 0.02)
        let material = SCNMaterial()
        material.lightingModel = .constant
        material.diffuse.contents = color
        // No emission — silhouettes read pure flat against the sky.
        material.isDoubleSided = true
        shape.materials = [material]
        return SCNNode(geometry: shape)
    }

    private func makeRuinArchNode(color: UIColor) -> SCNNode {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: -1.0, y: 0))
        path.addLine(to: CGPoint(x: -1.0, y: 1.2))
        path.addLine(to: CGPoint(x: -0.55, y: 1.2))
        path.addLine(to: CGPoint(x: -0.55, y: 0.34))
        path.addLine(to: CGPoint(x: -0.15, y: 0.34))
        path.addLine(to: CGPoint(x: -0.15, y: 1.2))
        path.addLine(to: CGPoint(x: 0.15, y: 1.2))
        path.addLine(to: CGPoint(x: 0.15, y: 0.34))
        path.addLine(to: CGPoint(x: 0.55, y: 0.34))
        path.addLine(to: CGPoint(x: 0.55, y: 1.2))
        path.addLine(to: CGPoint(x: 1.0, y: 1.2))
        path.addLine(to: CGPoint(x: 1.0, y: 0))
        path.close()

        let shape = SCNShape(path: path, extrusionDepth: 0.04)
        let material = SCNMaterial()
        material.lightingModel = .constant
        material.diffuse.contents = color
        // No emission — silhouettes read pure flat against the sky.
        material.isDoubleSided = true
        shape.materials = [material]
        return SCNNode(geometry: shape)
    }

    private func makeCloudNode(color: UIColor) -> SCNNode {
        let path = UIBezierPath()
        let w = CGFloat.random(in: 3.0...5.0)
        let h = CGFloat.random(in: 0.6...1.2)
        path.move(to: CGPoint(x: -w / 2, y: 0))
        path.addQuadCurve(to: CGPoint(x: -w * 0.15, y: h * 0.7), controlPoint: CGPoint(x: -w * 0.38, y: h * 0.5))
        path.addQuadCurve(to: CGPoint(x: w * 0.2, y: h), controlPoint: CGPoint(x: 0, y: h * 1.1))
        path.addQuadCurve(to: CGPoint(x: w / 2, y: 0), controlPoint: CGPoint(x: w * 0.42, y: h * 0.6))
        path.close()

        let shape = SCNShape(path: path, extrusionDepth: 0.01)
        let material = SCNMaterial()
        material.lightingModel = .constant
        material.diffuse.contents = color
        // No emission — silhouettes read pure flat against the sky.
        material.isDoubleSided = true
        shape.materials = [material]
        return SCNNode(geometry: shape)
    }

    private func makeBirdGroupNode(color: UIColor) -> SCNNode {
        let group = SCNNode()
        let count = Int.random(in: 3...6)
        for _ in 0..<count {
            let path = UIBezierPath()
            let span: CGFloat = CGFloat.random(in: 0.18...0.30)
            let dip: CGFloat = span * 0.3
            path.move(to: CGPoint(x: -span, y: 0))
            path.addQuadCurve(to: CGPoint(x: 0, y: -dip), controlPoint: CGPoint(x: -span * 0.4, y: -dip * 0.2))
            path.addQuadCurve(to: CGPoint(x: span, y: 0), controlPoint: CGPoint(x: span * 0.4, y: -dip * 0.2))
            path.addLine(to: CGPoint(x: span, y: 0.04))
            path.addQuadCurve(to: CGPoint(x: 0, y: -dip + 0.04), controlPoint: CGPoint(x: span * 0.4, y: -dip * 0.2 + 0.04))
            path.addQuadCurve(to: CGPoint(x: -span, y: 0.04), controlPoint: CGPoint(x: -span * 0.4, y: -dip * 0.2 + 0.04))
            path.close()

            let shape = SCNShape(path: path, extrusionDepth: 0.01)
            let material = SCNMaterial()
            material.lightingModel = .constant
            material.diffuse.contents = color
            material.isDoubleSided = true
            shape.materials = [material]

            let bird = SCNNode(geometry: shape)
            bird.position = SCNVector3(
                Float.random(in: -1.5...1.5),
                Float.random(in: -0.8...0.8),
                0
            )
            group.addChildNode(bird)
        }
        return group
    }

    // MARK: - Private Helpers — Ambient Life Spawning

    private func spawnAmbientBird(shipPosition: SCNVector3) {
        let bird = makeAmbientBirdNode()
        let shipZ = shipPosition.z
        let depth = Float.random(in: 0...1)
        let baseX = Float.random(in: -15...15)
        let baseY = Float.random(in: 5.0...11.0)
        bird.position = SCNVector3(baseX, baseY, shipZ + Float.random(in: 36...88))

        let scale = Float.random(in: 0.26...0.52) * (0.8 + depth * 0.5)
        bird.scale = SCNVector3(scale, scale, scale)
        bird.opacity = CGFloat(0.08 + depth * 0.16)
        ambientLifeContainer.addChildNode(bird)

        ambientLifeElements.append(
            AmbientLifeElement(
                kind: .bird,
                node: bird,
                baseX: baseX,
                baseY: baseY,
                amplitudeX: Float.random(in: 0.6...1.8),
                amplitudeY: Float.random(in: 0.10...0.35),
                frequency: Float.random(in: 0.55...1.00),
                phase: Float.random(in: 0...(Float.pi * 2)),
                zDrift: Float.random(in: 0.45...1.25),
                baseOpacity: CGFloat(0.08 + depth * 0.16),
                opacityVariation: 0.06
            )
        )
    }

    private func makeAmbientBirdNode() -> SCNNode {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: -1.2, y: -0.05))
        path.addLine(to: CGPoint(x: -0.45, y: 0.35))
        path.addLine(to: CGPoint(x: 0.0, y: 0.05))
        path.addLine(to: CGPoint(x: 0.45, y: 0.35))
        path.addLine(to: CGPoint(x: 1.2, y: -0.05))
        path.addLine(to: CGPoint(x: 0.48, y: 0.03))
        path.addLine(to: CGPoint(x: 0.0, y: -0.10))
        path.addLine(to: CGPoint(x: -0.48, y: 0.03))
        path.close()

        let shape = SCNShape(path: path, extrusionDepth: 0.03)
        shape.chamferRadius = 0
        let material = SCNMaterial()
        material.lightingModel = .constant
        material.diffuse.contents = UIColor.cDeepCharcoal
        material.emission.contents = UIColor.cDeepCharcoal.dimmed(0.20)
        material.isDoubleSided = true
        shape.materials = [material]

        let node = SCNNode(geometry: shape)
        node.renderingOrder = -120
        node.eulerAngles.x = -.pi / 2
        return node
    }

    private func spawnAmbientMote(shipPosition: SCNVector3) {
        let mote = makeAmbientMoteNode()
        let shipZ = shipPosition.z
        let depth = Float.random(in: 0...1)
        let baseX = Float.random(in: -17...17)
        let baseY = Float.random(in: -2.0...9.0)
        mote.position = SCNVector3(baseX, baseY, shipZ + Float.random(in: 26...96))
        mote.opacity = CGFloat(0.06 + depth * 0.18)
        ambientLifeContainer.addChildNode(mote)

        ambientLifeElements.append(
            AmbientLifeElement(
                kind: .mote,
                node: mote,
                baseX: baseX,
                baseY: baseY,
                amplitudeX: Float.random(in: 0.25...0.95),
                amplitudeY: Float.random(in: 0.08...0.55),
                frequency: Float.random(in: 0.25...0.70),
                phase: Float.random(in: 0...(Float.pi * 2)),
                zDrift: Float.random(in: 0.25...0.90),
                baseOpacity: CGFloat(0.06 + depth * 0.18),
                opacityVariation: 0.10
            )
        )
    }

    private func makeAmbientMoteNode() -> SCNNode {
        let radius = CGFloat.random(in: 0.045...0.11)
        let sphere = SCNSphere(radius: radius)
        sphere.segmentCount = 4
        let material = SCNMaterial()
        material.lightingModel = .constant
        // Pale dust drifting in the sun-warmed air — Alto's-style
        // soft motes, not Outrun neon. A tiny chance of a colder mote
        // gives the air a hint of variety without breaking the palette.
        let warm = Int.random(in: 0...5) > 0
        let warmCore = UIColor(red: 1.00, green: 0.92, blue: 0.78, alpha: 1)
        let coolCore = UIColor(red: 0.86, green: 0.90, blue: 0.96, alpha: 1)
        material.diffuse.contents = warm ? warmCore : coolCore
        material.emission.contents = (warm ? warmCore : coolCore).dimmed(0.55)
        sphere.materials = [material]

        let node = SCNNode(geometry: sphere)
        node.renderingOrder = -122
        return node
    }
}
