//
//  SDL_Weather_Widget.swift
//  SDL Weather Widget
//
//  Created by Joel Fischer on 12/6/21.
//  Copyright © 2021 Ford. All rights reserved.
//

import WidgetKit
import SwiftUI
import Intents

struct Provider: IntentTimelineProvider {
    var serverWeatherData: WeatherData?

    init() {
        WeatherService.shared.start()
    }

    func placeholder(in context: Context) -> WeatherDataEntry {
        WeatherDataEntry(date: Date(), data: WeatherData.testData, configuration: ConfigurationIntent())
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (WeatherDataEntry) -> ()) {
        let entry: WeatherDataEntry

        if let weatherData = serverWeatherData {
            entry = WeatherDataEntry(date: Date(), data: weatherData, configuration: configuration)
        } else {
            entry = WeatherDataEntry(date: Date(), data: WeatherData.testData, configuration: configuration)
        }

        completion(entry)
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<WeatherDataEntry>) -> ()) {
        var entries: [WeatherDataEntry] = []

        Task.init {
            guard let data = await WeatherService.shared.retrieveWeatherData(location: WeatherLocation(country: nil, state: nil, city: nil, zipCode: nil, gpsLocation: CLLocation(latitude: 42.4829483, longitude: -83.1426719))) else {
                let errorTimeline = Timeline(entries: [WeatherDataEntry(date: Date(), data: .testData, configuration: configuration)], policy: .after(Calendar.current.date(byAdding: .minute, value: 5, to: Date())!))
                completion(errorTimeline)
            }

            for hourData in data.hourly {

            }
        }

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = WeatherDataEntry(date: entryDate, data: WeatherData.testData, configuration: configuration)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct WeatherDataEntry: TimelineEntry {
    let date: Date
    let data: WeatherData
    let configuration: ConfigurationIntent
}

@main
struct SDL_Weather_Widget: Widget {
    let kind: String = "SDL_Weather_Widget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            SDL_Weather_WidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Hourly Weather")
        .description("The current and next five hours of weather")
        .supportedFamilies([.systemMedium])
    }
}
