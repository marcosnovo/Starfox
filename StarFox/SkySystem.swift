//
//  SkySystem.swift
//  StarFox
//

import SceneKit
import UIKit

struct SkyPreset {
    let topColor: UIColor
    let midColor: UIColor
    let horizonColor: UIColor
    let sunCoreColor: UIColor
    let ambientColor: UIColor
    let ambientIntensity: CGFloat
    let keyColor: UIColor
    let keyIntensity: CGFloat
    let fillColor: UIColor
    let fillIntensity: CGFloat
}

struct WeatherPreset {
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

class SkySystem {
    private let rootNode: SCNNode

    private(set) var ambientLightNode: SCNNode?
    private(set) var keyLightNode: SCNNode?
    private(set) var fillLightNode: SCNNode?

    private var sunNode: SCNNode?
    private var sunGlowNode: SCNNode?
    private var horizonHazeNode: SCNNode?

    private var skyCycleTime: TimeInterval = 0
    private let skyCycleDuration: TimeInterval = AltoVisualStyle.defaultSkyCycleDuration
    private let staticGoldenHourSky = true

    var presets: [SkyPreset] {
        let preset = SkyPreset(
            topColor: UIColor(hex: "#6F3E4C"),
            midColor: UIColor(hex: "#D97854"),
            horizonColor: UIColor(hex: "#F6A35A"),
            sunCoreColor: UIColor(hex: "#FFF2A6"),
            ambientColor: UIColor(hex: "#9D5A55"),
            ambientIntensity: 300,
            keyColor: UIColor(hex: "#D97854"),
            keyIntensity: 620,
            fillColor: UIColor(hex: "#F6A35A"),
            fillIntensity: 280
        )
        return [preset, preset, preset, preset]
    }

    init(rootNode: SCNNode) {
        self.rootNode = rootNode
    }

    func setupBackground(scene: SCNScene) {
        scene.background.contents = makeSkyBackgroundImage()
        scene.fogColor = UIColor(hex: "#9D5A55")
        scene.fogStartDistance = 160
        scene.fogEndDistance = 380
        scene.fogDensityExponent = 0.30
    }

    func setupLighting(scene: SCNScene) {
        scene.lightingEnvironment.contents = UIColor(hex: "#4B3442")
        scene.lightingEnvironment.intensity = 0.3

        let ambient = SCNNode()
        let al = SCNLight()
        al.type = .ambient
        al.color = UIColor(hex: "#9D5A55")
        al.intensity = 180
        ambient.light = al
        rootNode.addChildNode(ambient)
        ambientLightNode = ambient

        let key = SCNNode()
        let keyLight = SCNLight()
        keyLight.type = .directional
        keyLight.intensity = 420
        keyLight.castsShadow = false
        keyLight.color = UIColor(hex: "#D97854")
        key.light = keyLight
        key.eulerAngles = SCNVector3(-0.60, 0.0, 0)
        rootNode.addChildNode(key)
        keyLightNode = key

        let fill = SCNNode()
        let fillLight = SCNLight()
        fillLight.type = .omni
        fillLight.intensity = 140
        fillLight.attenuationStartDistance = 0
        fillLight.attenuationEndDistance = 16
        fillLight.color = UIColor(hex: "#F6A35A")
        fill.light = fillLight
        fill.position = SCNVector3(0, 3.0, -6.0)
        rootNode.addChildNode(fill)
        fillLightNode = fill
    }

