//
//  DailyForecast.swift
//  MobileWeather
//
//  Created by Joel Fischer on 11/10/21.
//  Copyright © 2021 Ford. All rights reserved.
//

import Foundation

struct DailyForecast: Identifiable, Equatable, Hashable, Decodable {
    var id: Int { return Int(date.timeIntervalSinceReferenceDate) }

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

    init(date: Date, sunriseDate: Date, sunsetDate: Date, lowTemperature: Measurement<UnitTemperature>, highTemperature: Measurement<UnitTemperature>, windSpeed: Measurement<UnitSpeed>, windGust: Measurement<UnitSpeed>?, rainAmount: Measurement<UnitLength>, snowAmount: Measurement<UnitLength>, precipitationChance: Double, conditionDescriptions: [String], conditionIconNames: [String]) {
        self.date = date; self.sunriseDate = sunriseDate; self.sunsetDate = sunsetDate; self.lowTemperature = lowTemperature; self.highTemperature = highTemperature; self.windSpeed = windSpeed; self.windGust = windGust; self.rainAmount = rainAmount; self.snowAmount = snowAmount; self.precipitationChance = precipitationChance; self.conditionDescriptions = conditionDescriptions; self.conditionIconNames = conditionIconNames;
    }

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

extension DailyForecast {
    static var testData: [DailyForecast] = {
        var testDataArray = [DailyForecast]()

        let sunriseDate = DateComponents(calendar: Calendar.current, timeZone: TimeZone.current, year: 2021, month: 12, day: 2, hour: 7, minute: 51, second: 1).date!
        let sunsetDate = DateComponents(calendar: Calendar.current, timeZone: TimeZone.current, year: 2021, month: 12, day: 2, hour: 20, minute: 2, second: 1).date!
        let testData = DailyForecast(date: Date(), sunriseDate: sunriseDate, sunsetDate: sunsetDate, lowTemperature: Measurement<UnitTemperature>(value: 61, unit: .fahrenheit), highTemperature: Measurement<UnitTemperature>(value: 80, unit: .fahrenheit), windSpeed: Measurement<UnitSpeed>(value: 15, unit: .milesPerHour), windGust: Measurement<UnitSpeed>(value: 25, unit: .milesPerHour), rainAmount: Measurement<UnitLength>(value: 0.1, unit: .inches), snowAmount: Measurement<UnitLength>(value: 0, unit: .inches), precipitationChance: 0.2, conditionDescriptions: ["overcast and rainy"], conditionIconNames: [OpenWeatherIcon.rainDay.rawValue])
        testDataArray.append(testData)

        let sunriseDate2 = DateComponents(calendar: Calendar.current, timeZone: TimeZone.current, year: 2021, month: 12, day: 3, hour: 7, minute: 51, second: 1).date!
        let sunsetDate2 = DateComponents(calendar: Calendar.current, timeZone: TimeZone.current, year: 2021, month: 12, day: 3, hour: 20, minute: 2, second: 1).date!
        let testData2 = DailyForecast(date: Date(), sunriseDate: sunriseDate2, sunsetDate: sunsetDate2, lowTemperature: Measurement<UnitTemperature>(value: 84, unit: .fahrenheit), highTemperature: Measurement<UnitTemperature>(value: 102, unit: .fahrenheit), windSpeed: Measurement<UnitSpeed>(value: 15, unit: .milesPerHour), windGust: Measurement<UnitSpeed>(value: 3, unit: .milesPerHour), rainAmount: Measurement<UnitLength>(value: 2.2, unit: .inches), snowAmount: Measurement<UnitLength>(value: 0, unit: .inches), precipitationChance: 0.95, conditionDescriptions: ["Light Rain"], conditionIconNames: [OpenWeatherIcon.lightRainDay.rawValue])
        testDataArray.append(testData2)

        return testDataArray
    }()
}
