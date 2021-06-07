//
//  Speed.swift
//  MobileWeather
//
//  Created by Joel Fischer on 6/7/21.
//  Copyright © 2021 Ford. All rights reserved.
//

import Foundation

public enum SpeedUnit {
    case metersPerSecond, kilometersPerHour, milesPerHour
}

public struct Speed {
    public let unit: SpeedUnit
    public let value: Float

    public func value(unit: SpeedUnit) -> Float {
        guard self.unit != unit else { return value }

        // First convert to SI meters/second
        let multiplierFrom: Float
        switch self.unit {
        case .metersPerSecond:
            multiplierFrom = 1.0
        case .kilometersPerHour:
            multiplierFrom = 0.27777777777778;
        case .milesPerHour:
            multiplierFrom = 0.44704;
        }

        let multiplierTo: Float
        switch unit {
        case .metersPerSecond:
            multiplierTo = 1.0;
        case .kilometersPerHour:
            multiplierTo = 3.6;
        case .milesPerHour:
            multiplierTo = 2.2369362920544;
        }

        return value * multiplierFrom * multiplierTo
    }

    public func valueString(unit: SpeedUnit, shortened: Bool = false) -> String {
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

    private func unitString(unit: SpeedUnit, shortened: Bool = false) -> String {
        if !shortened {
            switch unit {
            case .metersPerSecond:
                return "meters per second"
            case .kilometersPerHour:
                return "kilometers per hour"
            case .milesPerHour:
                return "miles per hour"
            }
        } else {
            switch unit {
            case .metersPerSecond:
                return "m/s"
            case .kilometersPerHour:
                return "kph"
            case .milesPerHour:
                return "mph"
            }
        }
    }
}
