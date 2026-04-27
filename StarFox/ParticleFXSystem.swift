//
//  ParticleFXSystem.swift
//  StarFox
//

import SceneKit
import UIKit

enum WeatherState: CaseIterable {
    case clear, snow, rain, fog
}

class ParticleFXSystem {
    private let rootNode: SCNNode
    private let minimalMode: Bool

    private var atmosphereContainer = SCNNode()
    private var speedLinesSystems: [SCNParticleSystem] = []
    private var speedLinesNodes: [SCNNode] = []
    private var dustSystem: SCNParticleSystem?
    private var dustNode: SCNNode?

    private var weatherContainer = SCNNode()
    private var snowNode: SCNNode?
    private var rainNode: SCNNode?
    private var fogNode: SCNNode?
    private var snowSystem: SCNParticleSystem?
    private var rainSystem: SCNParticleSystem?
    private var fogSystem: SCNParticleSystem?

    private(set) var currentWeather: WeatherState = .clear
    private var targetWeather: WeatherState = .clear
    private var weatherTransitionProgress: CGFloat = 1
    private var weatherHoldTime: TimeInterval = 0
    private var weatherChangeInterval: TimeInterval = 30
    private let weatherTransitionDuration: TimeInterval = AltoVisualStyle.defaultWeatherTransitionDuration

    private var weatherPresets: [WeatherState: WeatherPresetConfig] {
        let day = AltoVisualStyle.palette(for: .day)
        let dusk = AltoVisualStyle.palette(for: .dusk)
        let night = AltoVisualStyle.palette(for: .night)
        return [
            .clear: WeatherPresetConfig(
                skyTopTint: .white, skyBottomTint: .white, skyStrength: 0,
                ambientTint: .white, keyTint: .white, fillTint: .white,
                ambientIntensityMultiplier: 1, keyIntensityMultiplier: 1,
                fillIntensityMultiplier: 1, densityMultiplier: 0
            ),
            .snow: WeatherPresetConfig(
                skyTopTint: day.highlight, skyBottomTint: day.mist, skyStrength: 0.30,
                ambientTint: day.highlight, keyTint: day.mist, fillTint: day.highlight,
                ambientIntensityMultiplier: 0.95, keyIntensityMultiplier: 0.90,
                fillIntensityMultiplier: 0.95, densityMultiplier: 0.55
            ),
            .rain: WeatherPresetConfig(
                skyTopTint: night.skyTop, skyBottomTint: night.skyBottom, skyStrength: 0.52,
                ambientTint: night.mist, keyTint: night.highlight, fillTint: night.mist,
                ambientIntensityMultiplier: 0.86, keyIntensityMultiplier: 0.74,
                fillIntensityMultiplier: 0.80, densityMultiplier: 0.72
            ),
            .fog: WeatherPresetConfig(
                skyTopTint: dusk.mist, skyBottomTint: day.mist, skyStrength: 0.44,
                ambientTint: day.mist, keyTint: dusk.highlight, fillTint: day.highlight,
                ambientIntensityMultiplier: 0.92, keyIntensityMultiplier: 0.78,
                fillIntensityMultiplier: 0.82, densityMultiplier: 0.48
            )
        ]
    }

    init(rootNode: SCNNode, minimalMode: Bool) {
        self.rootNode = rootNode
        self.minimalMode = minimalMode
    }

    // MARK: - Atmosphere

    func setupAtmosphere() {
        atmosphereContainer.removeFromParentNode()
        atmosphereContainer = SCNNode()
        atmosphereContainer.name = "atmosphereContainer"
        atmosphereContainer.renderingOrder = -140
        rootNode.addChildNode(atmosphereContainer)

        speedLinesSystems.removeAll()
        speedLinesNodes.removeAll()
        dustSystem = nil
        dustNode = nil

        let biases: [(x: Float, y: Float)] = [
            (-1.0, -0.2), (1.0, -0.2),
            (-0.8,  0.4), (0.8,  0.4),
            (-0.6, -0.5), (0.6, -0.5)
        ]
        for bias in biases {
            let ps = makeSpeedLinesSystem(xBias: bias.x, yBias: bias.y)
            let node = SCNNode()
            node.position = SCNVector3(bias.x * 6.0, bias.y * 3.5, 8.0)
            node.addParticleSystem(ps)
            atmosphereContainer.addChildNode(node)
            speedLinesSystems.append(ps)
            speedLinesNodes.append(node)
        }

        let dust = makeDustSystem()
        let dNode = SCNNode()
        dNode.position = SCNVector3(0, 0, 4)
        dNode.addParticleSystem(dust)
        atmosphereContainer.addChildNode(dNode)
        dustSystem = dust
        dustNode = dNode
    }

