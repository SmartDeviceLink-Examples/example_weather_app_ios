//
//  WeatherConditions.swift
//  WeatherDataService
//
//  Created by Joel Fischer on 6/7/21.
//  Copyright © 2021 Ford. All rights reserved.
//

import Foundation

struct CurrentForecast: Decodable {
    let date: Date
    let sunriseDate: Date
    let sunsetDate: Date
    let temperature: Measurement<UnitTemperature>
    let feelsLikeTemperature: Measurement<UnitTemperature>
    let uvIndex: Double
    let visibility: Measurement<UnitLength>
    let windSpeed: Measurement<UnitSpeed>
    let windGust: Measurement<UnitSpeed>
    let conditionDescription: String
    let conditionIconName: String

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        date = try values.decode(Date.self, forKey: .date)
        sunriseDate = try values.decode(Date.self, forKey: .sunriseDate)
        sunsetDate = try values.decode(Date.self, forKey: .sunsetDate)
        temperature = Measurement(value: try values.decode(Double.self, forKey: .temperature), unit: UnitTemperature.kelvin)
        feelsLikeTemperature = Measurement(value: try values.decode(Double.self, forKey: .feelsLikeTemperature), unit: UnitTemperature.kelvin)
        uvIndex = try values.decode(Double.self, forKey: .uvIndex)
        visibility = Measurement(value: try values.decode(Double.self, forKey: .visibility), unit: UnitLength.meters)
        windSpeed = Measurement(value: try values.decode(Double.self, forKey: .windSpeed), unit: UnitSpeed.metersPerSecond)
        windGust = Measurement(value: try values.decode(Double.self, forKey: .windGust), unit: UnitSpeed.metersPerSecond)

        let weatherInfoValues = try values.nestedContainer(keyedBy: WeatherInfoCodingKeys.self, forKey: .weatherInfo)
        conditionDescription = try weatherInfoValues.decode(String.self, forKey: .conditionDescription)
        conditionIconName = try weatherInfoValues.decode(String.self, forKey: .icon)
    }

    private enum CodingKeys: String, CodingKey {
        case date = "dt", sunriseDate = "sunrise", sunsetDate = "sunset", temperature = "temp", feelsLikeTemperature = "feels_like", uvIndex = "uvi", visibility, windSpeed = "wind_speed", windGust = "wind_gust", weatherInfo = "weather"
    }

    private enum WeatherInfoCodingKeys: String, CodingKey {
        case conditionId = "id", conditionNames = "main", conditionDescription = "description", icon = "icon"
    }
}
