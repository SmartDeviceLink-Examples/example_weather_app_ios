//
//  WeatherForecast.swift
//  MobileWeather
//
//  Created by Joel Fischer on 6/7/21.
//  Copyright © 2021 Ford. All rights reserved.
//

import Foundation

struct HourlyForecast: Decodable {
    let date: Date
    let temperature: Measurement<UnitTemperature>
    let feelsLikeTemperature: Measurement<UnitTemperature>
    let uvIndex: Double
    let visibility: Measurement<UnitLength>
    let windSpeed: Measurement<UnitSpeed>
    let windGust: Measurement<UnitSpeed>?
    let precipitationChance: Double
    let rainAmount: Measurement<UnitLength>
    let snowAmount: Measurement<UnitLength>
    let conditionDescriptions: [String]
    let conditionIconNames: [String]

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        date = try values.decode(Date.self, forKey: .date)
        temperature = Measurement(value: try values.decode(Double.self, forKey: .temperature), unit: UnitTemperature.kelvin)
        feelsLikeTemperature = Measurement(value: try values.decode(Double.self, forKey: .feelsLikeTemperature), unit: UnitTemperature.kelvin)
        uvIndex = try values.decode(Double.self, forKey: .uvIndex)
        visibility = Measurement(value: try values.decode(Double.self, forKey: .visibility), unit: UnitLength.meters)
        windSpeed = Measurement(value: try values.decode(Double.self, forKey: .windSpeed), unit: UnitSpeed.metersPerSecond)

        if let gustRawValue = try values.decodeIfPresent(Double.self, forKey: .windGust) {
            windGust = Measurement(value: gustRawValue, unit: UnitSpeed.metersPerSecond)
        } else {
            windGust = nil
        }
        precipitationChance = try values.decode(Double.self, forKey: .precipitationChance)

        if values.contains(.rainInfo) {
            let rainValues = try values.nestedContainer(keyedBy: PrecipitationCodingKeys.self, forKey: .rainInfo)
            rainAmount = Measurement(value: try rainValues.decode(Double.self, forKey: .lastHour), unit: UnitLength.millimeters)
        } else {
            rainAmount = Measurement(value: 0.0, unit: UnitLength.millimeters)
        }

        if values.contains(.snowInfo) {
            let snowValues = try values.nestedContainer(keyedBy: PrecipitationCodingKeys.self, forKey: .snowInfo)
            snowAmount = Measurement(value: try snowValues.decode(Double.self, forKey: .lastHour), unit: UnitLength.millimeters)
        } else {
            snowAmount = Measurement(value: 0.0, unit: UnitLength.millimeters)
        }

        var weatherValues = try values.nestedUnkeyedContainer(forKey: .weatherInfo)
        var tempDescriptions = [String]()
        var tempIconNames = [String]()
        while !weatherValues.isAtEnd {
            let weatherInfoValues = try weatherValues.nestedContainer(keyedBy: WeatherInfoCodingKeys.self)
            tempDescriptions.append(try weatherInfoValues.decode(String.self, forKey: .conditionDescription))
            tempIconNames.append(try weatherInfoValues.decode(String.self, forKey: .icon))
        }
        conditionDescriptions = tempDescriptions
        conditionIconNames = tempIconNames
    }

    private enum CodingKeys: String, CodingKey {
        case date = "dt", temperature = "temp", feelsLikeTemperature = "feels_like", humidity = "humidity", uvIndex = "uvi", visibility = "visibility", windSpeed = "wind_speed", windGust = "wind_gust", precipitationChance = "pop", rainInfo = "rain", snowInfo = "snow", weatherInfo = "weather"
    }

    private enum WeatherInfoCodingKeys: String, CodingKey {
        case conditionId = "id", conditionNames = "main", conditionDescription = "description", icon = "icon"
    }

    private enum PrecipitationCodingKeys: String, CodingKey {
        case lastHour = "1h"
    }
}