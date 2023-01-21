//
//  View+Extensions.swift
//  Moonlight
//
//  Created by Gennady Dmitrik on 17.01.23.
//

import SwiftUI

extension View {
    func safeArea() -> UIEdgeInsets {
        guard let window = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return .zero }
        guard let safeArea = window.windows.first?.safeAreaInsets else { return .zero }
        return safeArea
    }
}
