//
//  Percentage.swift
//  MobileWeather
//
//  Created by Joel Fischer on 6/7/21.
//  Copyright © 2021 Ford. All rights reserved.
//

import Foundation

public enum PercentageUnit {
    case percent, factor
}

public struct Percentage {
    public let unit: PercentageUnit
    public let value: Float

    public func value(unit: PercentageUnit) -> Float {
        guard self.unit != unit else { return value }

        let multiplierFrom: Float
        switch self.unit {
        case .percent:
            multiplierFrom = 1.0
        case .factor:
            multiplierFrom = 100.0
        }

        let multiplierTo: Float
        switch self.unit {
        case .percent:
            multiplierTo = 1.0
        case .factor:
            multiplierTo = 0.001
        }

        return value * multiplierFrom * multiplierTo
    }

    public func valueString(unit: PercentageUnit, shortened: Bool = false) -> String {
        var convertedValue = value(unit: unit)

        let prefixString: String
        if convertedValue < 0 && shortened == false {
            prefixString = "negative"
            convertedValue *= -1.0
        } else {
            prefixString = ""
        }

        let unitString = unitString(unit: unit)
        return "\(prefixString) \(convertedValue) \(unitString)"
    }

    private func unitString(unit: PercentageUnit, shortened: Bool = false) -> String {
        switch unit {
        case .factor: return ""
        case .percent:
            if !shortened {
                return "percent"
            } else {
                return "%"
            }
        }
    }
}