    func updateAtmosphere(shipPosition: SCNVector3) {
        atmosphereContainer.position = SCNVector3(
            shipPosition.x * 0.22,
            shipPosition.y * 0.10,
            shipPosition.z
        )
    }

    // MARK: - Weather

    func setupWeather() {
        weatherContainer.removeFromParentNode()
        weatherContainer = SCNNode()
        weatherContainer.name = "weatherContainer"
        weatherContainer.renderingOrder = -150
        rootNode.addChildNode(weatherContainer)

        snowSystem = makeSnowSystem()
        rainSystem = makeRainSystem()
        fogSystem = makeFogSystem()

        let snowEmitter = SCNNode()
        snowEmitter.name = "snowEmitter"
        snowEmitter.position = SCNVector3(0, 16, 20)
        if let snowSystem { snowEmitter.addParticleSystem(snowSystem) }
        weatherContainer.addChildNode(snowEmitter)
        snowNode = snowEmitter

        let rainEmitter = SCNNode()
        rainEmitter.name = "rainEmitter"
        rainEmitter.position = SCNVector3(0, 18, 22)
        rainEmitter.eulerAngles = SCNVector3(0, 0.35, 0)
        if let rainSystem { rainEmitter.addParticleSystem(rainSystem) }
        weatherContainer.addChildNode(rainEmitter)
        rainNode = rainEmitter

        let fogEmitter = SCNNode()
        fogEmitter.name = "fogEmitter"
        fogEmitter.position = SCNVector3(0, -2.8, 17)
        if let fogSystem { fogEmitter.addParticleSystem(fogSystem) }
        weatherContainer.addChildNode(fogEmitter)
        fogNode = fogEmitter

        currentWeather = .clear
        targetWeather = .clear
        weatherTransitionProgress = 1
        weatherHoldTime = 0
        weatherChangeInterval = TimeInterval.random(in: 24...42)
        applyWeatherParticles()
    }

    func updateWeather(dt: TimeInterval, shipPosition: SCNVector3) {
        if minimalMode {
            currentWeather = .clear
            targetWeather = .clear
            weatherTransitionProgress = 1
            snowSystem?.birthRate = 0
            rainSystem?.birthRate = 0
            fogSystem?.birthRate = 0
            return
        }
        guard snowSystem != nil || rainSystem != nil || fogSystem != nil else { return }

        weatherHoldTime += dt
        if weatherTransitionProgress < 1 {
            weatherTransitionProgress = min(
                1,
                weatherTransitionProgress + CGFloat(dt / weatherTransitionDuration)
            )
            if weatherTransitionProgress >= 1 {
                currentWeather = targetWeather
            }
        } else if weatherHoldTime >= weatherChangeInterval {
            weatherHoldTime = 0
            weatherChangeInterval = TimeInterval.random(in: 24...42)
            targetWeather = pickNextWeatherState()
            weatherTransitionProgress = 0
        }

        weatherContainer.position = SCNVector3(
            shipPosition.x * 0.32,
            shipPosition.y * 0.16,
            shipPosition.z + 2.0
        )

        applyWeatherParticles()
    }

    func blendedWeatherPreset() -> WeatherPreset {
        var skyTop = UIColor.black
        var skyBottom = UIColor.black
        var ambientTint = UIColor.black
        var keyTint = UIColor.black
        var fillTint = UIColor.black
        var skyStrength: CGFloat = 0
        var ambientMul: CGFloat = 0
        var keyMul: CGFloat = 0
        var fillMul: CGFloat = 0
        var density: CGFloat = 0

        for state in WeatherState.allCases {
            guard let preset = weatherPresets[state] else { continue }
            let w = weatherWeight(for: state)
            skyTop = skyTop.weightedAdd(color: preset.skyTopTint, weight: w)
            skyBottom = skyBottom.weightedAdd(color: preset.skyBottomTint, weight: w)
            ambientTint = ambientTint.weightedAdd(color: preset.ambientTint, weight: w)
            keyTint = keyTint.weightedAdd(color: preset.keyTint, weight: w)
            fillTint = fillTint.weightedAdd(color: preset.fillTint, weight: w)
            skyStrength += preset.skyStrength * w
            ambientMul += preset.ambientIntensityMultiplier * w
            keyMul += preset.keyIntensityMultiplier * w
            fillMul += preset.fillIntensityMultiplier * w
            density += preset.densityMultiplier * w
        }

        return WeatherPreset(
            skyTopTint: skyTop,
            skyBottomTint: skyBottom,
            skyStrength: skyStrength,
            ambientTint: ambientTint,
            keyTint: keyTint,
            fillTint: fillTint,
            ambientIntensityMultiplier: ambientMul,
            keyIntensityMultiplier: keyMul,
            fillIntensityMultiplier: fillMul,
            densityMultiplier: density
        )
    }

