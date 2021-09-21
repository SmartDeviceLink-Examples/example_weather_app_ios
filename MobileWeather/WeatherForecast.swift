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
    let conditionDescription: String
    let conditionIconName: String

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        date = try values.decode(Date.self, forKey: .date)
        temperature = Measurement(value: try values.decode(Double.self, forKey: .temperature), unit: UnitTemperature.kelvin)
        feelsLikeTemperature = Measurement(value: try values.decode(Double.self, forKey: .feelsLikeTemperature), unit: UnitTemperature.kelvin)
        uvIndex = try values.decode(Double.self, forKey: .uvIndex)
        visibility = Measurement(value: try values.decode(Double.self, forKey: .visibility), unit: UnitLength.meters)
        windSpeed = Measurement(value: try values.decode(Double.self, forKey: .windSpeed), unit: UnitSpeed.metersPerSecond)
        windGust = Measurement(value: try values.decode(Double.self, forKey: .windGust), unit: UnitSpeed.metersPerSecond)
        precipitationChance = try values.decode(Double.self, forKey: .precipitationChance)

        let rainValues = try values.nestedContainer(keyedBy: PrecipitationCodingKeys.self, forKey: .rainInfo)
        rainAmount = Measurement(value: try rainValues.decode(Double.self, forKey: .lastHour), unit: UnitLength.millimeters)

        let snowValues = try values.nestedContainer(keyedBy: PrecipitationCodingKeys.self, forKey: .snowInfo)
        snowAmount = Measurement(value: try snowValues.decode(Double.self, forKey: .lastHour), unit: UnitLength.millimeters)

        let weatherInfoValues = try values.nestedContainer(keyedBy: WeatherInfoCodingKeys.self, forKey: .weatherInfo)
        conditionDescription = try weatherInfoValues.decode(String.self, forKey: .conditionDescription)
        conditionIconName = try weatherInfoValues.decode(String.self, forKey: .icon)
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

struct DailyForecast: Decodable {
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

    let conditionDescription: String
    let conditionIconName: String

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        date = try values.decode(Date.self, forKey: .date)
        sunriseDate = try values.decode(Date.self, forKey: .sunriseDate)
        sunsetDate = try values.decode(Date.self, forKey: .sunsetDate)

        let temperatureValues = try values.nestedContainer(keyedBy: TemperatureCodingKeys.self, forKey: .temperature)
        lowTemperature = Measurement(value: try temperatureValues.decode(Double.self, forKey: .low), unit: UnitTemperature.kelvin)
        highTemperature = Measurement(value: try temperatureValues.decode(Double.self, forKey: .high), unit: UnitTemperature.kelvin)

        windSpeed = Measurement(value: try values.decode(Double.self, forKey: .windSpeed), unit: UnitSpeed.metersPerSecond)
        windGust = Measurement(value: try values.decode(Double.self, forKey: .windGust), unit: UnitSpeed.metersPerSecond)
        precipitationChance = try values.decode(Double.self, forKey: .precipitationChance)
        rainAmount = Measurement(value: try values.decode(Double.self, forKey: .rainAmount), unit: UnitLength.millimeters)
        snowAmount = Measurement(value: try values.decode(Double.self, forKey: .snowAmount), unit: UnitLength.millimeters)

        let weatherInfoValues = try values.nestedContainer(keyedBy: WeatherInfoCodingKeys.self, forKey: .weatherInfo)
        conditionDescription = try weatherInfoValues.decode(String.self, forKey: .conditionDescription)
        conditionIconName = try weatherInfoValues.decode(String.self, forKey: .icon)
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
