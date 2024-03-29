//
//  WeatherConditions.swift
//  WeatherDataService
//
//  Created by Joel Fischer on 6/7/21.
//  Copyright © 2021 Ford. All rights reserved.
//

import Foundation

struct CurrentForecast: Equatable, Hashable, Decodable {
    let date: Date
    let sunriseDate: Date
    let sunsetDate: Date
    let temperature: Measurement<UnitTemperature>
    let feelsLikeTemperature: Measurement<UnitTemperature>
    let uvIndex: Double
    let visibility: Measurement<UnitLength>
    let windSpeed: Measurement<UnitSpeed>
    let windGust: Measurement<UnitSpeed>?
    let conditionDescriptions: [String]
    let conditionIconNames: [String]

    init() {
        date = Date()
        sunriseDate = Date()
        sunsetDate = Date()
        temperature = Measurement<UnitTemperature>(value: 0.0, unit: .fahrenheit)
        feelsLikeTemperature = Measurement<UnitTemperature>(value: 0.0, unit: .fahrenheit)
        uvIndex = 0.0
        visibility = Measurement<UnitLength>(value: 0.0, unit: .miles)
        windSpeed = Measurement<UnitSpeed>(value: 0.0, unit: .milesPerHour)
        windGust = nil
        conditionDescriptions = ["Sunny"]
        conditionIconNames = [OpenWeatherIcon.clearDay.rawValue]
    }

    init(date: Date, sunriseDate: Date, sunsetDate: Date, temperature: Measurement<UnitTemperature>, feelsLikeTemperature: Measurement<UnitTemperature>, uvIndex: Double, visibility: Measurement<UnitLength>, windSpeed: Measurement<UnitSpeed>, windGust: Measurement<UnitSpeed>?, conditionDescriptions: [String], conditionIconNames: [String]) {
        self.date = date
        self.sunriseDate = sunriseDate
        self.sunsetDate = sunsetDate
        self.temperature = temperature
        self.feelsLikeTemperature = feelsLikeTemperature
        self.uvIndex = uvIndex
        self.visibility = visibility
        self.windSpeed = windSpeed
        self.windGust = windGust
        self.conditionDescriptions = conditionDescriptions
        self.conditionIconNames = conditionIconNames
    }

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

        if let gustRawValue = try values.decodeIfPresent(Double.self, forKey: .windGust) {
            windGust = Measurement(value: gustRawValue, unit: UnitSpeed.metersPerSecond)
        } else {
            windGust = nil
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
        case date = "dt", sunriseDate = "sunrise", sunsetDate = "sunset", temperature = "temp", feelsLikeTemperature = "feels_like", uvIndex = "uvi", visibility, windSpeed = "wind_speed", windGust = "wind_gust", weatherInfo = "weather"
    }

    private enum WeatherInfoCodingKeys: String, CodingKey {
        case conditionId = "id", conditionNames = "main", conditionDescription = "description", icon = "icon"
    }
}
