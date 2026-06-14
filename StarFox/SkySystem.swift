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

        // Sun rim — a bright warm directional coming from the sun (ahead,
        // +Z) toward the camera. A default directional shines toward -Z;
        // tilting down rakes the tops/leading edges of hulls flying ahead
        // of the camera, giving lit metal the cinematic backlit halo
        // instead of reading as flat cutouts.
        let rim = SCNNode()
        let rimLight = SCNLight()
        rimLight.type = .directional
        rimLight.intensity = 950
        rimLight.castsShadow = false
        rimLight.color = UIColor(hex: "#FFE4B0")
        rim.light = rimLight
        rim.eulerAngles = SCNVector3(-0.3, 0, 0)
        rootNode.addChildNode(rim)

        // Cool teal counter-fill raking up from below, so the shadowed,
        // camera-facing underside of hulls keeps subtle definition (the
        // warm-key / cool-fill contrast that makes models read as 3D).
        // Directional so it lights hulls anywhere along the corridor.
        let cool = SCNNode()
        let coolLight = SCNLight()
        coolLight.type = .directional
        coolLight.intensity = 260
        coolLight.castsShadow = false
        coolLight.color = UIColor(hex: "#5A7E8C")
        cool.light = coolLight
        cool.eulerAngles = SCNVector3(Float.pi - 0.35, 0, 0)
        rootNode.addChildNode(cool)
    }

    func setupSunNodes() {
        sunNode?.removeFromParentNode()
        sunGlowNode?.removeFromParentNode()
        horizonHazeNode?.removeFromParentNode()

        // Outrun-style banded sun: a camera-facing textured disc with the
        // classic horizontal cuts across its lower half.
        let sunGeom = SCNPlane(width: 26, height: 26)
        let sunMaterial = SCNMaterial()
        sunMaterial.lightingModel = .constant
        sunMaterial.diffuse.contents = Self.sunDiscImage()
        sunMaterial.emission.contents = Self.sunDiscImage()
        sunMaterial.blendMode = .alpha
        sunMaterial.isDoubleSided = true
        sunMaterial.readsFromDepthBuffer = false
        sunMaterial.writesToDepthBuffer = false
        sunGeom.materials = [sunMaterial]
        let sun = SCNNode(geometry: sunGeom)
        sun.position = SCNVector3(0, 3.0, 128)
        sun.renderingOrder = -395
        rootNode.addChildNode(sun)
        sunNode = sun

        // Volumetric god-ray spokes behind the sun, rotating slowly.
        let rayGeom = SCNPlane(width: 96, height: 96)
        let rayMat = SCNMaterial()
        rayMat.lightingModel = .constant
        rayMat.diffuse.contents = Self.sunRaysImage()
        rayMat.emission.contents = Self.sunRaysImage()
        rayMat.blendMode = .add
        rayMat.isDoubleSided = true
        rayMat.readsFromDepthBuffer = false
        rayMat.writesToDepthBuffer = false
        rayGeom.materials = [rayMat]
        let rays = SCNNode(geometry: rayGeom)
        rays.position = SCNVector3(0, 0, 1.5)
        rays.renderingOrder = -398
        rays.runAction(SCNAction.repeatForever(
            SCNAction.rotateBy(x: 0, y: 0, z: .pi * 2, duration: 90)
        ))
        rays.runAction(SCNAction.repeatForever(SCNAction.sequence([
            SCNAction.fadeOpacity(to: 0.55, duration: 4),
            SCNAction.fadeOpacity(to: 0.9, duration: 4)
        ])))
        sun.addChildNode(rays)

        // Mirror-glow streaking downward from the horizon — reads as the
        // sun's reflection on the grid floor.
        let reflGeom = SCNPlane(width: 22, height: 26)
        let reflMat = SCNMaterial()
        reflMat.lightingModel = .constant
        reflMat.diffuse.contents = Self.sunReflectionImage()
        reflMat.emission.contents = Self.sunReflectionImage()
        reflMat.blendMode = .add
        reflMat.isDoubleSided = true
        reflMat.readsFromDepthBuffer = false
        reflMat.writesToDepthBuffer = false
        reflGeom.materials = [reflMat]
        let refl = SCNNode(geometry: reflGeom)
        refl.position = SCNVector3(0, -17, 0.5)
        refl.renderingOrder = -397
        sun.addChildNode(refl)

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

    // MARK: - Procedural sun art

    private static func sunDiscImage() -> UIImage {
        let s = CGSize(width: 320, height: 320)
        return UIGraphicsImageRenderer(size: s).image { ctx in
            let cg = ctx.cgContext
            cg.clear(CGRect(origin: .zero, size: s))
            let center = CGPoint(x: s.width / 2, y: s.height / 2)
            let radius = s.width * 0.46
            let space = CGColorSpaceCreateDeviceRGB()
            let colors = [
                UIColor(hex: "#FFF6C8").cgColor,
                UIColor(hex: "#FFE49A").cgColor,
                UIColor(hex: "#FFC56A").cgColor,
                UIColor(hex: "#F58A4E").withAlphaComponent(0.9).cgColor,
                UIColor(hex: "#F58A4E").withAlphaComponent(0.0).cgColor
            ] as CFArray
            let locs: [CGFloat] = [0, 0.45, 0.72, 0.94, 1.0]
            if let g = CGGradient(colorsSpace: space, colors: colors, locations: locs) {
                cg.drawRadialGradient(g, startCenter: center, startRadius: 0,
                                      endCenter: center, endRadius: radius, options: [])
            }
            // Horizontal cuts across the lower half — thicker toward the
            // bottom, the signature retro sun look.
            cg.setBlendMode(.clear)
            cg.setFillColor(UIColor.clear.cgColor)
            var y = center.y + radius * 0.16
            var thickness: CGFloat = 4
            while y < s.height {
                cg.fill(CGRect(x: 0, y: y, width: s.width, height: thickness))
                y += thickness + max(6, radius * 0.10 - thickness * 0.5)
                thickness += 3
            }
        }
    }

    private static func sunRaysImage() -> UIImage {
        let s = CGSize(width: 512, height: 512)
        return UIGraphicsImageRenderer(size: s).image { ctx in
            let cg = ctx.cgContext
            cg.clear(CGRect(origin: .zero, size: s))
            let center = CGPoint(x: s.width / 2, y: s.height / 2)
            let spokes = 18
            cg.translateBy(x: center.x, y: center.y)
            for i in 0..<spokes {
                let angle = CGFloat(i) * (.pi * 2) / CGFloat(spokes)
                cg.saveGState()
                cg.rotate(by: angle)
                let path = CGMutablePath()
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: -10, y: -s.width * 0.5))
                path.addLine(to: CGPoint(x: 10, y: -s.width * 0.5))
                path.closeSubpath()
                cg.addPath(path)
                cg.setFillColor(UIColor(hex: "#FFE6A8").withAlphaComponent(0.10).cgColor)
                cg.fillPath()
                cg.restoreGState()
            }
        }
    }

    private static func sunReflectionImage() -> UIImage {
        let s = CGSize(width: 256, height: 320)
        return UIGraphicsImageRenderer(size: s).image { ctx in
            let cg = ctx.cgContext
            cg.clear(CGRect(origin: .zero, size: s))
            let space = CGColorSpaceCreateDeviceRGB()
            // Vertical fade: warm at the top (horizon), gone at the bottom.
            let colors = [
                UIColor(hex: "#FFC56A").withAlphaComponent(0.5).cgColor,
                UIColor(hex: "#F58A4E").withAlphaComponent(0.18).cgColor,
                UIColor(hex: "#F58A4E").withAlphaComponent(0.0).cgColor
            ] as CFArray
            if let g = CGGradient(colorsSpace: space, colors: colors, locations: [0, 0.5, 1]) {
                cg.drawLinearGradient(g, start: CGPoint(x: 0, y: 0),
                                      end: CGPoint(x: 0, y: s.height), options: [])
            }
            // Horizontal shimmer cuts (mirror of the sun bands).
            cg.setBlendMode(.clear)
            var y: CGFloat = 10
            var thickness: CGFloat = 7
            while y < s.height {
                cg.fill(CGRect(x: 0, y: y, width: s.width, height: thickness))
                y += thickness + 9
                thickness = max(3, thickness - 0.6)
            }
        }
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
