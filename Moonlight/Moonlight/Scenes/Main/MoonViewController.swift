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
import YandexMobileAds

enum MoonMode {
    case main
    case ar
}

final class MoonViewController: UIViewController {
    fileprivate var viewModel: MoonlightViewModel?
    let adBannerID = "ca-app-pub-7596340865562529/5693808324"
    let testADBannerID = "ca-app-pub-3940256099942544/2934735716" // special google test id for banners
    let yandexAppID = "2753133"
    let yandexADBannerID = "R-M-2753133-1"

    private var bannerView: GADBannerView!
    private let yandexADView: YMANativeBannerView = {
        let adView = YMANativeBannerView()
        return adView
    }()
    private lazy var adLoader: YMANativeAdLoader = {
        let adLoader = YMANativeAdLoader()
        adLoader.delegate = self
        return adLoader
    }()

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
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        arMoonSceneView.session.run(configuration)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        arMoonSceneView.session.pause()
    }

    func updateCurrentMoonPhase() {
        animatePhaseLightChange(with: viewModel?.currentMoonPhaseValue ?? 0)
    }
}

private extension MoonViewController {
    func setupViews() {
        setupScene()
        setupAR()
        enableMoonZoom()

        setupGoogleBannerAd()
        setupYandexNativeBannerAd()
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
        ambientLightNode.light?.color = UIColor.white
        ambientLightNode.light?.type = SCNLight.LightType.ambient
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
        let animation2 = CAKeyframeAnimation(keyPath: "rotation")
        let pos1rot = SCNVector4(0, 0, 0, 0)
        let pos2rot = SCNVector4(0, 1, 0, CGFloat(Float.pi / 2))
        animation2.values = [pos1rot, pos2rot]
        animation2.keyTimes = [0, 1]
        animation2.duration = 200
        animation2.repeatCount = .infinity
        animation2.isAdditive = true

        nodeToAnimate.addAnimation(animation2, forKey: "spin around")
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

    func addBannerViewToView(_ bannerView: GADBannerView) {
        view.addSubview(bannerView)
        bannerView.layer.zPosition = 10
        bannerView.frame.origin.y = view.frame.height - 220
        bannerView.center.x = view.center.x
       }

    func setupGoogleBannerAd() {
        bannerView = GADBannerView(adSize: GADAdSizeBanner)
        addBannerViewToView(bannerView)
        bannerView.adUnitID = adBannerID // testADBannerID
        bannerView.rootViewController = self
        bannerView.delegate = self
        bannerView.load(GADRequest())
    }

    func setupYandexNativeBannerAd() {
        let requestConfiguration = YMANativeAdRequestConfiguration(adUnitID: yandexADBannerID)
        adLoader.loadAd(with: requestConfiguration)

        view.addSubview(yandexADView)
        yandexADView.frame.size.width = view.frame.size.width
        yandexADView.frame.origin.y = view.frame.height - 160
        yandexADView.center.x = view.center.x
    }

    func bindNativeAd(_ ad: YMANativeAd) {
        ad.delegate = self
        yandexADView.ad = ad
    }
}


extension MoonViewController: ARSCNViewDelegate {
    func session(_ session: ARSession, didFailWithError error: Error) {}

    func sessionWasInterrupted(_ session: ARSession) {}

    func sessionInterruptionEnded(_ session: ARSession) {}
}

extension MoonViewController: GADBannerViewDelegate {
    func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
        bannerView.alpha = 0
        UIView.animate(withDuration: 1, animations: {
            bannerView.alpha = 1
        })
    }

    func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
        print("bannerView:didFailToReceiveAdWithError: \(error.localizedDescription)")
    }

    func bannerViewDidRecordImpression(_ bannerView: GADBannerView) {}

    func bannerViewWillPresentScreen(_ bannerView: GADBannerView) {}

    func bannerViewWillDismissScreen(_ bannerView: GADBannerView) {}

    func bannerViewDidDismissScreen(_ bannerView: GADBannerView) {}
}

// MARK: - YMANativeAdLoaderDelegate
extension MoonViewController: YMANativeAdLoaderDelegate {
    func nativeAdLoader(_ loader: YMANativeAdLoader, didLoad ad: YMANativeAd) {
        print(#function)
        bindNativeAd(ad)
    }

    func nativeAdLoader(_ loader: YMANativeAdLoader, didFailLoadingWithError error: Error) {
        print(#function + "Error: \(error)")
    }
}

// MARK: - YMANativeAdDelegate
extension MoonViewController: YMANativeAdDelegate {
    func nativeAdDidClick(_ ad: YMANativeAd) {
        print(#function)
    }

    func nativeAdWillLeaveApplication(_ ad: YMANativeAd) {
        print(#function)
    }

    func nativeAd(_ ad: YMANativeAd, willPresentScreen viewController: UIViewController?) {
        print(#function)
    }

    func nativeAd(_ ad: YMANativeAd, didTrackImpressionWith impressionData: YMAImpressionData?) {
        print(#function)
    }

    func nativeAd(_ ad: YMANativeAd, didDismissScreen viewController: UIViewController?) {
        print(#function)
    }

    func close(_ ad: YMANativeAd) {
        print(#function)
    }
}
