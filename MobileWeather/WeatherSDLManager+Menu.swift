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
    static private let artSize: CGFloat = 64.0

    var menuCells: [SDLMenuCell] {
        let showWeatherConditions = SDLMenuCell(
            title: "Current Conditions", secondaryText: nil, tertiaryText: nil,
            icon: SDLArtwork(image: UIImage(systemName: "sun.max.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: WeatherSDLManager.artSize))!.withRenderingMode(.alwaysTemplate), persistent: true, as: .PNG), secondaryArtwork: nil,
            voiceCommands: ["Current", "Current Conditions"]) { triggerSource in
                self.showCurrentConditions(speak: (triggerSource == .voiceRecognition))
        }

        let showHourlyForecast = SDLMenuCell(
            title: "Hourly Forecast", secondaryText: nil, tertiaryText: nil,
            icon: SDLArtwork(image: UIImage(systemName: "clock", withConfiguration: UIImage.SymbolConfiguration(pointSize: WeatherSDLManager.artSize))!.withRenderingMode(.alwaysTemplate), persistent: true, as: .PNG), secondaryArtwork: nil,
            voiceCommands: ["Hourly", "Hourly Forecast"]) { triggerSource in
                self.presentHourlyForecastPopup()
            }

        let showDailyForecast = SDLMenuCell(
            title: "Daily Forecast", secondaryText: nil, tertiaryText: nil,
            icon: SDLArtwork(image: UIImage(systemName: "calendar", withConfiguration: UIImage.SymbolConfiguration(pointSize: WeatherSDLManager.artSize))!.withRenderingMode(.alwaysTemplate), persistent: true, as: .PNG), secondaryArtwork: nil,
            voiceCommands: ["Daily", "Daily Forecast"]) { triggerSource in
                self.presentDailyForecastPopup()
            }

        let showAlerts = SDLMenuCell(
            title: "Weather Alerts", secondaryText: nil, tertiaryText: nil,
            icon: SDLArtwork(image: UIImage(systemName: "exclamationmark.triangle", withConfiguration: UIImage.SymbolConfiguration(pointSize: WeatherSDLManager.artSize))!.withRenderingMode(.alwaysTemplate), persistent: true, as: .PNG), secondaryArtwork: nil,
            voiceCommands: ["Weather Alerts", "Alerts"]) { triggerSource in
                self.presentAlertsPopup()
            }

        return [showWeatherConditions, showHourlyForecast, showDailyForecast, showAlerts]
    }
}
