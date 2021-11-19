//
//  CurrentWeatherViewModel.swift
//  MobileWeather
//
//  Created by Joel Fischer on 11/18/21.
//  Copyright © 2021 Ford. All rights reserved.
//

import Foundation
import SmartDeviceLink

struct CurrentWeatherSDLViewModel: WeatherSDLViewModelType {
    var dateText: String
    var temperatureText: String
    var conditionText: String
    var additionalText: String
    var artwork1: SDLArtwork

    private static var sunriseSunsetFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeZone = .current
        f.timeStyle = .short

        return f
    }()

    init(currentWeather: CurrentForecast) {
        var temperatureString = "\(currentWeather.temperature.formatted())"
        if abs(currentWeather.feelsLikeTemperature.value - currentWeather.temperature.value) >= 5.0 {
            // The feels like is >5 degrees different than the normal temp, so we want to display that feels like
            temperatureString.append(" | Feels like \(currentWeather.feelsLikeTemperature.formatted())")
        }

        let textField4String: String
        if currentWeather.visibility.value < 0.5 {
            // If visibility is less than a half mile, use that value
            textField4String = "Visibility: \(currentWeather.visibility.formatted())"
        } else if currentWeather.windSpeed.value > 20.0 {
            // If the wind is greater than 20 mph, use that value
            textField4String = "Wind: \(currentWeather.windSpeed.formatted())"
        } else if currentWeather.uvIndex > 7.0 {
            // UV Index is greater than 7
            textField4String = "UV Index: \(Int(currentWeather.uvIndex.rounded()).formatted())"
        } else {
            if currentWeather.sunriseDate.timeIntervalSinceNow < 0 {
                // Sunrise passed, use sunset
                textField4String = "Sunset at " + CurrentWeatherSDLViewModel.sunriseSunsetFormatter.string(from: currentWeather.sunsetDate)
            } else {
                // Sunrise hasn't passed, use sunrise
                textField4String = "Sunrise at " + CurrentWeatherSDLViewModel.sunriseSunsetFormatter.string(from: currentWeather.sunriseDate)
            }
        }

        dateText = "Right Now"
        temperatureText = temperatureString
        conditionText = currentWeather.conditionDescriptions.first!.capitalized(with: .current)
        additionalText = textField4String
        artwork1 = WeatherImage.toSDLArtwork(from: OpenWeatherIcon(rawValue: currentWeather.conditionIconNames.first!)!, size: .large)
    }
}
