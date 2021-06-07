//
//  WeatherManager.swift
//  MobileWeather
//
//  Created by Joel Fischer on 6/7/21.
//  Copyright © 2021 Ford. All rights reserved.
//

import Foundation

enum UnitSettings {
    case imperial, metric
}

extension Notification.Name {
    static let weatherDataUpdate = Notification.Name(rawValue: "MobileWeatherDataUpdatedNotification")
}

class WeatherManager {
    static let shared = WeatherManager()

    var units: UnitSettings
    var currentLocation: WeatherLocation
    var conditions: WeatherConditions
    var dailyForecast: [Forecast]
    var hourlyForecast: [Forecast]
    var alerts: [WeatherAlert]

    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(locationDidUpdate(_:)), name: .weatherLocationUpdate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(weatherDataDidUpdate(_:)), name: .weatherDataUpdate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(userDefaultsDidChange(_:)), name: UserDefaults.didChangeNotification, object: nil)
    }
}

extension WeatherManager {
    @objc private func locationDidUpdate(_ notification: Notification) {

    }

    @objc private func weatherDataDidUpdate(_ notification: Notification) {

    }

    @objc private func userDefaultsDidChange(_ notification: Notification) {

    }
}