    func setupSunNodes() {
        sunNode?.removeFromParentNode()
        sunGlowNode?.removeFromParentNode()
        horizonHazeNode?.removeFromParentNode()

        let sunGeom = SCNCylinder(radius: 10.0, height: 0.06)
        let sunMaterial = SCNMaterial()
        sunMaterial.lightingModel = .constant
        sunMaterial.diffuse.contents = UIColor(hex: "#FFF2A6")
        sunMaterial.emission.contents = UIColor(hex: "#FFF2A6")
        sunMaterial.isDoubleSided = true
        sunMaterial.readsFromDepthBuffer = false
        sunMaterial.writesToDepthBuffer = false
        sunGeom.materials = [sunMaterial]
        let sun = SCNNode(geometry: sunGeom)
        sun.position = SCNVector3(0, 2.5, 128)
        sun.eulerAngles.x = .pi / 2
        sun.renderingOrder = -395
        rootNode.addChildNode(sun)
        sunNode = sun

        let glowGeom = SCNCylinder(radius: 30.0, height: 0.04)
        let glowMaterial = SCNMaterial()
        glowMaterial.lightingModel = .constant
        glowMaterial.diffuse.contents = UIColor(hex: "#FFD37A").withAlphaComponent(0.40)
        glowMaterial.emission.contents = UIColor(hex: "#FFD37A").withAlphaComponent(0.35)
        glowMaterial.blendMode = .add
        glowMaterial.isDoubleSided = true
        glowMaterial.transparency = 0.75
        glowMaterial.readsFromDepthBuffer = false
        glowMaterial.writesToDepthBuffer = false
        glowGeom.materials = [glowMaterial]
        let glow = SCNNode(geometry: glowGeom)
        glow.position = SCNVector3(0, 2.5, 127.5)
        glow.eulerAngles.x = .pi / 2
        glow.renderingOrder = -396
        rootNode.addChildNode(glow)
        sunGlowNode = glow

        let hazeGeom = SCNCylinder(radius: 60, height: 0.03)
        let hazeMat = SCNMaterial()
        hazeMat.lightingModel = .constant
        hazeMat.diffuse.contents = UIColor(hex: "#F6A35A").withAlphaComponent(0.18)
        hazeMat.emission.contents = UIColor(hex: "#D97854").withAlphaComponent(0.14)
        hazeMat.blendMode = .add
        hazeMat.isDoubleSided = true
        hazeMat.transparency = 0.50
        hazeMat.readsFromDepthBuffer = false
        hazeMat.writesToDepthBuffer = false
        hazeGeom.materials = [hazeMat]
        let haze = SCNNode(geometry: hazeGeom)
        haze.position = SCNVector3(0, 0.4, 126)
        haze.eulerAngles.x = .pi / 2
        haze.renderingOrder = -397
        rootNode.addChildNode(haze)
        horizonHazeNode = haze
    }

    func update(dt: TimeInterval, shipPosition: SCNVector3, weatherPreset: WeatherPreset) {
        if staticGoldenHourSky {
            skyCycleTime = 0
        } else {
            skyCycleTime += dt
        }
        let duration = max(120.0, skyCycleDuration)
        let phaseProgress = staticGoldenHourSky ? 0 : (skyCycleTime.truncatingRemainder(dividingBy: duration)) / duration

        let skyPresets = presets
        let segmentCount = skyPresets.count
        let scaled = phaseProgress * Double(segmentCount)
        let indexA = Int(floor(scaled)) % segmentCount
        let indexB = (indexA + 1) % segmentCount
        let localT = CGFloat(scaled - floor(scaled))
        let easedT = AltoVisualStyle.calmEase(localT)

        let a = skyPresets[indexA]
        let b = skyPresets[indexB]

        var ambientColor = UIColor.lerp(from: a.ambientColor, to: b.ambientColor, t: easedT)
        var keyColor = UIColor.lerp(from: a.keyColor, to: b.keyColor, t: easedT)
        var fillColor = UIColor.lerp(from: a.fillColor, to: b.fillColor, t: easedT)
        var ambientIntensity = CGFloat.lerp(from: a.ambientIntensity, to: b.ambientIntensity, t: easedT)
        var keyIntensity = CGFloat.lerp(from: a.keyIntensity, to: b.keyIntensity, t: easedT)
        var fillIntensity = CGFloat.lerp(from: a.fillIntensity, to: b.fillIntensity, t: easedT)

        let weather = weatherPreset
        ambientColor = ambientColor.multiplied(by: weather.ambientTint)
        keyColor = keyColor.multiplied(by: weather.keyTint)
        fillColor = fillColor.multiplied(by: weather.fillTint)
        ambientIntensity *= weather.ambientIntensityMultiplier
        keyIntensity *= weather.keyIntensityMultiplier
        fillIntensity *= weather.fillIntensityMultiplier

        sunNode?.position = SCNVector3(
            shipPosition.x * 0.04,
            2.5 + shipPosition.y * 0.015,
            shipPosition.z + 128
        )
        sunGlowNode?.position = SCNVector3(
            shipPosition.x * 0.04,
            2.5 + shipPosition.y * 0.015,
            shipPosition.z + 127.5
        )
        horizonHazeNode?.position = SCNVector3(
            shipPosition.x * 0.03,
            1.0 + shipPosition.y * 0.01,
            shipPosition.z + 126
        )

        if let ambientLight = ambientLightNode?.light {
            ambientLight.color = ambientColor
            ambientLight.intensity = ambientIntensity
        }
        if let keyLight = keyLightNode?.light {
            keyLight.color = keyColor
            keyLight.intensity = keyIntensity
        }
        if let fillLight = fillLightNode?.light {
            fillLight.color = fillColor
            fillLight.intensity = fillIntensity
        }
    }

