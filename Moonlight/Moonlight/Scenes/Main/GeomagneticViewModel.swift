//
//  GeomagneticViewModel.swift
//  Moonlight
//
//  Created by Gennady Dmitrik on 16.03.25.
//

import Foundation

class GeomagneticViewModel: ObservableObject {
    @Published var maxValues: [String] = [NSLocalizedString("General.geomagnetic_loading", comment: "")]

    init() {
        fetchGeomagneticData()
    }

    func fetchGeomagneticData() {
        guard let url = URL(string: "https://services.swpc.noaa.gov/text/3-day-geomag-forecast.txt") else { return }

        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let forecastText = String(data: data, encoding: .utf8) {
                    let result = extractMaxKpValues(from: forecastText)
                    DispatchQueue.main.async {
                        self.maxValues = result
                    }
                }
            } catch {
                print("Error fetching data:", error)
            }
        }
    }

    func extractMaxKpValues(from text: String) -> [String] {
        let lines = text.components(separatedBy: "\n")
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
                return Double(components[i + 1])
            }

            let maxKp = values.max() ?? 0

            if let date = Calendar.current.date(byAdding: .day, value: i, to: today) {
                maxValues.append(maxKp)
            }
        }

        return maxValues.enumerated().map { (index, value) in
            let date = Calendar.current.date(byAdding: .day, value: index, to: today)!
            return "\(dateFormatter.string(from: date).capitalizingFirstLetter()): \(value)"
        }
    }
}
