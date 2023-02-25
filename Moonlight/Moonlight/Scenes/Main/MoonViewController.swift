//
//  MoonViewController.swift
//  Moonlight
//
//  Created by Gennady Dmitrik on 25.02.23.
//

import UIKit
import AVKit
import AVFAudio
import Combine
import SceneKit
import ARKit

final class MoonViewController: UIViewController {
    fileprivate var viewModel: MoonlightViewModel?
    private let playerLayer = AVPlayerLayer()
    private var player = AVPlayer()
    private let length = 24.0
    private var isInitialLoading = true
    private var speed = 0.0
    private let stepOffset = 0.8127165763
    private var previousPosition = 0.0

    private var arMode = false
    private let configuration = ARWorldTrackingConfiguration()
    private var moonARSceneView = ARSCNView()
    private let moonNode = SCNNode()
    private let directLightNode = SCNNode()

    init(viewModel: MoonlightViewModel) {
        super.init(nibName: nil, bundle: nil)
        self.viewModel = viewModel
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let fileUrl = Bundle.main.url(forResource: "moonVideo", withExtension: "mov")!
        player = AVPlayer(url: fileUrl)
        player.actionAtItemEnd = .none
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(playerLayer)
        setupAR()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        playerLayer.frame = view.bounds
        moonARSceneView.session.run(configuration)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        moonARSceneView.session.pause()
    }

    func updateCurrentMoonPhase() {
        speed = isInitialLoading && (viewModel?.currentMoonPhaseValue ?? 0.0) > 6.5 ? 5.0 : 1.0
        if isInitialLoading {
            previousPosition = getStartPosition()
        }
        var start = previousPosition
        let end = getEndPosition()
        var rate = end > start ? speed : -speed
        if previousPosition > 23 && (viewModel?.currentMoonPhaseValue ?? 0.0) < 1 {
            start = 0.0
            rate = abs(rate)
        } else if (!isInitialLoading) && previousPosition < 0.8 && (viewModel?.currentMoonPhaseValue ?? 0.0) > 28.5 {
            start = length
        }
        previousPosition = end
        let timeToPause = abs((end - start) / rate)
        player.seek(to: CMTime(seconds: start, preferredTimescale: 600))
        player.play()
        player.rate = Float(rate)
        if isInitialLoading {
            isInitialLoading.toggle()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + timeToPause) {
            self.player.pause()
        }

        directLightNode.eulerAngles = SCNVector3(
            0,
            -Float((viewModel?.currentMoonPhaseValue ?? 0) - 14.5) * 0.21,
            0
        )
    }
}

private extension MoonViewController {
    func getStartPosition() -> Double {
        if (viewModel?.currentMoonPhaseValue ?? 0.0) < 2 {
            return 4
        }
        return 0
    }

    func getEndPosition() -> Double {
        (viewModel?.currentMoonPhaseValue ?? 0.0) * stepOffset
    }

    func setupAR() {
        let moonARSelectGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(moonARSelect))
        view.addGestureRecognizer(moonARSelectGestureRecognizer)
        view.addSubview(moonARSceneView)
        moonARSceneView.layer.zPosition = 2
        moonARSceneView.frame = view.bounds
        moonARSceneView.alpha = 0
        moonARSceneView.delegate = self
        let sphere = SCNSphere(radius: 0.8)
        let material = SCNMaterial()
        material.diffuse.contents = UIImage(named: "moonAR.scnassets/8k_moon.jpg")
        sphere.materials = [material]
        moonNode.position = SCNVector3(x: 0, y: 0, z: -3)
        moonNode.geometry = sphere
        moonARSceneView.scene.rootNode.addChildNode(moonNode)
        moonARSceneView.autoenablesDefaultLighting = true
        shadowingMoonAR()
        enableMoonARZoom()
    }

    func shadowingMoonAR() {
        let ambientLightPosition = SCNVector3(x: 0, y: 0, z: 0)
        // Create an ambient light
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light?.shadowMode = .deferred
        ambientLightNode.light?.color = UIColor.white
        ambientLightNode.light?.type = SCNLight.LightType.ambient
        ambientLightNode.position = ambientLightPosition
        moonNode.addChildNode(ambientLightNode)

        let lightPosition = SCNVector3(x: 0, y: 0, z: -3)
        // Create a directional light node with shadow
        directLightNode.light = SCNLight()
        directLightNode.light?.type = SCNLight.LightType.directional
        directLightNode.light?.color = UIColor.white
        directLightNode.light?.castsShadow = true
        directLightNode.light?.automaticallyAdjustsShadowProjection = true
        directLightNode.light?.shadowSampleCount = 64
        directLightNode.light?.shadowRadius = 16
        directLightNode.light?.shadowMode = .deferred
        directLightNode.light?.shadowMapSize = CGSize(width: 2048, height: 2048)
        directLightNode.light?.shadowColor = UIColor.black.withAlphaComponent(0.9)
        directLightNode.position = lightPosition

        // Add the lights to the container
        moonNode.addChildNode(directLightNode)
    }

    func enableMoonARZoom() {
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(startZooming(_:)))
        moonARSceneView.addGestureRecognizer(pinchGesture)
      }

      @objc func startZooming(_ sender: UIPinchGestureRecognizer) {
          guard
            let sphere = moonNode.geometry as? SCNSphere,
            sender.scale > 0 && sender.scale < 2
          else { return }
          sphere.radius = sender.scale
      }

    @objc func moonARSelect() {
        arMode.toggle()
        UIView.animate(withDuration: 0.5, delay: 0.0, options: UIView.AnimationOptions(), animations: {
            self.moonARSceneView.alpha = self.arMode ? 1.0 : 0.0
        }, completion: { _ in })
    }
}


extension MoonViewController: ARSCNViewDelegate {
    func session(_ session: ARSession, didFailWithError error: Error) {}

    func sessionWasInterrupted(_ session: ARSession) {}

    func sessionInterruptionEnded(_ session: ARSession) {}
}
