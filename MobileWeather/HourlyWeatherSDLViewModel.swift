//
//  HourlyWeatherSDLViewModel.swift
//  MobileWeather
//
//  Created by Joel Fischer on 11/18/21.
//  Copyright © 2021 Ford. All rights reserved.
//

import Foundation
import SmartDeviceLink

struct HourlyWeatherSDLViewModel: WeatherSDLViewModelType {
    var dateText: String
    var temperatureText: String
    var conditionText: String
    var additionalText: String
    var artwork1: SDLArtwork

    private static let hourlyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .none
        f.doesRelativeDateFormatting = false
        f.setLocalizedDateFormatFromTemplate("h a")

        return f
    }()

    init(forecast: HourlyForecast) {
        var temperatureString = "\(forecast.temperature.formatted())"
        if abs(forecast.feelsLikeTemperature.value - forecast.temperature.value) >= 5.0 {
            // The feels like is >5 degrees different than the normal temp, so we want to display that feels like
            temperatureString.append(" | Feels like \(forecast.feelsLikeTemperature.formatted())")
        }

        var textField4String = ""
        if forecast.precipitationChance > 5.0 {
            // If >5% precipitation chance, use that
            textField4String = "\(Int(forecast.precipitationChance.rounded()))%"
            if forecast.rainAmount.value > 0.0 {
                textField4String.append(" | \(forecast.rainAmount.formatted()) of Rain")
            } else if forecast.snowAmount.value > 0.0 {
                textField4String.append(" | \(forecast.rainAmount.formatted()) of Snow")
            }
        } else if forecast.visibility.value < 0.5 {
            // If visibility is less than a half mile, use that value
            textField4String = "Visibility: \(forecast.visibility.formatted())"
        } else if forecast.windSpeed.value > 20.0 {
            // If the wind is greater than 20 mph, use that value
            textField4String = "Wind: \(forecast.windSpeed.formatted())"
        } else if forecast.uvIndex > 7.0 {
            // UV Index is greater than 7
            textField4String = "UV Index: \(Int(forecast.uvIndex.rounded()).formatted())"
        }

        dateText = HourlyWeatherSDLViewModel.hourlyFormatter.string(from: forecast.date)
        temperatureText = temperatureString
        conditionText = forecast.conditionDescriptions.first!.capitalized(with: .current)
        additionalText = textField4String
        artwork1 = WeatherImage.toSDLArtwork(from: OpenWeatherIcon(rawValue: forecast.conditionIconNames.first!)!, size: .large)
    }
}
