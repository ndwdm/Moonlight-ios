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
import GoogleMobileAds
import SnapKit

enum MoonMode {
    case main
    case ar
}

final class MoonViewController: UIViewController {
    fileprivate var viewModel: MoonlightViewModel?
    let googleADBannerID = ""

    private var bannerView: BannerView?

    private var arMode = false
    private let configuration = ARWorldTrackingConfiguration()

    private var mainMoonSceneView = SCNView()
    private let moonNode = SCNNode()

    private var arMoonSceneView = ARSCNView()
    private let moonARNode = SCNNode()

    private let lightPosition = SCNVector3(x: 0, y: 0, z: -3)
    private var directLightNode = SCNNode()
    private var directARLightNode = SCNNode()

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
        setupViews()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSceneWillEnterForeground),
            name: UIScene.willEnterForegroundNotification,
            object: nil
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        arMoonSceneView.session.run(configuration)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        arMoonSceneView.session.pause()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func updateCurrentMoonPhase() {
        animatePhaseLightChange(with: viewModel?.currentMoonPhaseValue ?? 0)
    }

    // MARK: - Actions

    @objc private func handleSceneWillEnterForeground(_ notification: Notification) {
        AppOpenAdManager.shared.showAdIfAvailable()
    }
}

private extension MoonViewController {
    func setupViews() {
        setupScene()
        setupAR()
        enableMoonZoom()

        setupGoogleBannerAd()
    }

    func setupScene() {
        let moonModeSelectGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(moonModeSelect))
        view.addGestureRecognizer(moonModeSelectGestureRecognizer)

        setupMoon(for: moonNode, with: 1.2)
        shadowingMoon(for: moonNode, mode: .main)

        mainMoonSceneView = SCNView(frame: .init(x: 0, y: 0, width: view.frame.width, height: view.frame.height / 2))
        view.addSubview(mainMoonSceneView)
        mainMoonSceneView.layer.zPosition = 5

        let scene = SCNScene()
        mainMoonSceneView.scene = scene
        mainMoonSceneView.backgroundColor = .black

        let camera = SCNCamera()
        let cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(x: 0.0, y: 0.0, z: 0.0)

        let constraint = SCNLookAtConstraint(target: moonNode)
        constraint.isGimbalLockEnabled = true
        cameraNode.constraints = [constraint]

        scene.rootNode.addChildNode(cameraNode)
        scene.rootNode.addChildNode(moonNode)

