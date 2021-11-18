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
    var text1: String
    var text2: String
    var text3: String
    var text4: String
    var artwork1: SDLArtwork

    static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .none
        f.doesRelativeDateFormatting = true
        f.setLocalizedDateFormatFromTemplate("EEEE MMMM d")

        return f
    }()

    init(forecast: DailyForecast) {
        let conditionImage = WeatherImage.fromOpenWeatherName(OpenWeatherIcon(rawValue: forecast.conditionIconNames.first!)!)

        text1 = DailyWeatherSDLViewModel.dayFormatter.string(from: forecast.date)
        text2 = "H \(forecast.highTemperature)° | L \(forecast.lowTemperature)°"
        text3 = forecast.conditionDescriptions.first!
        text4 = "\(Int(forecast.precipitationChance.rounded()))%"
        artwork1 = SDLArtwork(image: conditionImage, persistent: true, as: .PNG)
    }
}
