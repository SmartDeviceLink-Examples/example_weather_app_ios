//
//  Preferences.swift
//  MobileWeather
//
//  Created by Joel Fischer on 9/17/21.
//  Copyright © 2021 Ford. All rights reserved.
//

import Foundation

class Preferences {
    private let defaults = UserDefaults.standard

    static let shared = Preferences()

    func registerDefaults() {
        defaults.register(defaults: [
            Keys.unit.rawValue: Values.Units.imperial.rawValue
        ])
    }
}

extension Preferences {
    enum Keys: String {
        case unit
    }

    enum Values {
        enum Units: String {
            case imperial, metric
        }
    }
}
