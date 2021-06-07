//
//  Temperature.swift
//  WeatherDataService
//
//  Created by Joel Fischer on 6/7/21.
//  Copyright © 2021 Ford. All rights reserved.
//

import Foundation

public enum TemperatureUnit {
    case celsius, fahrenheit
}

public struct Temperature {
    public let unit: TemperatureUnit
    public let value: Float

    public func value(unit: TemperatureUnit) -> Float {
        guard self.unit != unit else { return value }

        if self.unit == .celsius && unit == .fahrenheit {
            return (value * 9/5) + 32.0
        } else {
            return (value - 32.0) * 5/9
        }
    }

    public func valueString(unit: TemperatureUnit, shortened: Bool = false) -> String {
        var convertedValue = value(unit: unit)

        let prefixString: String
        if convertedValue < 0 && shortened == false {
            prefixString = "negative"
            convertedValue *= -1.0
        } else {
            prefixString = ""
        }

        let unitString = unitString(unit: unit, shortened: shortened)
        let valueString = String(convertedValue)
        let string = "\(prefixString) \(valueString) \(unitString)"

        return string.trimmingCharacters(in: .whitespaces)
    }

    private func unitString(unit: TemperatureUnit, shortened: Bool = false) -> String {
        if !shortened {
            return "degrees"
        } else {
            switch unit {
            case .celsius:
                return "°C"
            case .fahrenheit:
                return "°F"
            }
        }
    }
}
