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

class WeatherService: ObservableObject {
    static let shared = WeatherService()

    private var locationService: LocationService!
    private let openWeatherService = OpenWeatherService()

    private var lastUpdateTime: Date?

    @Published var currentLocation: WeatherLocation?
    @Published var weatherData: WeatherData?

    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(weatherDataDidUpdate(_:)), name: .weatherDataUpdate, object: nil)
        // TODO: KVO units preference
//        NotificationCenter.default.addObserver(self, selector: #selector(userDefaultsDidChange(_:)), name: UserDefaults.didChangeNotification, object: nil)
        locationService = LocationService(delegate: self)
    }

    func start() {
        locationService.start()
    }
}

extension WeatherService {
    @objc private func weatherDataDidUpdate(_ notification: Notification) {
        if let data = notification.userInfo?["data"] as? WeatherData {
            self.weatherData = data
        }
    }
}

extension WeatherService: LocationServiceDelegate {
    func locationDidUpdate(newLocation: WeatherLocation) {
        currentLocation = newLocation

        openWeatherService.updateWeatherData(location: <#T##WeatherLocation#>)
    }
}