    func reset() {
        skyCycleTime = 0
    }

    // MARK: - Sky Background Image

    private func makeSkyBackgroundImage() -> UIImage {
        let w = 960
        let h = 540
        let size = CGSize(width: w, height: h)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let cg = ctx.cgContext
            let space = CGColorSpaceCreateDeviceRGB()

            let gradientColors = [
                UIColor(hex: "#6F3E4C").cgColor,
                UIColor(hex: "#7A4550").cgColor,
                UIColor(hex: "#9D5A55").cgColor,
                UIColor(hex: "#C06A50").cgColor,
                UIColor(hex: "#D97854").cgColor,
                UIColor(hex: "#E88C54").cgColor,
                UIColor(hex: "#F6A35A").cgColor,
                UIColor(hex: "#FFD37A").cgColor,
                UIColor(hex: "#F6A35A").cgColor,
                UIColor(hex: "#D97854").cgColor,
                UIColor(hex: "#9D5A55").cgColor,
                UIColor(hex: "#4B3442").cgColor,
                UIColor(hex: "#241C2A").cgColor,
                UIColor(hex: "#17131D").cgColor,
            ] as CFArray
            let gradientLocations: [CGFloat] = [
                0.00, 0.10, 0.22, 0.32, 0.38,
                0.44, 0.48, 0.52,
                0.56, 0.64, 0.74,
                0.86, 0.94, 1.00
            ]
            if let gradient = CGGradient(colorsSpace: space, colors: gradientColors, locations: gradientLocations) {
                cg.drawLinearGradient(
                    gradient,
                    start: CGPoint(x: 0, y: 0),
                    end: CGPoint(x: 0, y: CGFloat(h)),
                    options: []
                )
            }

            let sunCenter = CGPoint(x: CGFloat(w) / 2, y: CGFloat(h) * 0.50)
            let sunColors = [
                UIColor(hex: "#FFF2A6").withAlphaComponent(0.95).cgColor,
                UIColor(hex: "#FFD37A").withAlphaComponent(0.80).cgColor,
                UIColor(hex: "#F6A35A").withAlphaComponent(0.50).cgColor,
                UIColor(hex: "#D97854").withAlphaComponent(0.25).cgColor,
                UIColor(hex: "#9D5A55").withAlphaComponent(0.08).cgColor,
                UIColor(hex: "#6F3E4C").withAlphaComponent(0.0).cgColor,
            ] as CFArray
            let sunLocations: [CGFloat] = [0.0, 0.06, 0.18, 0.34, 0.58, 1.0]
            if let sunGradient = CGGradient(colorsSpace: space, colors: sunColors, locations: sunLocations) {
                cg.drawRadialGradient(
                    sunGradient,
                    startCenter: sunCenter,
                    startRadius: 0,
                    endCenter: sunCenter,
                    endRadius: CGFloat(w) * 0.42,
                    options: []
                )
            }
        }
    }
}
