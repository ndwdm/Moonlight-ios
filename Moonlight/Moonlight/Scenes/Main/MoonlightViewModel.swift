//
//  MoonlightViewModel.swift
//  Moonlight
//
//  Created by Gennady Dmitrik on 17.01.23.
//

import SwiftUI

class MoonlightViewModel: ObservableObject {
    @Published var currentMoonPhaseValue = 0.0
    @Published var selectedDate = Date() {
        didSet {
            updateCurrentMoonPhaseValue()
        }
    }

    init() {
        updateCurrentMoonPhaseValue()
    }

    func updateCurrentMoonPhaseValue() {
        let lunarPhaseStart = Date("01/08/1970")
        guard let daysSinceStart = Calendar.current.dateComponents(
            [.day],
            from: lunarPhaseStart,
            to: selectedDate
        ).day else { return }
        let lunarMonthSeconds = 2551443
        let daySeconds = 86400
        let dayOffset = 12300
        let seconds = daysSinceStart * daySeconds + dayOffset
        let lunarMonths = Double(seconds % lunarMonthSeconds) / Double(daySeconds)
        currentMoonPhaseValue = lunarMonths
    }

    func moveOn(_ days: Int) {
        selectedDate = Calendar.current.date(byAdding: .day, value: days, to: selectedDate) ?? selectedDate
        updateCurrentMoonPhaseValue()
        objectWillChange.send()
    }
}
