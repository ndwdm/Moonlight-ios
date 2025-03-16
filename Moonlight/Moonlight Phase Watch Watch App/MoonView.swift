//
//  MoonView.swift
//  Moonlight Phase Watch Watch App
//
//  Created by Gennady Dmitrik on 16.03.25.
//

import SwiftUI
import SceneKit

struct MoonView: View {
    @State private var selectedDate = Date()
    @State private var scene = SCNScene()
    @State private var moonNode = SCNNode()
    @State private var directLightNode = SCNNode()

    var body: some View {
        VStack {
            Text(selectedDate, style: .date)
                .font(.title)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .frame(height: 35)
                .padding(.top, 30)

            ZStack {
                SceneView(scene: scene, options: [.autoenablesDefaultLighting])
                    .onAppear { setupScene() }
                    .onChange(of: selectedDate) { _ in updateMoonPhase(for: selectedDate) }

                Color.clear
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture()
                            .onEnded { value in
                                if value.translation.width < -20 {
                                    selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
                                } else if value.translation.width > 20 {
                                    selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
                                }
                            }
                    )
            }
        }
    }

    private func setupScene() {
        scene = SCNScene()

        // Setup Moon
        let sphere = SCNSphere(radius: 1.2)
        let material = SCNMaterial()
        material.diffuse.contents = UIImage(named: "moonAR.scnassets/8k_moon.jpg")
        sphere.materials = [material]

        moonNode.geometry = sphere
        moonNode.position = SCNVector3(x: 0, y: 0, z: -3)

        // Setup Lighting
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.color = UIColor.white.withAlphaComponent(0.75)
        ambientLight.light?.intensity = 25

        directLightNode.light = SCNLight()
        directLightNode.light?.type = .directional
        directLightNode.light?.color = UIColor.white
        directLightNode.position = SCNVector3(x: 0, y: 0, z: 3)
        directLightNode.light?.castsShadow = true
        directLightNode.light?.automaticallyAdjustsShadowProjection = true
        directLightNode.light?.shadowSampleCount = 64
        directLightNode.light?.shadowRadius = 16


        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.3
        directLightNode.light?.intensity = 2500
        SCNTransaction.commit()

        directLightNode.light?.shadowMapSize = CGSize(width: 2048, height: 2048)


        // Setup Camera
        let cameraNode = SCNNode()
        let camera = SCNCamera()
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 0, 0.3)

        let constraint = SCNLookAtConstraint(target: moonNode)
        constraint.isGimbalLockEnabled = true
        cameraNode.constraints = [constraint]

        // Add to Scene
        scene.rootNode.addChildNode(cameraNode)
        scene.rootNode.addChildNode(moonNode)
        scene.rootNode.addChildNode(ambientLight)
        scene.rootNode.addChildNode(directLightNode)

        // Initial Moon Update
        updateMoonPhase(for: selectedDate)
    }

    private func updateMoonPhase(for date: Date) {
        let angle = calculateMoonPhase(date: date)
        let newVector = SCNVector3(0, -Float(angle - 14.5) * 0.21, 0)

        let rotateAction = SCNAction.rotateTo(
            x: CGFloat(newVector.x),
            y: CGFloat(newVector.y),
            z: CGFloat(newVector.z),
            duration: 0
        )

        directLightNode.runAction(rotateAction)
    }

    private func calculateMoonPhase(date: Date) -> Double {
        let lunarPhaseStart = Calendar.current.date(from: DateComponents(year: 1970, month: 8, day: 1)) ?? Date()
        guard let daysSinceStart = Calendar.current.dateComponents([.day], from: lunarPhaseStart, to: date).day else { return 0 }

        let lunarMonthSeconds = 2551443
        let daySeconds = 86400
        let dayOffset = 12300
        let seconds = daysSinceStart * daySeconds + dayOffset
        let lunarMonths = Double(seconds % lunarMonthSeconds) / Double(daySeconds)

        return lunarMonths
    }
}
