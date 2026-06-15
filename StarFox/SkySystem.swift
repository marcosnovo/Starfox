//
//  SkySystem.swift
//  StarFox
//
//  Alto's Adventure-style atmospheric sky.
//
//  Slow dawn → day → dusk → night cycle, clean 3-stop gradient
//  background (no harsh bands), a single soft sun/moon disc
//  (no Outrun horizontal cuts, no god rays, no horizon reflection),
//  and three matching lights (ambient + warm sun key + cool fill).
//

import SceneKit
import UIKit

struct SkyPreset {
    let phase: AltoVisualStyle.ScenePhase
    let skyTop: UIColor
    let skyMid: UIColor
    let skyHorizon: UIColor
    let sunCore: UIColor
    let sunHalo: UIColor
    let ambientColor: UIColor
    let ambientIntensity: CGFloat
    let keyColor: UIColor
    let keyIntensity: CGFloat
    let fillColor: UIColor
    let fillIntensity: CGFloat
    let fogColor: UIColor
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

final class SkySystem {
    private let rootNode: SCNNode

    private(set) var ambientLightNode: SCNNode?
    private(set) var keyLightNode: SCNNode?
    private(set) var fillLightNode: SCNNode?

    private(set) var currentPalette: SkyPreset?

    private var sunNode: SCNNode?
    private var sunMaterial: SCNMaterial?
    private weak var scene: SCNScene?

    private var skyCycleTime: TimeInterval = 0
    private let skyCycleDuration: TimeInterval = AltoVisualStyle.defaultSkyCycleDuration

    // Sky regeneration is throttled — drawing the gradient texture every
    // frame is unnecessary; lights interpolate continuously and the
    // background only needs a refresh every couple of seconds.
    private var skyRegenAccumulator: TimeInterval = 0
    private let skyRegenInterval: TimeInterval = 1.2

    var presets: [SkyPreset] {
        [
            // Dawn — cool indigo overhead, peach horizon.
            SkyPreset(
                phase: .dawn,
                skyTop:     UIColor(hex: "#2B2748"),
                skyMid:     UIColor(hex: "#7E4B6B"),
                skyHorizon: UIColor(hex: "#F2B79E"),
                sunCore:    UIColor(hex: "#FFE6C2"),
                sunHalo:    UIColor(hex: "#F7B07A"),
                ambientColor: UIColor(hex: "#6B5470"), ambientIntensity: 240,
                keyColor:     UIColor(hex: "#F2B79E"), keyIntensity:     480,
                fillColor:    UIColor(hex: "#5C7A99"), fillIntensity:    180,
                fogColor:     UIColor(hex: "#E5B099")
            ),
            // Day — blue sky, soft haze horizon.
            SkyPreset(
                phase: .day,
                skyTop:     UIColor(hex: "#4A6E92"),
                skyMid:     UIColor(hex: "#B6CCD8"),
                skyHorizon: UIColor(hex: "#E8D9BD"),
                sunCore:    UIColor(hex: "#FFF8DE"),
                sunHalo:    UIColor(hex: "#FFE7A3"),
                ambientColor: UIColor(hex: "#BCD0DE"), ambientIntensity: 280,
                keyColor:     UIColor(hex: "#FFF1C8"), keyIntensity:     520,
                fillColor:    UIColor(hex: "#D7C39A"), fillIntensity:    200,
                fogColor:     UIColor(hex: "#BAA993")
            ),
            // Dusk — deep purple top, rose mid, glowing orange horizon.
            SkyPreset(
                phase: .dusk,
                skyTop:     UIColor(hex: "#3F2E48"),
                skyMid:     UIColor(hex: "#B05E5E"),
                skyHorizon: UIColor(hex: "#F0935A"),
                sunCore:    UIColor(hex: "#FFDB8F"),
                sunHalo:    UIColor(hex: "#F0935A"),
                ambientColor: UIColor(hex: "#7A4A4E"), ambientIntensity: 220,
                keyColor:     UIColor(hex: "#F0935A"), keyIntensity:     560,
                fillColor:    UIColor(hex: "#5A4970"), fillIntensity:    180,
                fogColor:     UIColor(hex: "#B45E5E")
            ),
            // Night — near-black blue top, navy mid, twilight horizon, moon.
            SkyPreset(
                phase: .night,
                skyTop:     UIColor(hex: "#0E1024"),
                skyMid:     UIColor(hex: "#1B2240"),
                skyHorizon: UIColor(hex: "#3F3E58"),
                sunCore:    UIColor(hex: "#DEE6FA"),
                sunHalo:    UIColor(hex: "#A6B0CE"),
                ambientColor: UIColor(hex: "#1F2A40"), ambientIntensity: 160,
                keyColor:     UIColor(hex: "#C8D0E6"), keyIntensity:     220,
                fillColor:    UIColor(hex: "#1A2C44"), fillIntensity:    120,
                fogColor:     UIColor(hex: "#1A2233")
            )
        ]
    }

