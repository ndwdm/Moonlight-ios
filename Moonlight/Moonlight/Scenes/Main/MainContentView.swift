//
//  MainContentView.swift
//  Moonlight
//
//  Created by Gennady Dmitrik on 17.01.23.
//

import SwiftUI
import StoreKit

struct MainContentView: View {
    //@Environment(\.requestReview) private var requestReview
    @Environment(\.scenePhase) var scenePhase
    @AppStorage("launchAppCount") private var launchAppCount = 0

    @State private var statusBarIsHidden = true
    @ObservedObject private var viewModel = MoonlightViewModel()

    var body: some View {
        let dragGesture = DragGesture()
            .onEnded { value in
                if value.translation.width < -20 {
                    viewModel.moveOn(1)
                }
                if value.translation.width > 20 {
                    viewModel.moveOn(-1)
                }
            }
        AnimatedSplashScreen(animationTiming: 3) {
            ScrollView {
                VStack(spacing: 15) {
                    Text("Tap on the Moon to enable AR mode")
                        .font(.subheadline)
                    Text(viewModel.selectedDate, style: .date)
                        .font(.title)
                    Text("Moon Day: \(Int(viewModel.currentMoonPhaseValue.rounded(.up))) " + Int(viewModel.currentMoonPhaseValue.rounded(.up)).symbolForMoon)
                        .font(.subheadline)
                }
            }
        } onAnimationEnd: {
            statusBarIsHidden = false
        }
        .statusBar(hidden: statusBarIsHidden)
        .onChange(of: viewModel.currentMoonPhaseValue) { _ in }
        .environmentObject(viewModel)
        .gesture(dragGesture)
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                launchAppCount += 1
                if launchAppCount % 3 == 0 {
                    //requestReview()
                    if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                        DispatchQueue.main.async {
                            SKStoreReviewController.requestReview(in: scene)
                        }
                    }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        MainContentView()
    }
}