    // MARK: - Explosions

    func explode(at position: SCNVector3) {
        let colors: [UIColor] = [
            UIColor(hex: "#E8905A"),
            UIColor(hex: "#C07040"),
            UIColor(hex: "#F0B070"),
            UIColor(hex: "#F8D098")
        ]
        for color in colors {
            for _ in 0..<2 {
                let particle = SCNNode()
                let g = SCNSphere(radius: CGFloat.random(in: 0.2...0.45))
                let m = SCNMaterial()
                m.lightingModel = .constant
                m.diffuse.contents = color
                m.emission.contents = color
                g.materials = [m]
                particle.geometry = g
                particle.position = SCNVector3(
                    position.x + Float.random(in: -0.7...0.7),
                    position.y + Float.random(in: -0.7...0.7),
                    position.z + Float.random(in: -0.7...0.7)
                )
                rootNode.addChildNode(particle)
                particle.runAction(SCNAction.sequence([
                    SCNAction.group([
                        SCNAction.scale(to: CGFloat.random(in: 2.5...4.0), duration: 0.30),
                        SCNAction.fadeOut(duration: 0.30)
                    ]),
                    SCNAction.removeFromParentNode()
                ]))
            }
        }
    }

    // MARK: - Reset

    func reset() {
        weatherHoldTime = 0
        weatherTransitionProgress = 1
        currentWeather = .clear
        targetWeather = .clear
        weatherChangeInterval = TimeInterval.random(in: 24...42)
        applyWeatherParticles()
        updateAtmosphere(shipPosition: SCNVector3Zero)
    }

    // MARK: - Private Weather Helpers

    private func pickNextWeatherState() -> WeatherState {
        let candidates: [WeatherState] = [.clear, .clear, .snow, .rain, .fog]
        var next = candidates.randomElement() ?? .clear
        if next == currentWeather {
            next = WeatherState.allCases.filter { $0 != currentWeather }.randomElement() ?? .clear
        }
        return next
    }

    private func weatherWeight(for state: WeatherState) -> CGFloat {
        if currentWeather == targetWeather {
            return state == currentWeather ? 1 : 0
        }
        let t = weatherTransitionProgress.smoothStep01
        if state == currentWeather { return 1 - t }
        if state == targetWeather { return t }
        return 0
    }

    private func applyWeatherParticles() {
        let snowWeight = weatherWeight(for: .snow)
        let rainWeight = weatherWeight(for: .rain)
        let fogWeight = weatherWeight(for: .fog)
        let weatherDensity = blendedWeatherPreset().densityMultiplier

        snowSystem?.birthRate = 140 * snowWeight * weatherDensity
        rainSystem?.birthRate = 220 * rainWeight * weatherDensity
        fogSystem?.birthRate = 58 * fogWeight * weatherDensity
    }

    // MARK: - Private Particle Factories

    private func makeSpeedLinesSystem(xBias: Float, yBias: Float) -> SCNParticleSystem {
        let ps = SCNParticleSystem()
        ps.birthRate = 2.5
        ps.loops = true
        ps.emissionDuration = 0
        ps.birthLocation = .volume
        ps.emitterShape = SCNBox(width: 3.0, height: 5.0, length: 1.2, chamferRadius: 0)
        ps.particleLifeSpan = 0.42
        ps.particleLifeSpanVariation = 0.10
        ps.particleSize = 0.018
        ps.particleSizeVariation = 0.006
        ps.particleColor = UIColor(white: 1.0, alpha: 0.20)
        ps.particleColorVariation = SCNVector4(0, 0, 0, 0.08)
        ps.blendMode = .alpha
        ps.emittingDirection = SCNVector3(xBias * 0.10, yBias * 0.06, -1)
        ps.particleVelocity = 38
        ps.particleVelocityVariation = 8
        ps.spreadingAngle = 4
        ps.stretchFactor = 4.5
        ps.acceleration = SCNVector3(xBias * 1.2, yBias * 0.4, -4.0)
        ps.isLightingEnabled = false
        ps.isAffectedByGravity = false
        return ps
    }

