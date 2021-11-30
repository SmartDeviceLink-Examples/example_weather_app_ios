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

    @Published var lastUpdateTime: Date?
    @Published var currentLocation = WeatherLocation(country: nil, state: nil, city: nil, zipCode: nil, gpsLocation: CLLocation(latitude: 42.4829483, longitude: -83.1426719))
    @Published var weatherData = WeatherData()

    init() {
        locationService = LocationService(delegate: self)
    }

    func start() {
        locationService.start()
    }
}

extension WeatherService: LocationServiceDelegate {
    func locationDidUpdate(newLocation: WeatherLocation) {
        currentLocation = newLocation

        Task.init {
            if let newWeatherData = await openWeatherService.updateWeatherData(location: newLocation) {
                DispatchQueue.main.async {
                    self.weatherData = newWeatherData
                    self.lastUpdateTime = Date()
                    NotificationCenter.default.post(name: .weatherDataUpdate, object: self)
                }
            } else {
                // Broadcast an error
            }
        }
    }
}
