//
//  MoonView.swift
//  Moonlight
//
//  Created by Gennady Dmitrik on 18.01.23.
//

import SwiftUI
import AVKit
import AVFAudio
import Combine

class MoonUIView: UIView {
    fileprivate var viewModel: MoonlightViewModel?
    private let playerLayer = AVPlayerLayer()
    private var player = AVPlayer()
    private let length = 24.0
    private var isInitialLoading = true
    private var speed = 0.0
    private let stepOffset = 0.8127165763
    private var previousPosition = 0.0

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(viewModel: MoonlightViewModel) {
        super.init(frame: .zero)
        self.viewModel = viewModel
        let fileUrl = Bundle.main.url(forResource: "moonVideo", withExtension: "mov")!
        player = AVPlayer(url: fileUrl)
        player.actionAtItemEnd = .none
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(playerLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }

    func updateCurrentMoonPhase() {
        speed = isInitialLoading && (viewModel?.currentMoonPhaseValue ?? 0.0) > 2 ? 5.0 : 1.0
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
    }

    func getStartPosition() -> Double {
        if (viewModel?.currentMoonPhaseValue ?? 0.0) < 2 {
            return 4
        }
        return 0
    }

    func getEndPosition() -> Double {
        (viewModel?.currentMoonPhaseValue ?? 0.0) * stepOffset
    }
}

struct MoonView: UIViewRepresentable {
    @EnvironmentObject private var viewModel: MoonlightViewModel

    func makeUIView(context: Context) -> UIView {
        let controller = MoonUIView(viewModel: viewModel)
        return controller
    }

    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<MoonView>) {
        (uiView as? MoonUIView)?.updateCurrentMoonPhase()
    }
}
