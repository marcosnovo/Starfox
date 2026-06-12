//
//  GameViewController.swift
//  StarFox
//
//  Touch layout: drag anywhere to steer the Arwing. Right thumb cluster
//  fires (hold for autofire), barrel-rolls and drops smart bombs; left
//  thumb cluster boosts and brakes against the shared boost gauge.
//

import UIKit
import SceneKit
import SwiftUI

class GameViewController: UIViewController {

    private var scnView: SCNView!
    private var gameScene: GameScene!
    private var hudHosting: UIHostingController<HUDOverlay>?

    private var fireButton: UIButton!
    private var rollButton: UIButton!
    private var bombButton: UIButton!
    private var boostButton: UIButton!
    private var brakeButton: UIButton!
    private var pauseButton: UIButton!
    private var exitButton: UIButton!

    private var combatButtons: [UIButton] {
        [fireButton, rollButton, bombButton, boostButton, brakeButton, pauseButton]
    }

    // Touch tracking
    private var lastTouchPoint: CGPoint = .zero
    private var lastCombatTapTime: TimeInterval = 0

    // Phase mirrored from the scene on the main thread, so touch handling
    // never reads render-thread state directly.
    private var currentPhase: GamePhase = .menu
    private var phaseChangedAt: TimeInterval = CACurrentMediaTime()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSceneView()
        setupGame()
        setupHUD()
        setupControlButtons()
        bindSceneCallbacks()
    }

    private func setupSceneView() {
        scnView = SCNView(frame: view.bounds)
        scnView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scnView.antialiasingMode = .multisampling4X
        scnView.showsStatistics = false
        scnView.backgroundColor = .black
        scnView.isPlaying = true
        view.addSubview(scnView)
    }

    private func setupGame() {
        gameScene = GameScene()
        gameScene.setup()
        scnView.scene = gameScene
        scnView.delegate = gameScene
        scnView.pointOfView = gameScene.cameraNode
    }

    private func setupHUD() {
        let hud = HUDOverlay(state: gameScene.hud)
        let hosting = UIHostingController(rootView: hud)
        hosting.view.backgroundColor = .clear
        hosting.view.frame = view.bounds
        hosting.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        hosting.view.isUserInteractionEnabled = false
        addChild(hosting)
        view.addSubview(hosting.view)
        hosting.didMove(toParent: self)
        hudHosting = hosting
    }

    // MARK: - Controls

    private func setupControlButtons() {
        fireButton = makeControlButton(title: "FIRE", diameter: 74, emphasized: true)
        rollButton = makeControlButton(title: "ROLL", diameter: 54)
        bombButton = makeControlButton(title: "BOMB", diameter: 54)
        boostButton = makeControlButton(title: "BST", diameter: 54)
        brakeButton = makeControlButton(title: "BRK", diameter: 54)
        pauseButton = makeSmallButton(symbol: "pause")
        exitButton = makeSmallButton(symbol: "xmark")

        // Hold-style controls.
        fireButton.addTarget(self, action: #selector(handleFireDown), for: .touchDown)
        fireButton.addTarget(self, action: #selector(handleFireUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        boostButton.addTarget(self, action: #selector(handleBoostDown), for: .touchDown)
        boostButton.addTarget(self, action: #selector(handleBoostUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        brakeButton.addTarget(self, action: #selector(handleBrakeDown), for: .touchDown)
        brakeButton.addTarget(self, action: #selector(handleBrakeUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])

        // Tap-style controls.
        rollButton.addTarget(self, action: #selector(handleRollTap), for: .touchDown)
        bombButton.addTarget(self, action: #selector(handleBombTap), for: .touchUpInside)
        pauseButton.addTarget(self, action: #selector(handlePauseTap), for: .touchUpInside)
        exitButton.addTarget(self, action: #selector(handleExitTap), for: .touchUpInside)

        for button in [fireButton, rollButton, bombButton, boostButton, brakeButton, pauseButton, exitButton] {
            view.addSubview(button!)
            button!.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            // Right thumb cluster: FIRE with ROLL above and BOMB inboard.
            fireButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -14),
            fireButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -14),
            fireButton.widthAnchor.constraint(equalToConstant: 74),
            fireButton.heightAnchor.constraint(equalToConstant: 74),

            rollButton.trailingAnchor.constraint(equalTo: fireButton.trailingAnchor),
            rollButton.bottomAnchor.constraint(equalTo: fireButton.topAnchor, constant: -12),
            rollButton.widthAnchor.constraint(equalToConstant: 54),
            rollButton.heightAnchor.constraint(equalToConstant: 54),

            bombButton.trailingAnchor.constraint(equalTo: fireButton.leadingAnchor, constant: -12),
            bombButton.bottomAnchor.constraint(equalTo: fireButton.bottomAnchor),
            bombButton.widthAnchor.constraint(equalToConstant: 54),
            bombButton.heightAnchor.constraint(equalToConstant: 54),

            // Left thumb cluster: BOOST over BRAKE.
            brakeButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 14),
            brakeButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -14),
            brakeButton.widthAnchor.constraint(equalToConstant: 54),
            brakeButton.heightAnchor.constraint(equalToConstant: 54),

            boostButton.leadingAnchor.constraint(equalTo: brakeButton.leadingAnchor),
            boostButton.bottomAnchor.constraint(equalTo: brakeButton.topAnchor, constant: -12),
            boostButton.widthAnchor.constraint(equalToConstant: 54),
            boostButton.heightAnchor.constraint(equalToConstant: 54),

            pauseButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -14),
            pauseButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            pauseButton.widthAnchor.constraint(equalToConstant: 28),
            pauseButton.heightAnchor.constraint(equalToConstant: 28),

            exitButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 14),
            exitButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            exitButton.widthAnchor.constraint(equalToConstant: 28),
            exitButton.heightAnchor.constraint(equalToConstant: 28)
        ])
    }

    private func makeControlButton(title: String, diameter: CGFloat, emphasized: Bool = false) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .monospacedSystemFont(ofSize: emphasized ? 13 : 11, weight: .bold)
        let accent = UIColor(red: 0.95, green: 0.58, blue: 0.33, alpha: 1)
        button.setTitleColor(emphasized ? accent : UIColor.white.withAlphaComponent(0.80), for: .normal)
        button.backgroundColor = UIColor.white.withAlphaComponent(emphasized ? 0.16 : 0.12)
        button.layer.cornerRadius = diameter / 2
        button.layer.borderColor = (emphasized
            ? accent.withAlphaComponent(0.45)
            : UIColor.white.withAlphaComponent(0.22)).cgColor
        button.layer.borderWidth = 1.0
        return button
    }

    private func makeSmallButton(symbol: String) -> UIButton {
        let button = UIButton(type: .system)
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 10, weight: .semibold)
        button.setImage(UIImage(systemName: symbol, withConfiguration: symbolConfig), for: .normal)
        button.tintColor = UIColor.white.withAlphaComponent(0.72)
        button.backgroundColor = UIColor.white.withAlphaComponent(0.12)
        button.layer.cornerRadius = 14
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.18).cgColor
        button.layer.borderWidth = 0.8
        return button
    }

    private func bindSceneCallbacks() {
        gameScene.onPhaseChanged = { [weak self] phase in
            guard let self else { return }
            self.currentPhase = phase
            self.phaseChangedAt = CACurrentMediaTime()
            self.applyControls(for: phase)
        }
        applyControls(for: currentPhase)
    }

    private func applyControls(for phase: GamePhase) {
        let inCombat = phase == .playing || phase == .bossEncounter
        for button in combatButtons {
            button.isHidden = !inCombat
            button.isEnabled = inCombat
        }
        if !inCombat {
            // Make sure no held control stays latched across phase changes.
            gameScene.setFiring(false)
            gameScene.setBoosting(false)
            gameScene.setBraking(false)
        }

        let showExit = phase != .menu
        exitButton.isHidden = !showExit
        exitButton.isEnabled = showExit
    }

    // MARK: - Button actions

    @objc private func handleFireDown() { gameScene.setFiring(true) }
    @objc private func handleFireUp() { gameScene.setFiring(false) }
    @objc private func handleBoostDown() { gameScene.setBoosting(true) }
    @objc private func handleBoostUp() { gameScene.setBoosting(false) }
    @objc private func handleBrakeDown() { gameScene.setBraking(true) }
    @objc private func handleBrakeUp() { gameScene.setBraking(false) }
    @objc private func handleRollTap() { gameScene.requestBarrelRoll() }
    @objc private func handleBombTap() { gameScene.requestBomb() }
    @objc private func handlePauseTap() { gameScene.requestPauseGame() }

    @objc private func handleExitTap() {
        gameScene.setDragging(false)
        gameScene.setFiring(false)
        gameScene.setBoosting(false)
        gameScene.setBraking(false)
        gameScene.requestExitToMenu()
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }

        switch currentPhase {
        case .menu:
            gameScene.requestStartNewGame()
            return
        case .gameOver:
            // Small grace period so mashing FIRE while dying doesn't skip
            // the game-over screen instantly.
            if CACurrentMediaTime() - phaseChangedAt > 0.8 {
                gameScene.requestRestartGame()
            }
            return
        case .paused:
            gameScene.requestResumeGame()
            return
        case .levelIntro, .levelComplete:
            return
        case .playing, .bossEncounter:
            break
        }

        // Quick double tap anywhere = barrel roll (classic).
        let now = CACurrentMediaTime()
        if now - lastCombatTapTime < 0.28 {
            lastCombatTapTime = 0
            gameScene.requestBarrelRoll()
        } else {
            lastCombatTapTime = now
        }

        let loc = touch.location(in: view)
        lastTouchPoint = loc
        gameScene.setDragging(true)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first,
              currentPhase == .playing || currentPhase == .bossEncounter
        else { return }

        let loc = touch.location(in: view)
        let delta = CGPoint(
            x: loc.x - lastTouchPoint.x,
            y: loc.y - lastTouchPoint.y
        )
        gameScene.enqueueDragDelta(delta)
        lastTouchPoint = loc
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        gameScene.setDragging(false)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        gameScene.setDragging(false)
    }

    // MARK: - Orientation / Status Bar

    override var prefersStatusBarHidden: Bool { true }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        UIDevice.current.userInterfaceIdiom == .phone ? .landscape : .all
    }
}
