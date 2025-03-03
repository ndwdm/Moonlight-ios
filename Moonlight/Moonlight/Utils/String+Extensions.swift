//
//  String+Extensions.swift
//  Moonlight
//
//  Created by Gennady Dmitrik on 03.03.25.
//

import Foundation
import UIKit

extension String {
    func capitalizingFirstLetter() -> String {
        let first = self.prefix(1).capitalized
        let other = self.dropFirst()
        return first + other
    }

}
