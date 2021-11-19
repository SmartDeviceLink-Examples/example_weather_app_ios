//
//  DailyWeatherViewModel.swift
//  MobileWeather
//
//  Created by Joel Fischer on 11/18/21.
//  Copyright © 2021 Ford. All rights reserved.
//

import Foundation
import SmartDeviceLink

struct DailyWeatherSDLViewModel: WeatherSDLViewModelType {
    var dateText: String
    var temperatureText: String
    var conditionText: String
    var additionalText: String
    var artwork1: SDLArtwork

    static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .none
        f.doesRelativeDateFormatting = true
        f.setLocalizedDateFormatFromTemplate("EEEE MMMM d")

        return f
    }()

    init(forecast: DailyForecast) {
        dateText = DailyWeatherSDLViewModel.dayFormatter.string(from: forecast.date)
        temperatureText = "H \(forecast.highTemperature.formatted()) | L \(forecast.lowTemperature.formatted())"
        conditionText = forecast.conditionDescriptions.first!.capitalized(with: .current)
        additionalText = "\(Int(forecast.precipitationChance.rounded()))%"
        artwork1 = WeatherImage.toSDLArtwork(from: OpenWeatherIcon(rawValue: forecast.conditionIconNames.first!)!, size: .large)
    }
}
