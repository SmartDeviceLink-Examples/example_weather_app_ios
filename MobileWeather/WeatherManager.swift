//
//  WeatherManager.swift
//  MobileWeather
//
//  Created by Joel Fischer on 6/7/21.
//  Copyright © 2021 Ford. All rights reserved.
//

import Foundation

extension Notification.Name {
    static let weatherDataUpdate = Notification.Name(rawValue: "MobileWeatherDataUpdatedNotification")
}

class WeatherManager {
    static let shared = WeatherManager()

    var units: Preferences.Values.Units
    var currentLocation: WeatherLocation
    var conditions: WeatherCurrentConditions
    var dailyForecast: [Forecast]
    var hourlyForecast: [Forecast]
    var alerts: [WeatherAlert]

    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(locationDidUpdate(_:)), name: .weatherLocationUpdate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(weatherDataDidUpdate(_:)), name: .weatherDataUpdate, object: nil)
        // TODO: KVO units preference
//        NotificationCenter.default.addObserver(self, selector: #selector(userDefaultsDidChange(_:)), name: UserDefaults.didChangeNotification, object: nil)
    }
}

extension WeatherManager {
    @objc private func locationDidUpdate(_ notification: Notification) {
        if let location = notification.userInfo?["location"] as? WeatherLocation {
            self.currentLocation = location
        }
    }

    @objc private func weatherDataDidUpdate(_ notification: Notification) {
        if let conditions = notification.userInfo?["weatherConditions"] as? WeatherCurrentConditions {
            self.conditions = conditions
        }
        if let dailyForecast = notification.userInfo?["dailyForecast"] as? [Forecast] {
            self.dailyForecast = dailyForecast
        }
        if let hourlyForecast = notification.userInfo?["hourlyForecast"] as? [Forecast] {
            self.hourlyForecast = hourlyForecast
        }
        if let alerts = notification.userInfo?["alerts"] as? [WeatherAlert] {
            self.alerts = alerts
        }
    }
}
