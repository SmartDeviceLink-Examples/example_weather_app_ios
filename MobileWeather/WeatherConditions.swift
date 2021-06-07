//
//  WeatherConditions.swift
//  WeatherDataService
//
//  Created by Joel Fischer on 6/7/21.
//  Copyright © 2021 Ford. All rights reserved.
//

import Foundation

public struct WeatherConditions {
    let date: Date
    let conditionTitle: String
    let conditionIconName: String
    let temperature: Temperature
    let feelsLikeTemperature: Temperature
    let windSpeed: Speed
    let windSpeedGust: Speed
    let visibility: Length
    let humidity: Percentage
    let precipitation: Percentage
}
