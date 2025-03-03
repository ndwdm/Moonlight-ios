//
//  MoonlightApp.swift
//  Moonlight
//
//  Created by Gennady Dmitrik on 17.01.23.
//

import SwiftUI
import FirebaseCore
import GoogleMobileAds

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
      FirebaseApp.configure()
      MobileAds.shared.start(completionHandler: nil)

    return true
  }
}

@main
struct MoonlightApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            MainContentView()
                .onChange(of: scenePhase) { newPhase in
                    if newPhase == .active {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            AppOpenAdManager.shared.showAdIfAvailable()
                        }
                    }
                }
        }
    }
}