    init(rootNode: SCNNode) {
        self.rootNode = rootNode
    }

    func setupBackground(scene: SCNScene) {
        self.scene = scene
        // Start the loop a third of the way into dusk — the most
        // recognisable Alto's-style opening.
        skyCycleTime = skyCycleDuration * 0.50
        let preset = presets[2]
        currentPalette = preset
        scene.background.contents = makeSkyBackgroundImage(
            top: preset.skyTop, mid: preset.skyMid, horizon: preset.skyHorizon
        )
        scene.fogColor = preset.fogColor
        scene.fogStartDistance = 140
        scene.fogEndDistance   = 360
        scene.fogDensityExponent = 0.35
    }

    func setupLighting(scene: SCNScene) {
        self.scene = scene
        let preset = currentPalette ?? presets[2]

        // IBL off — Alto's reads as flat shapes; IBL only muddies the silhouettes.
        scene.lightingEnvironment.contents = nil
        scene.lightingEnvironment.intensity = 0

        let ambient = SCNNode()
        let al = SCNLight()
        al.type = .ambient
        al.color = preset.ambientColor
        al.intensity = preset.ambientIntensity
        ambient.light = al
        rootNode.addChildNode(ambient)
        ambientLightNode = ambient

        // Warm sun key — raking down from above, toward the camera.
        let key = SCNNode()
        let keyLight = SCNLight()
        keyLight.type = .directional
        keyLight.color = preset.keyColor
        keyLight.intensity = preset.keyIntensity
        keyLight.castsShadow = false
        key.light = keyLight
        key.eulerAngles = SCNVector3(-0.55, 0, 0)
        rootNode.addChildNode(key)
        keyLightNode = key

        // Cool counter-fill raking up from below, keeping undersides legible
        // against the bright horizon band.
        let fill = SCNNode()
        let fillLight = SCNLight()
        fillLight.type = .directional
        fillLight.color = preset.fillColor
        fillLight.intensity = preset.fillIntensity
        fillLight.castsShadow = false
        fill.light = fillLight
        fill.eulerAngles = SCNVector3(Float.pi - 0.40, 0, 0)
        rootNode.addChildNode(fill)
        fillLightNode = fill
    }

    func setupSunNodes() {
        sunNode?.removeFromParentNode()

        let preset = currentPalette ?? presets[2]

        // Single soft disc — no horizontal cuts, no spokes, no reflection.
        let geom = SCNPlane(width: 18, height: 18)
        let mat = SCNMaterial()
        mat.lightingModel = .constant
        let img = Self.sunDiscImage(core: preset.sunCore, halo: preset.sunHalo)
        mat.diffuse.contents = img
        mat.emission.contents = img
        mat.blendMode = .alpha
        mat.isDoubleSided = true
        mat.readsFromDepthBuffer = false
        mat.writesToDepthBuffer = false
        geom.materials = [mat]
        let sun = SCNNode(geometry: geom)
        sun.position = SCNVector3(0, 3.0, 128)
        sun.renderingOrder = -395
        rootNode.addChildNode(sun)
        sunNode = sun
        sunMaterial = mat
    }

