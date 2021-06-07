//
//  Length.swift
//  MobileWeather
//
//  Created by Joel Fischer on 6/7/21.
//  Copyright © 2021 Ford. All rights reserved.
//

import Foundation

public enum LengthUnit {
    case millimeter, centimeter, meter, kilometer, inch, yard, mile
}

public struct Length {
    public let unit: LengthUnit
    public let value: Float

    public func value(unit: LengthUnit) -> Float {
        guard self.unit != unit else { return value }

        // Convert to SI meter
        let multiplierFrom: Float
        switch self.unit {
        case .kilometer:
            multiplierFrom = 1000.0
        case .meter:
            multiplierFrom = 1.0
        case .centimeter:
            multiplierFrom = 0.01
        case .millimeter:
            multiplierFrom = 0.001
        case .mile:
            multiplierFrom = 1609.344;
        case .yard:
            multiplierFrom = 0.9144;
        case .inch:
            multiplierFrom = 0.0254;
        }

        // Convert from SI meter to new value
        let multiplierTo: Float
        switch unit {
        case .kilometer:
            multiplierTo = 0.0001;
        case .meter:
            multiplierTo = 1.0;
        case .centimeter:
            multiplierTo = 10.0;
        case .millimeter:
            multiplierTo = 100.0;
        case .mile:
            multiplierTo = 0.00062137119224;
        case .yard:
            multiplierTo = 1.09361329833771;
        case .inch:
            multiplierTo = 39.37007874015748;
            break;
        }

        return value * multiplierFrom * multiplierTo
    }

    public func valueString(unit: LengthUnit, shortened: Bool = false) -> String {
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
        return "\(prefixString) \(valueString) \(unitString)"
    }

    public func unitString(unit: LengthUnit, shortened: Bool = false) -> String {
        if !shortened {
            switch unit {
            case .millimeter:
                return "mm"
            case .centimeter:
                return "cm"
            case .meter:
                return "m"
            case .kilometer:
                return "km"
            case .inch:
                return "in"
            case .yard:
                return "yd"
            case .mile:
                return "mi"
            }
        } else {
            switch unit {
            case .millimeter:
                return "millimter(s)"
            case .centimeter:
                return "centimeter(s)"
            case .meter:
                return "meter(s)"
            case .kilometer:
                return "kilometer(s)"
            case .inch:
                return "inch(es)"
            case .yard:
                return "yard(s)"
            case .mile:
                return "mile(s)"
            }
        }
    }
}
