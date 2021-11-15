//
//  WeatherSDLMenuManager.swift
//  MobileWeather
//
//  Created by Joel Fischer on 11/12/21.
//  Copyright © 2021 Ford. All rights reserved.
//

import Foundation
import SmartDeviceLink

extension WeatherSDLManager {
    var menuCells: [SDLMenuCell] {
        let showWeatherConditions = SDLMenuCell(
            title: "Current Conditions", secondaryText: nil, tertiaryText: nil,
            icon: SDLArtwork(image: UIImage(named: "clear-day")!.withRenderingMode(.alwaysTemplate), persistent: true, as: .PNG), secondaryArtwork: nil,
            voiceCommands: ["Current", "Current Conditions"]) { triggerSource in
                self.showCurrentConditions(speak: (triggerSource == .voiceRecognition))
        }

        let showDailyForecast = SDLMenuCell(
            title: "Daily Forecast", secondaryText: nil, tertiaryText: nil,
            icon: SDLArtwork(image: UIImage(named: "menu-day")!.withRenderingMode(.alwaysTemplate), persistent: true, as: .PNG), secondaryArtwork: nil,
            voiceCommands: ["Daily", "Daily Forecast"]) { triggerSource in
                self.showDailyForecast(speak: (triggerSource == .voiceRecognition))
            }

        let showHourlyForecast = SDLMenuCell(
            title: "Hourly Forecast", secondaryText: nil, tertiaryText: nil,
            icon: SDLArtwork(image: UIImage(named: "menu-time")!.withRenderingMode(.alwaysTemplate), persistent: true, as: .PNG), secondaryArtwork: nil,
            voiceCommands: ["Hourly", "Hourly Forecast"]) { triggerSource in
                self.showHourlyForecast(speak: (triggerSource == .voiceRecognition))
            }

        let showAlerts = SDLMenuCell(
            title: "Weather Alerts", secondaryText: nil, tertiaryText: nil,
            icon: SDLArtwork(image: UIImage(named: "menu-alert")!.withRenderingMode(.alwaysTemplate), persistent: true, as: .PNG), secondaryArtwork: nil,
            voiceCommands: ["Weather Alerts", "Alerts"]) { triggerSource in
                self.showWeatherAlerts(speak: (triggerSource == .voiceRecognition))
            }

        return [showWeatherConditions, showDailyForecast, showHourlyForecast, showAlerts]
    }
}
