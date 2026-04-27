//
//  GameViewController.swift
//  StarFox
//

import UIKit
import SceneKit
import SwiftUI

class GameViewController: UIViewController {

    private var scnView: SCNView!
    private var gameScene: GameScene!
    private var hudHosting: UIHostingController<HUDOverlay>?

    private var fireButton: UIButton!
    private var exitButton: UIButton!

    // Touch tracking
    private var lastTouchPoint: CGPoint = .zero

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
        let hud = HUDOverlay(state: gameScene.state)
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

    private func setupControlButtons() {
        fireButton = makeFireButton()
        fireButton.addTarget(self, action: #selector(handleFireTap), for: .touchUpInside)

        exitButton = makeExitButton()
        exitButton.addTarget(self, action: #selector(handleExitTap), for: .touchUpInside)

        view.addSubview(fireButton)
        view.addSubview(exitButton)

        fireButton.translatesAutoresizingMaskIntoConstraints = false
        exitButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            fireButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            fireButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -12),
            fireButton.widthAnchor.constraint(equalToConstant: 60),
            fireButton.heightAnchor.constraint(equalToConstant: 60),

            exitButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 14),
            exitButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            exitButton.widthAnchor.constraint(equalToConstant: 28),
            exitButton.heightAnchor.constraint(equalToConstant: 28)
        ])
    }

    private func makeFireButton() -> UIButton {
        let button = UIButton(type: .system)
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        button.setImage(UIImage(systemName: "scope", withConfiguration: symbolConfig), for: .normal)
        button.tintColor = UIColor.white.withAlphaComponent(0.78)
        button.backgroundColor = UIColor.white.withAlphaComponent(0.14)
        button.layer.cornerRadius = 30
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.22).cgColor
        button.layer.borderWidth = 0.8
        return button
    }

    private func makeExitButton() -> UIButton {
        let button = UIButton(type: .system)
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 10, weight: .semibold)
        button.setImage(UIImage(systemName: "xmark", withConfiguration: symbolConfig), for: .normal)
        button.tintColor = UIColor.white.withAlphaComponent(0.72)
        button.backgroundColor = UIColor.white.withAlphaComponent(0.12)
        button.layer.cornerRadius = 14
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.18).cgColor
        button.layer.borderWidth = 0.8
        return button
    }

    private func bindSceneCallbacks() {
        gameScene.onPhaseChanged = { [weak self] phase in
            self?.applyControls(for: phase)
        }
        applyControls(for: gameScene.state.phase)
    }

    private func applyControls(for phase: GamePhase) {
        let showFire = phase == .playing || phase == .bossEncounter
        let showExit = phase != .menu

        fireButton.isHidden = !showFire
        fireButton.isEnabled = showFire

        exitButton.isHidden = !showExit
        exitButton.isEnabled = showExit
    }

    @objc private func handleFireTap() {
        gameScene.requestFire()
    }

    @objc private func handleExitTap() {
        gameScene.setDragging(false)
        gameScene.requestExitToMenu()
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }

        switch gameScene.state.phase {
        case .menu:
            gameScene.requestStartNewGame()
            return
        case .gameOver:
            gameScene.requestRestartGame()
            return
        case .paused:
            gameScene.requestResumeGame()
            return
        case .playing, .bossEncounter:
            break
        }

        let loc = touch.location(in: view)
        lastTouchPoint = loc
        gameScene.setDragging(true)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first,
              gameScene.state.phase == .playing || gameScene.state.phase == .bossEncounter
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
