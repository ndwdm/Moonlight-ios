//
//  Moonlight_Phase_WatchApp.swift
//  Moonlight Phase Watch Watch App
//
//  Created by Gennady Dmitrik on 16.03.25.
//

import SwiftUI

@main
struct Moonlight_Phase_Watch_Watch_AppApp: App {
    var body: some Scene {
        WindowGroup {
            MoonView()
                .edgesIgnoringSafeArea(.all)
        }
    }
}

#Preview {
    MoonView()
}