        animatePlaneKey(nodeToAnimate: moonNode)
    }

    func setupAR() {
        setupMoon(for: moonARNode, with: 0.8)
        shadowingMoon(for: moonARNode, mode: .ar)
        view.addSubview(arMoonSceneView)
        arMoonSceneView.layer.zPosition = 4
        arMoonSceneView.frame = view.bounds
        arMoonSceneView.alpha = 0
        arMoonSceneView.delegate = self
        arMoonSceneView.scene.rootNode.addChildNode(moonARNode)
        arMoonSceneView.autoenablesDefaultLighting = true
    }

    func setupMoon(for node: SCNNode, with radius: Double) {
        let sphere = SCNSphere(radius: radius)
        let material = SCNMaterial()
        material.diffuse.contents = UIImage(named: "moonAR.scnassets/8k_moon.jpg")
        sphere.materials = [material]
        node.position = SCNVector3(x: 0, y: 0, z: -3)
        node.geometry = sphere
    }

    func shadowingMoon(for node: SCNNode, mode: MoonMode) {
        let ambientLightPosition = SCNVector3(x: 0, y: 0, z: 0)
        // Create an ambient light
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light?.shadowMode = .deferred
        ambientLightNode.light?.color = UIColor.white.withAlphaComponent(0.3)
        ambientLightNode.light?.type = SCNLight.LightType.ambient
        ambientLightNode.light?.intensity = 400
        ambientLightNode.position = ambientLightPosition
        node.addChildNode(ambientLightNode)

        // Create a directional light node with shadow
        setupDirectLight(for: &directLightNode)
        setupDirectLight(for: &directARLightNode)

        // Add the lights to the container
        node.addChildNode(mode == .main ? directLightNode : directARLightNode)
    }

    func setupDirectLight(for node: inout SCNNode) {
        // Create a directional light node with shadow
        node.light = SCNLight()
        node.light?.type = SCNLight.LightType.directional
        node.light?.color = UIColor.white
        node.light?.castsShadow = true
        node.light?.automaticallyAdjustsShadowProjection = true
        node.light?.shadowSampleCount = 64
        node.light?.shadowRadius = 16
        node.light?.shadowMode = .deferred
        node.light?.shadowMapSize = CGSize(width: 2048, height: 2048)
        node.light?.shadowColor = UIColor.black.withAlphaComponent(0.9)
        node.position = lightPosition
    }

    func enableMoonZoom() {
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(startZooming(_:)))
        mainMoonSceneView.addGestureRecognizer(pinchGesture)
        let pinchARGesture = UIPinchGestureRecognizer(target: self, action: #selector(startARZooming(_:)))
        arMoonSceneView.addGestureRecognizer(pinchARGesture)
    }

    @objc func startZooming(_ sender: UIPinchGestureRecognizer) {
        guard
            let sphere = moonNode.geometry as? SCNSphere,
            sender.scale > 0 && sender.scale < 2
        else { return }
        sphere.radius = sender.scale
    }

    @objc func startARZooming(_ sender: UIPinchGestureRecognizer) {
        guard
            let sphere = moonARNode.geometry as? SCNSphere,
            sender.scale > 0 && sender.scale < 2
        else { return }
        sphere.radius = sender.scale
    }

    @objc func moonModeSelect() {
        arMode.toggle()
        UIView.animate(withDuration: 0.5, delay: 0.0, options: UIView.AnimationOptions(), animations: {
            self.mainMoonSceneView.alpha = self.arMode ? 0.0 : 1.0
            self.arMoonSceneView.alpha = self.arMode ? 1.0 : 0.0
        }, completion: { _ in
            self.mainMoonSceneView.isHidden = self.arMode
        })
    }

    func animatePlaneKey(nodeToAnimate: SCNNode) {
//        let animation2 = CAKeyframeAnimation(keyPath: "rotation")
        let pos1rot = SCNVector4(0, 0, 0, 0)
        let pos2rot = SCNVector4(0, 1, 0, CGFloat(Float.pi / 2))
//        animation2.values = [pos1rot, pos2rot]
//        animation2.keyTimes = [0, 1]
//        animation2.duration = 500
//        animation2.repeatCount = .infinity

//        nodeToAnimate.addAnimation(animation2, forKey: "spin around")
    }

    func animatePhaseLightChange(with angle: Double) {
        let newVector = SCNVector3(
            0,
            -Float(angle - 14.5) * 0.21,
            0
        )
        directLightNode.eulerAngles = newVector
        directARLightNode.eulerAngles = newVector
    }

    func setupGoogleBannerAd() {
        let viewWidth = view.frame.inset(by: view.safeAreaInsets).width
        let adaptiveSize = currentOrientationAnchoredAdaptiveBanner(width: viewWidth)
        bannerView = BannerView(adSize: adaptiveSize)
        bannerView?.adUnitID = googleADBannerID
        bannerView?.rootViewController = self
        bannerView?.load(Request())

        guard let bannerView else { return }

        view.addSubview(bannerView)

        bannerView.layer.zPosition = 11
        bannerView.frame.origin.y = view.frame.height - 100
        bannerView.center.x = view.center.x
    }
}


extension MoonViewController: ARSCNViewDelegate {
    func session(_ session: ARSession, didFailWithError error: Error) {}

    func sessionWasInterrupted(_ session: ARSession) {}

    func sessionInterruptionEnded(_ session: ARSession) {}
}

extension MoonViewController: BannerViewDelegate {
    func bannerViewDidReceiveAd(_ bannerView: BannerView) {
        print(">>: bannerViewDidReceiveAd")
    }

    func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
        print(">>: bannerView:didFailToReceiveAdWithError: \(error.localizedDescription)")
    }

    func bannerViewDidRecordImpression(_ bannerView: BannerView) {
        print(">>: bannerViewDidRecordImpression")
    }

    func bannerViewWillPresentScreen(_ bannerView: BannerView) {
        print(">>: bannerViewWillPresentScreen")
    }

    func bannerViewWillDismissScreen(_ bannerView: BannerView) {
        print(">>: bannerViewWillDIsmissScreen")
    }

    func bannerViewDidDismissScreen(_ bannerView: BannerView) {
        print(">>: bannerViewDidDismissScreen")
    }
}
