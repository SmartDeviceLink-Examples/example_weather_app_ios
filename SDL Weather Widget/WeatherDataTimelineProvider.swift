//
//  WeatherDataTimelineProvider.swift
//  MobileWeather
//
//  Created by Joel Fischer on 1/3/22.
//  Copyright © 2022 Ford. All rights reserved.
//

import Intents
import WidgetKit

struct HourlyWeatherDataEntry: TimelineEntry {
    let date: Date
    let currentData: CurrentForecast
    let hourlyData: [HourlyForecast]
    let configuration: ConfigurationIntent
}

struct WeatherDataTimelineProvider: IntentTimelineProvider {
    var serverWeatherData = WeatherDataWrapper()

    init() {
        WeatherService.shared.start()
    }

    func placeholder(in context: Context) -> HourlyWeatherDataEntry {
        HourlyWeatherDataEntry(date: Date(), currentData: WeatherData.testData.current, hourlyData: WeatherData.testData.hourly, configuration: ConfigurationIntent())
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (HourlyWeatherDataEntry) -> ()) {
        let entry: HourlyWeatherDataEntry
        if let weatherData = serverWeatherData.data {
            entry = HourlyWeatherDataEntry(date: weatherData.current.date, currentData: weatherData.current, hourlyData: weatherData.hourly, configuration: configuration)
        } else {
            entry = HourlyWeatherDataEntry(date: Date(), currentData: WeatherData.testData.current, hourlyData: WeatherData.testData.hourly, configuration: configuration)
        }

        completion(entry)
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<HourlyWeatherDataEntry>) -> ()) {
        Task.init { () -> Void in
            guard let data = await WeatherService.shared.retrieveWeatherData(location: WeatherLocation(country: nil, state: nil, city: nil, zipCode: nil, gpsLocation: CLLocation(latitude: 42.4829483, longitude: -83.1426719))) else {
                let errorTimeline = Timeline(entries: [HourlyWeatherDataEntry(date: Date(), currentData: WeatherData.testData.current, hourlyData: WeatherData.testData.hourly, configuration: configuration)], policy: .after(Calendar.current.date(byAdding: .minute, value: 5, to: Date())!))
                return completion(errorTimeline)
            }
            serverWeatherData.data = data

            var entries: [HourlyWeatherDataEntry] = []
            // First item uses actual current data
            let firstEntry = HourlyWeatherDataEntry(date: data.current.date, currentData: data.current, hourlyData: data.hourly, configuration: configuration)
            entries.append(firstEntry)

            for i in 1..<4 {
                let currentHour = data.hourly[i]
                let currentData = CurrentForecast(date: currentHour.date, sunriseDate: data.current.sunriseDate, sunsetDate: data.current.sunsetDate, temperature: currentHour.temperature, feelsLikeTemperature: currentHour.feelsLikeTemperature, uvIndex: currentHour.uvIndex, visibility: currentHour.visibility, windSpeed: currentHour.windSpeed, windGust: currentHour.windGust, conditionDescriptions: currentHour.conditionDescriptions, conditionIconNames: currentHour.conditionIconNames)
                let entry = HourlyWeatherDataEntry(date: currentData.date, currentData: currentData, hourlyData: Array(data.hourly.dropFirst(i)), configuration: configuration)
                entries.append(entry)
            }

            // Update after an hour if possible
            let timeline = Timeline(entries: entries, policy: .after(Calendar.current.date(byAdding: .hour, value: 1, to: Date())!))
            completion(timeline)
        }
    }
}
