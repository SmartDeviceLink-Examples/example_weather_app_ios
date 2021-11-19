//
//  WeatherSDLManager+SoftButtons.swift
//  MobileWeather
//
//  Created by Joel Fischer on 11/15/21.
//  Copyright © 2021 Ford. All rights reserved.
//

import SmartDeviceLink

extension WeatherSDLManager {
    static private let artSize: CGFloat = 64.0

    var softButtons: [SDLSoftButtonObject] {
        let currentConditionsSB = SDLSoftButtonObject(name: "Current Conditions", text: "Current", artwork: SDLArtwork(image: UIImage(systemName: "sun.max.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: WeatherSDLManager.artSize))!.withRenderingMode(.alwaysTemplate).withTintColor(.systemGray), persistent: true, as: .PNG)) { press, event in
            guard press != nil else { return }

            self.showCurrentConditions(speak: false)
        }

        let hourlyForecastSB = SDLSoftButtonObject(name: "Hourly Forecast", text: "Hourly", artwork: SDLArtwork(image: UIImage(systemName: "clock", withConfiguration: UIImage.SymbolConfiguration(pointSize: WeatherSDLManager.artSize))!.withRenderingMode(.alwaysTemplate).withTintColor(.systemGray), persistent: true, as: .PNG)) { press, event in
            guard press != nil else { return }

            self.presentHourlyForecastPopup()
        }

        let dailyForecastSB = SDLSoftButtonObject(name: "Daily Forecast", text: "Daily", artwork: SDLArtwork(image: UIImage(systemName: "calendar", withConfiguration: UIImage.SymbolConfiguration(pointSize: WeatherSDLManager.artSize))!.withRenderingMode(.alwaysTemplate).withTintColor(.systemGray), persistent: true, as: .PNG)) { press, event in
            guard press != nil else { return }

            self.presentDailyForecastPopup()
        }

        let alertsSB = SDLSoftButtonObject(name: "Alerts", text: "Alerts", artwork: SDLArtwork(image: UIImage(systemName: "exclamationmark.triangle", withConfiguration: UIImage.SymbolConfiguration(pointSize: WeatherSDLManager.artSize))!.withRenderingMode(.alwaysTemplate).withTintColor(.systemGray), persistent: true, as: .PNG)) { press, event in
            guard press != nil else { return }

            self.presentAlertsPopup()
        }

        return [currentConditionsSB, hourlyForecastSB, dailyForecastSB, alertsSB]
    }
}
