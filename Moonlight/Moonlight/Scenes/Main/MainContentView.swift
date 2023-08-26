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
        AnimatedSplashScreen(animationTiming: 2) {
            VStack(
                alignment: .center,
                spacing: 0
            ) {
                Text(viewModel.selectedDate, style: .date)
                    .font(.title)
                Text("\(NSLocalizedString("General.moonDay", comment: "")): \(Int(viewModel.currentMoonPhaseValue.rounded(.up))) " + Int(viewModel.currentMoonPhaseValue.rounded(.up)).symbolForMoon)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.center)
                HStack {
                    Image("tap")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .aspectRatio(contentMode: .fit)
                    Text(NSLocalizedString("General.tap", comment: ""))
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.center)
                }

                HStack {
                    Spacer()
                    Image("swipe")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)
                    Text(NSLocalizedString("General.swipe", comment: ""))
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.center)

                    Image("pinch")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .aspectRatio(contentMode: .fit)
                    Text(NSLocalizedString("General.pinch", comment: ""))
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
            }
            .padding(0)
        } onAnimationEnd: {}
        .onChange(of: viewModel.currentMoonPhaseValue) { _ in }
        .environmentObject(viewModel)
        .gesture(dragGesture)
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                launchAppCount += 1
                if launchAppCount % 2 == 0 {
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
