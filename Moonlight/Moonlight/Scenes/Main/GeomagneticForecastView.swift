//
//  GeomagneticForecastView.swift
//  Moonlight
//
//  Created by Gennady Dmitrik on 03.03.25.
//

import SwiftUI

struct GeomagneticForecastView: View {
    @State private var maxValues: [String] = [NSLocalizedString("General.geomagnetic_loading", comment: "")]

    var body: some View {
        Text("\(NSLocalizedString("General.geomagnetic", comment: "")): ")
            .font(.headline)
            .fixedSize(horizontal: false, vertical: true)
            .multilineTextAlignment(.center)
        VStack(alignment: .leading, spacing: 5) {
            ForEach(maxValues, id: \.self) { value in
                Text(value)
            }
        }
        .onAppear {
            fetchGeomagneticData()
        }
    }

    func fetchGeomagneticData() {
        guard let url = URL(string: "https://services.swpc.noaa.gov/text/3-day-geomag-forecast.txt") else { return }

        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let forecastText = String(data: data, encoding: .utf8) {
                    let result = extractMaxKpValues(from: forecastText)
                    DispatchQueue.main.async {
                        maxValues = result
                    }
                }
            } catch {
                print("Error fetching data:", error)
            }
        }
    }

    func extractMaxKpValues(from text: String) -> [String] {
        let lines = text.components(separatedBy: "\n")

        // Filter lines that contain "UT" but exclude any that contain "UTC"
        let kpLines = lines.filter { $0.contains("UT") && !$0.contains("UTC") }

        var maxValues: [Double] = []
        let today = Date()

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "LLLL dd"

        for i in 0..<3 {
            let values = kpLines.compactMap { line -> Double? in
                let components = line.split(separator: " ")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty } // Remove empty components

                guard components.count > i + 1 else { return nil }

                // Ensure we're only parsing valid numbers
                if let doubleValue = Double(components[i + 1]) {
                    return doubleValue
                }
                return nil
            }

            let maxKp = values.max() ?? 0

            if let date = Calendar.current.date(byAdding: .day, value: i, to: today) {
                maxValues.append(maxKp)
            }
        }

        // Return formatted date and max Kp values
        return maxValues.enumerated().map { (index, value) in
            let date = Calendar.current.date(byAdding: .day, value: index, to: today)!
            return "\(dateFormatter.string(from: date).capitalizingFirstLetter()): \(value)"
        }
    }
}
