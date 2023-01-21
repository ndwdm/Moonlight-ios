//
//  Date+Extensions.swift
//  Moonlight
//
//  Created by Gennady Dmitrik on 19.01.23.
//

import Foundation

extension Date {
    static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        return dateFormatter
    }()

    init(_ text: String) {
        self = Self.dateFormatter.date(from: text)!
    }
}
