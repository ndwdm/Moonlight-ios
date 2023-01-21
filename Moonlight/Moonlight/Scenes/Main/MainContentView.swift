//
//  MainContentView.swift
//  Moonlight
//
//  Created by Gennady Dmitrik on 17.01.23.
//

import SwiftUI

struct MainContentView: View {
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
                    Text(viewModel.selectedDate, style: .date)
                        .font(.title)
                    Text("Moon Day: \(Int(viewModel.currentMoonPhaseValue.rounded(.up))) " + Int(viewModel.currentMoonPhaseValue.rounded(.up)).symbolForMoon)
                        .font(.subheadline)
                }            }
        } onAnimationEnd: {
            statusBarIsHidden = false
        }
        .statusBar(hidden: statusBarIsHidden)
        .onChange(of: viewModel.currentMoonPhaseValue) { _ in }
        .environmentObject(viewModel)
        .gesture(dragGesture)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        MainContentView()
    }
}
