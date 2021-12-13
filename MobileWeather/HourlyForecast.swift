//
//  WeatherForecast.swift
//  MobileWeather
//
//  Created by Joel Fischer on 6/7/21.
//  Copyright © 2021 Ford. All rights reserved.
//

import Foundation

struct HourlyForecast: Identifiable, Equatable, Hashable, Decodable {
    var id: Int { return Int(date.timeIntervalSinceReferenceDate) }

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

    init(date: Date, temperature: Measurement<UnitTemperature>, feelsLikeTemperature: Measurement<UnitTemperature>, uvIndex: Double, visibility: Measurement<UnitLength>, windSpeed: Measurement<UnitSpeed>, windGust: Measurement<UnitSpeed>?, precipitationChance: Double, rainAmount: Measurement<UnitLength> , snowAmount: Measurement<UnitLength>, conditionDescriptions: [String], conditionIconNames: [String]) {
        self.date = date; self.temperature = temperature; self.feelsLikeTemperature = feelsLikeTemperature; self.uvIndex = uvIndex; self.visibility = visibility; self.windSpeed = windSpeed; self.windGust = windGust; self.precipitationChance = precipitationChance; self.rainAmount = rainAmount; self.snowAmount = snowAmount; self.conditionDescriptions = conditionDescriptions; self.conditionIconNames = conditionIconNames;
    }

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

extension HourlyForecast {
    static var testData: HourlyForecast = {
        let testData = HourlyForecast(date: Date(), temperature: Measurement<UnitTemperature>(value: 61, unit: .fahrenheit), feelsLikeTemperature: Measurement<UnitTemperature>(value: 80, unit: .fahrenheit), uvIndex: 7.0, visibility: Measurement<UnitLength>(value: 1.2, unit: .miles), windSpeed: Measurement<UnitSpeed>(value: 15, unit: .milesPerHour), windGust: Measurement<UnitSpeed>(value: 25, unit: .milesPerHour), precipitationChance: 0.2, rainAmount: Measurement<UnitLength>(value: 0.1, unit: .inches), snowAmount: Measurement<UnitLength>(value: 0, unit: .inches), conditionDescriptions: ["overcast and rainy"], conditionIconNames: [OpenWeatherIcon.lightRainDay.rawValue])

        return testData
    }()
}
