//
//  AppOpenAdManager.swift
//  Moonlight
//
//  Created by Gennady Dmitrik on 03.03.25.
//

import UIKit
import GoogleMobileAds

class AppOpenAdManager: NSObject, FullScreenContentDelegate {
    var appOpenAd: AppOpenAd?
    var isLoadingAd = false
    var isShowingAd = false
    var loadTime: Date?

    static let shared = AppOpenAdManager()

    private func loadAd() async {
        // Do not load ad if there is an unused ad or one is already loading.
        if isLoadingAd || isAdAvailable() {
            return
        }
        print(">>: Load AD")
        isLoadingAd = true

        do {
            appOpenAd = try await AppOpenAd.load(with: "", request: Request())
            appOpenAd?.fullScreenContentDelegate = self
            loadTime = Date()
        } catch {
            print(">>: App open ad failed to load with error: \(error.localizedDescription)")
        }
        isLoadingAd = false
    }

    func showAdIfAvailable() {
        // If the app open ad is already showing, do not show the ad again.
        guard !isShowingAd else { return }

        // If the app open ad is not available yet but is supposed to show, load
        // a new ad.
        if !isAdAvailable() {
            Task {
                await loadAd()

                if let ad = appOpenAd {
                    isShowingAd = true
                    ad.present(from: nil)
                }
            }
            return
        }

        if let ad = appOpenAd {
            isShowingAd = true
            ad.present(from: nil)
        }
    }

    private func isAdAvailable() -> Bool {
        // Check if ad exists and can be shown.
        return appOpenAd != nil
    }

    // MARK: - GADFullScreenContentDelegate methods

    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        print(">>: App open ad will be presented.")
    }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print(">>: AD dismissed")
        appOpenAd = nil
        isShowingAd = false
        // Reload an ad.
        Task {
            await loadAd()
        }
    }

    func ad(
        _ ad: FullScreenPresentingAd,
        didFailToPresentFullScreenContentWithError error: Error
    ) {
        print(">>: AD failed")
        appOpenAd = nil
        isShowingAd = false
        // Reload an ad.
        Task {
            await loadAd()
        }
    }
}
