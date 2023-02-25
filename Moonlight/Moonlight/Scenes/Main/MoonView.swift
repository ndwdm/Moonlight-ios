//
//  MoonView.swift
//  Moonlight
//
//  Created by Gennady Dmitrik on 18.01.23.
//

import SwiftUI

struct MoonView: View {
    var body: some View {
        MoonHostedViewController()
            .edgesIgnoringSafeArea(.all)
    }
}

struct RecognitionView_Previews: PreviewProvider {
    static var previews: some View {
        MoonView()
    }
}

struct MoonHostedViewController: UIViewControllerRepresentable {
    @EnvironmentObject private var viewModel: MoonlightViewModel

    func makeUIViewController(context: Context) -> UIViewController {
        return MoonViewController(viewModel: viewModel)
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        (uiViewController as? MoonViewController)?.updateCurrentMoonPhase()
    }
}