    func update(dt: TimeInterval, shipPosition: SCNVector3, weatherPreset: WeatherPreset) {
        skyCycleTime += dt
        skyRegenAccumulator += dt
        let duration = max(120.0, skyCycleDuration)
        let phaseProgress = (skyCycleTime.truncatingRemainder(dividingBy: duration)) / duration

        let skyPresets = presets
        let segmentCount = skyPresets.count
        let scaled = phaseProgress * Double(segmentCount)
        let indexA = Int(floor(scaled)) % segmentCount
        let indexB = (indexA + 1) % segmentCount
        let localT = CGFloat(scaled - floor(scaled))
        let easedT = AltoVisualStyle.calmEase(localT)

        let a = skyPresets[indexA]
        let b = skyPresets[indexB]

        let blended = SkyPreset(
            phase: easedT < 0.5 ? a.phase : b.phase,
            skyTop:     UIColor.lerp(from: a.skyTop,     to: b.skyTop,     t: easedT),
            skyMid:     UIColor.lerp(from: a.skyMid,     to: b.skyMid,     t: easedT),
            skyHorizon: UIColor.lerp(from: a.skyHorizon, to: b.skyHorizon, t: easedT),
            sunCore:    UIColor.lerp(from: a.sunCore,    to: b.sunCore,    t: easedT),
            sunHalo:    UIColor.lerp(from: a.sunHalo,    to: b.sunHalo,    t: easedT),
            ambientColor: UIColor.lerp(from: a.ambientColor, to: b.ambientColor, t: easedT),
            ambientIntensity: CGFloat.lerp(from: a.ambientIntensity, to: b.ambientIntensity, t: easedT),
            keyColor:    UIColor.lerp(from: a.keyColor,  to: b.keyColor,  t: easedT),
            keyIntensity: CGFloat.lerp(from: a.keyIntensity, to: b.keyIntensity, t: easedT),
            fillColor:   UIColor.lerp(from: a.fillColor, to: b.fillColor, t: easedT),
            fillIntensity: CGFloat.lerp(from: a.fillIntensity, to: b.fillIntensity, t: easedT),
            fogColor:    UIColor.lerp(from: a.fogColor,  to: b.fogColor,  t: easedT)
        )
        currentPalette = blended

        let weatheredTop     = blended.skyTop.multiplied(by: weatherPreset.skyTopTint)
        let weatheredHorizon = blended.skyHorizon.multiplied(by: weatherPreset.skyBottomTint)
        let weatheredMid     = UIColor.lerp(from: blended.skyMid,
                                            to: weatherPreset.skyTopTint,
                                            t: 0.25)

        let ambientColor = blended.ambientColor.multiplied(by: weatherPreset.ambientTint)
        let keyColor     = blended.keyColor.multiplied(by: weatherPreset.keyTint)
        let fillColor    = blended.fillColor.multiplied(by: weatherPreset.fillTint)
        let ambientIntensity = blended.ambientIntensity * weatherPreset.ambientIntensityMultiplier
        let keyIntensity     = blended.keyIntensity     * weatherPreset.keyIntensityMultiplier
        let fillIntensity    = blended.fillIntensity    * weatherPreset.fillIntensityMultiplier

        sunNode?.position = SCNVector3(
            shipPosition.x * 0.03,
            2.5 + shipPosition.y * 0.012,
            shipPosition.z + 128
        )
        if let mat = sunMaterial {
            let img = Self.sunDiscImage(core: blended.sunCore, halo: blended.sunHalo)
            mat.diffuse.contents = img
            mat.emission.contents = img
        }

        if let scene = scene {
            scene.fogColor = blended.fogColor
            if skyRegenAccumulator >= skyRegenInterval {
                skyRegenAccumulator = 0
                scene.background.contents = makeSkyBackgroundImage(
                    top: weatheredTop, mid: weatheredMid, horizon: weatheredHorizon
                )
            }
        }

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
        // Keep starting at the dusk opening rather than snapping to dawn.
        skyCycleTime = skyCycleDuration * 0.50
        skyRegenAccumulator = skyRegenInterval   // force a refresh next update.
    }

    // MARK: - Procedural sun art

    private static func sunDiscImage(core: UIColor, halo: UIColor) -> UIImage {
        let s = CGSize(width: 256, height: 256)
        return UIGraphicsImageRenderer(size: s).image { ctx in
            let cg = ctx.cgContext
            cg.clear(CGRect(origin: .zero, size: s))
            let center = CGPoint(x: s.width / 2, y: s.height / 2)
            let radius = s.width * 0.48
            let space = CGColorSpaceCreateDeviceRGB()
            let colors = [
                core.cgColor,
                core.withAlphaComponent(0.92).cgColor,
                halo.withAlphaComponent(0.45).cgColor,
                halo.withAlphaComponent(0.0).cgColor
            ] as CFArray
            let locs: [CGFloat] = [0.0, 0.34, 0.72, 1.0]
            if let g = CGGradient(colorsSpace: space, colors: colors, locations: locs) {
                cg.drawRadialGradient(g, startCenter: center, startRadius: 0,
                                      endCenter: center, endRadius: radius, options: [])
            }
        }
    }

    // MARK: - Sky background image

    private func makeSkyBackgroundImage(top: UIColor, mid: UIColor, horizon: UIColor) -> UIImage {
        let w = 128
        let h = 512
        let size = CGSize(width: w, height: h)
        return UIGraphicsImageRenderer(size: size).image { ctx in
            let cg = ctx.cgContext
            let space = CGColorSpaceCreateDeviceRGB()

            // Three soft stops — Alto's-style atmospheric gradient.
            let colors = [
                top.cgColor,
                mid.cgColor,
                horizon.cgColor,
                horizon.blended(with: .black, t: 0.25).cgColor
            ] as CFArray
            let locs: [CGFloat] = [0.00, 0.55, 0.88, 1.00]
            if let g = CGGradient(colorsSpace: space, colors: colors, locations: locs) {
                cg.drawLinearGradient(
                    g,
                    start: CGPoint(x: 0, y: 0),
                    end: CGPoint(x: 0, y: CGFloat(h)),
                    options: []
                )
            }
        }
    }
}