    private func makeDustSystem() -> SCNParticleSystem {
        let ps = SCNParticleSystem()
        ps.birthRate = 5
        ps.loops = true
        ps.emissionDuration = 0
        ps.birthLocation = .volume
        ps.emitterShape = SCNBox(width: 30, height: 12, length: 24, chamferRadius: 0)
        ps.particleLifeSpan = 5.0
        ps.particleLifeSpanVariation = 1.5
        ps.particleSize = 0.06
        ps.particleSizeVariation = 0.03
        ps.particleColor = UIColor(red: 1.0, green: 0.92, blue: 0.78, alpha: 0.08)
        ps.particleColorVariation = SCNVector4(0.03, 0.03, 0.03, 0.04)
        ps.blendMode = .alpha
        ps.emittingDirection = SCNVector3(0, 0, -1)
        ps.particleVelocity = 1.8
        ps.particleVelocityVariation = 0.8
        ps.acceleration = SCNVector3(0.01, 0.03, -0.2)
        ps.spreadingAngle = 60
        ps.isLightingEnabled = false
        ps.isAffectedByGravity = false
        ps.warmupDuration = 3.0
        return ps
    }

    private func makeSnowSystem() -> SCNParticleSystem {
        let ps = SCNParticleSystem()
        ps.birthRate = 140
        ps.emissionDuration = 0
        ps.loops = true
        ps.birthLocation = .surface
        ps.emitterShape = SCNBox(width: 48, height: 1.0, length: 62, chamferRadius: 0)
        ps.particleLifeSpan = 8.2
        ps.particleLifeSpanVariation = 1.8
        ps.particleSize = 0.08
        ps.particleSizeVariation = 0.05
        ps.particleVelocity = 1.3
        ps.particleVelocityVariation = 0.5
        ps.acceleration = SCNVector3(0, -1.4, 0)
        ps.spreadingAngle = 10
        ps.particleColor = UIColor(white: 0.96, alpha: 0.82)
        ps.particleColorVariation = SCNVector4(0.03, 0.03, 0.05, 0.20)
        ps.blendMode = .alpha
        ps.isAffectedByGravity = false
        ps.isLightingEnabled = false
        ps.warmupDuration = 2.0
        return ps
    }

    private func makeRainSystem() -> SCNParticleSystem {
        let palette = AltoVisualStyle.palette(for: .dusk)
        let ps = SCNParticleSystem()
        ps.birthRate = 220
        ps.emissionDuration = 0
        ps.loops = true
        ps.birthLocation = .surface
        ps.emitterShape = SCNBox(width: 40, height: 1.0, length: 55, chamferRadius: 0)
        ps.particleLifeSpan = 1.25
        ps.particleLifeSpanVariation = 0.25
        ps.particleSize = 0.035
        ps.particleSizeVariation = 0.01
        ps.particleVelocity = 20
        ps.particleVelocityVariation = 4
        ps.acceleration = SCNVector3(-5.6, -22.0, 0.4)
        ps.spreadingAngle = 2
        ps.stretchFactor = 8.5
        ps.fresnelExponent = 0
        ps.particleColor = palette.mist.withAlphaComponent(0.36)
        ps.particleColorVariation = SCNVector4(0.02, 0.03, 0.05, 0.12)
        ps.blendMode = .alpha
        ps.isAffectedByGravity = false
        ps.isLightingEnabled = false
        ps.warmupDuration = 0.8
        return ps
    }

    private func makeFogSystem() -> SCNParticleSystem {
        let palette = AltoVisualStyle.palette(for: .dusk)
        let ps = SCNParticleSystem()
        ps.birthRate = 58
        ps.emissionDuration = 0
        ps.loops = true
        ps.birthLocation = .volume
        ps.emitterShape = SCNBox(width: 58, height: 6.0, length: 70, chamferRadius: 0)
        ps.particleLifeSpan = 9.5
        ps.particleLifeSpanVariation = 2.2
        ps.particleSize = 2.8
        ps.particleSizeVariation = 1.0
        ps.particleVelocity = 0.45
        ps.particleVelocityVariation = 0.20
        ps.acceleration = SCNVector3(0.03, 0.02, 0)
        ps.spreadingAngle = 180
        ps.particleColor = palette.mist.withAlphaComponent(0.12)
        ps.particleColorVariation = SCNVector4(0.05, 0.05, 0.05, 0.06)
        ps.blendMode = .alpha
        ps.isAffectedByGravity = false
        ps.isLightingEnabled = false
        ps.warmupDuration = 3.0
        return ps
    }
}

private struct WeatherPresetConfig {
    let skyTopTint: UIColor
    let skyBottomTint: UIColor
    let skyStrength: CGFloat
    let ambientTint: UIColor
    let keyTint: UIColor
    let fillTint: UIColor
    let ambientIntensityMultiplier: CGFloat
    let keyIntensityMultiplier: CGFloat
    let fillIntensityMultiplier: CGFloat
    let densityMultiplier: CGFloat
}
