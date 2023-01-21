//
//  Int+Extensions.swift
//  Moonlight
//
//  Created by Gennady Dmitrik on 19.01.23.
//

import Foundation

extension Int {
    var symbolForMoon: String {
        switch self {
        case 1...2, 29, 30:
            return "\u{1f311}" // new moon
        case 3...7:
            return "\u{1f312}"
        case 8...10:
            return "\u{1f313}" // first quarter
        case 11...13:
            return "\u{1f314}"
        case 14...17:
            return "\u{1f315}" // full moon
        case 18...21:
            return "\u{1f316}"
        case 22...24:
            return "\u{1f317}" // third quarter
        case 25...28:
            return "\u{1f318}"
        default:
            return ""
        }
    }
}
