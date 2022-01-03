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
    var serverWeatherData: WeatherData?

    init() {
        WeatherService.shared.start()
    }

    func placeholder(in context: Context) -> HourlyWeatherDataEntry {
        HourlyWeatherDataEntry(date: Date(), currentData: WeatherData.testData.current, hourlyData: WeatherData.testData.hourly, configuration: ConfigurationIntent())
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (HourlyWeatherDataEntry) -> ()) {
        let entry: HourlyWeatherDataEntry
        if let weatherData = serverWeatherData {
            entry = HourlyWeatherDataEntry(date: weatherData.current.date, currentData: weatherData.current, hourlyData: weatherData.hourly, configuration: configuration)
        } else {
            entry = HourlyWeatherDataEntry(date: Date(), currentData: WeatherData.testData.current, hourlyData: WeatherData.testData.hourly, configuration: configuration)
        }

        completion(entry)
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<HourlyWeatherDataEntry>) -> ()) {
        var entries: [HourlyWeatherDataEntry] = []

        Task.init { () -> Void in
            guard let data = await WeatherService.shared.retrieveWeatherData(location: WeatherLocation(country: nil, state: nil, city: nil, zipCode: nil, gpsLocation: CLLocation(latitude: 42.4829483, longitude: -83.1426719))) else {
                let errorTimeline = Timeline(entries: [HourlyWeatherDataEntry(date: Date(), currentData: WeatherData.testData.current, hourlyData: WeatherData.testData.hourly, configuration: configuration)], policy: .after(Calendar.current.date(byAdding: .minute, value: 5, to: Date())!))
                return completion(errorTimeline)
            }

//            self.serverWeatherData = data
            print("Received data: \(data)")

            for hourData in data.hourly {
//                let entry = WeatherDataEntry(date: hourData.date, data: <#T##WeatherData#>, configuration: <#T##ConfigurationIntent#>)
            }
        }

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = HourlyWeatherDataEntry(date: entryDate, currentData: WeatherData.testData.current, hourlyData: WeatherData.testData.hourly, configuration: configuration)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}
