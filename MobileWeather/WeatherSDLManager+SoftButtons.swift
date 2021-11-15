//
//  WeatherSDLManager+SoftButtons.swift
//  MobileWeather
//
//  Created by Joel Fischer on 11/15/21.
//  Copyright © 2021 Ford. All rights reserved.
//

import SmartDeviceLink

extension WeatherSDLManager {
    var softButtons: [SDLSoftButtonObject] {
        let currentConditionsSB = SDLSoftButtonObject(name: "Current Conditions", text: "Current", artwork: SDLArtwork(image: UIImage(named: "clear-day")!.withRenderingMode(.alwaysTemplate), persistent: true, as: .PNG)) { press, event in
            guard press != nil else { return }

            self.showCurrentConditions(speak: false)
        }

        let hourlyForecastSB = SDLSoftButtonObject(name: "Hourly Forecast", text: "Hourly", artwork: SDLArtwork(image: UIImage(named: "menu-day")!.withRenderingMode(.alwaysTemplate), persistent: true, as: .PNG)) { press, event in
            guard press != nil else { return }

            self.showHourlyForecast(speak: false)
        }

        let dailyForecastSB = SDLSoftButtonObject(name: "Daily Forecast", text: "Daily", artwork: SDLArtwork(image: UIImage(named: "menu-day")!.withRenderingMode(.alwaysTemplate), persistent: true, as: .PNG)) { press, event in
            guard press != nil else { return }

            self.showDailyForecast(speak: false)
        }

        let alertsSB = SDLSoftButtonObject(name: "Alerts", text: "Alerts", artwork: SDLArtwork(image: UIImage(named: "menu-alert")!.withRenderingMode(.alwaysTemplate), persistent: true, as: .PNG)) { press, event in
            guard press != nil else { return }

            self.showWeatherAlerts(speak: false)
        }

        return [currentConditionsSB, hourlyForecastSB, dailyForecastSB, alertsSB]
    }
}
