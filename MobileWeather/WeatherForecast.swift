//
//  WeatherForecast.swift
//  MobileWeather
//
//  Created by Joel Fischer on 6/7/21.
//  Copyright © 2021 Ford. All rights reserved.
//

import Foundation

struct HourlyForecast: Codable {
    let date: Date
    let conditionTitle: String
    let conditionIconName: String
    let temperature: Temperature
    let feelsLikeTemperature: Temperature
    let windSpeed: Speed
    let windGust: Speed?
    let humidity: Percentage
    let precipitationAmount: Length
    let precipitationChance: Percentage
}

struct DailyForecast: Codable {
    let date: Date
    let conditionTitle: String
    let conditionIconName: String
    let lowTemperature: Temperature
    let highTemperature: Temperature
    let windSpeed: Speed
    let windGust: Speed?
    let humidity: Percentage
    let precipitationAmount: Length
    let precipitationChance: Percentage
}
