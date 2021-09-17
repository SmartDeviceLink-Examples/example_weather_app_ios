//
//  WeatherConditions.swift
//  WeatherDataService
//
//  Created by Joel Fischer on 6/7/21.
//  Copyright © 2021 Ford. All rights reserved.
//

import Foundation

public struct WeatherCurrentConditions: Decodable {
    let date: Date
    let sunriseDate: Date
    let sunsetDate: Date
    let temperature: Measurement<UnitTemperature>
    let feelsLikeTemperature: Measurement<UnitTemperature>
    let uvIndex: Double
    let visibility: Measurement<UnitLength>
    let windSpeed: Measurement<UnitSpeed>
    let windGust: Measurement<UnitSpeed>
    let conditionTitle: String
    let conditionIconName: String

    enum CodingKeys: String, CodingKey {
        case date = "dt", sunriseDate = "sunrise", sunsetDate = "sunset", temperature = "temp", feelsLikeTemperature = "feels_like", uvIndex = "uvi", visibility, windspeed = "wind_speed", windGust = "wind_gust", conditionTitle = "
    }
}
