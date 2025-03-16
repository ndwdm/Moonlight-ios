//
//  GeomagneticForecastView.swift
//  Moonlight
//
//  Created by Gennady Dmitrik on 03.03.25.
//

import SwiftUI

struct GeomagneticForecastView: View {
    @StateObject private var viewModel = GeomagneticViewModel()

    var body: some View {
        VStack {
            Text("\(NSLocalizedString("General.geomagnetic", comment: "")): ")
                .font(.headline)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 5) {
                ForEach(viewModel.maxValues, id: \.self) { value in
                    Text(value)
                }
            }
        }
    }
}
