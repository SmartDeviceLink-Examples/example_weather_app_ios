//
//  WeatherManager.swift
//  MobileWeather
//
//  Created by Joel Fischer on 6/7/21.
//  Copyright © 2021 Ford. All rights reserved.
//

import Foundation
import CoreLocation

extension Notification.Name {
    static let weatherDataUpdate = Notification.Name(rawValue: "MobileWeatherDataUpdatedNotification")
}

class WeatherManager: ObservableObject {
    static let shared = WeatherManager()

    @Published var currentLocation: WeatherLocation?
    @Published var weatherData: WeatherData?

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
        if let data = notification.userInfo?["data"] as? WeatherData {
            self.weatherData = data
        }
    }
}
