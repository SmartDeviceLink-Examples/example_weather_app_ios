//
//  Formatters.swift
//  MobileWeather
//
//  Created by Joel Fischer on 12/6/21.
//  Copyright © 2021 Ford. All rights reserved.
//

import Foundation

enum WeatherFormatter {
    static var temperatureFormatter: MeasurementFormatter = {
        let m = MeasurementFormatter()
        m.locale = .autoupdatingCurrent
        m.numberFormatter.maximumFractionDigits = 0

        return m
    }()

    static var speedFormatter: MeasurementFormatter = {
        let m = MeasurementFormatter()
        m.locale = .autoupdatingCurrent
        m.numberFormatter.maximumFractionDigits = 0

        return m
    }()
}
