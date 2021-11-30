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
    let dateText: String
    let temperatureText: String
    let conditionText: String
    let additionalText: String
    let artwork1: SDLArtwork

    static private let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .none
        f.doesRelativeDateFormatting = true
        f.setLocalizedDateFormatFromTemplate("EEEE MMMM d")

        return f
    }()

    static private let measurementFormatter: MeasurementFormatter = {
        let f = MeasurementFormatter()
        f.locale = .autoupdatingCurrent
        f.unitOptions = .naturalScale
        f.unitStyle = .medium
        f.numberFormatter.maximumFractionDigits = 2

        return f
    }()

    init(forecast: DailyForecast) {
        dateText = DailyWeatherSDLViewModel.dayFormatter.string(from: forecast.date)
        temperatureText = "H \(forecast.highTemperature.formatted()) | L \(forecast.lowTemperature.formatted())"
        conditionText = forecast.conditionDescriptions.first!.capitalized(with: .current)

        var precipitationString = "\(Int((forecast.precipitationChance * 100).rounded()))% Chance"
        if (forecast.snowAmount.value > 0) && (forecast.rainAmount.value == 0) {
            precipitationString.append(" of \(DailyWeatherSDLViewModel.measurementFormatter.string(from: forecast.snowAmount)) Snow")
        } else if (forecast.rainAmount.value > 0) && (forecast.snowAmount.value == 0) {
            precipitationString.append(" of \(DailyWeatherSDLViewModel.measurementFormatter.string(from: forecast.rainAmount)) Rain")
        } else {
            let totalPrecipitation = forecast.rainAmount + forecast.snowAmount
            precipitationString.append(" \(DailyWeatherSDLViewModel.measurementFormatter.string(from: totalPrecipitation)) of Snow and Rain")
        }
        additionalText = precipitationString

        artwork1 = WeatherImage.toSDLArtwork(from: OpenWeatherIcon(rawValue: forecast.conditionIconNames.first!)!, size: .large)
    }
}
