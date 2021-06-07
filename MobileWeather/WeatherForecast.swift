//
//  WeatherForecast.swift
//  MobileWeather
//
//  Created by Joel Fischer on 6/7/21.
//  Copyright © 2021 Ford. All rights reserved.
//

import Foundation

struct Forecast {
    let date: Date
    let conditionTitle: String
    let conditionIconName: String
    let temperature: Temperature
    let highTemperature: Temperature
    let lowTemperature: Temperature
    let windSpeed: Speed
    let humidity: Percentage
    let precipitationAmount: Length
    let precipitationChance: Percentage
}
