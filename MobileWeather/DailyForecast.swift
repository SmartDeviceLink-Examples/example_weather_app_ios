//
//  DailyForecast.swift
//  MobileWeather
//
//  Created by Joel Fischer on 11/10/21.
//  Copyright © 2021 Ford. All rights reserved.
//

import Foundation

struct DailyForecast: Equatable, Hashable, Decodable {
    let date: Date
    let sunriseDate: Date
    let sunsetDate: Date
    let lowTemperature: Measurement<UnitTemperature>
    let highTemperature: Measurement<UnitTemperature>
    let windSpeed: Measurement<UnitSpeed>
    let windGust: Measurement<UnitSpeed>?
    let rainAmount: Measurement<UnitLength>
    let snowAmount: Measurement<UnitLength>
    let precipitationChance: Double

    let conditionDescriptions: [String]
    let conditionIconNames: [String]

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        date = try values.decode(Date.self, forKey: .date)
        sunriseDate = try values.decode(Date.self, forKey: .sunriseDate)
        sunsetDate = try values.decode(Date.self, forKey: .sunsetDate)

        let temperatureValues = try values.nestedContainer(keyedBy: TemperatureCodingKeys.self, forKey: .temperature)
        lowTemperature = Measurement(value: try temperatureValues.decode(Double.self, forKey: .low), unit: UnitTemperature.kelvin)
        highTemperature = Measurement(value: try temperatureValues.decode(Double.self, forKey: .high), unit: UnitTemperature.kelvin)

        windSpeed = Measurement(value: try values.decode(Double.self, forKey: .windSpeed), unit: UnitSpeed.metersPerSecond)
        if let gustRawValue = try values.decodeIfPresent(Double.self, forKey: .windGust) {
            windGust = Measurement(value: gustRawValue, unit: UnitSpeed.metersPerSecond)
        } else {
            windGust = nil
        }

        precipitationChance = try values.decode(Double.self, forKey: .precipitationChance)
        if let rainRawValue = try values.decodeIfPresent(Double.self, forKey: .rainAmount) {
            rainAmount = Measurement(value: rainRawValue, unit: UnitLength.millimeters)
        } else {
            rainAmount = Measurement(value: 0.0, unit: UnitLength.millimeters)
        }

        if let snowRawValue = try values.decodeIfPresent(Double.self, forKey: .snowAmount) {
            snowAmount = Measurement(value: snowRawValue, unit: UnitLength.millimeters)
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
        case date = "dt", rainAmount = "rain", snowAmount = "snow", sunriseDate = "sunrise", sunsetDate = "sunset", temperature = "temp", uvIndex = "uvi", windSpeed = "wind_speed", windGust = "wind_gust", precipitationChance = "pop", weatherInfo = "weather"
    }

    private enum WeatherInfoCodingKeys: String, CodingKey {
        case conditionId = "id", conditionNames = "main", conditionDescription = "description", icon = "icon"
    }

    private enum TemperatureCodingKeys: String, CodingKey {
        case morning = "morn", day, evening = "eve", night = "night", low = "min", high = "max"
    }
}
