//
//  SDLWeatherWidgetEntryView.swift
//  MobileWeather
//
//  Created by Joel Fischer on 12/6/21.
//  Copyright © 2021 Ford. All rights reserved.
//

import SwiftUI
import WidgetKit

struct SDL_Weather_WidgetEntryView : View {
    var entry: WeatherDataTimelineProvider.Entry

    var body: some View {
        VStack {
            HStack(alignment: .center, spacing: 15) {
                let iconName = OpenWeatherIcon(rawValue: entry.currentData.conditionIconNames.first!)!
                WeatherImageView(openWeatherName: iconName)
                    .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.currentData.conditionDescriptions.first!.capitalized)
                        .font(.callout)

                    HStack {
                        Image(systemName: "thermometer")
                        Text(WeatherFormatter.temperatureFormatter.string(from: entry.currentData.temperature))
                    }
                    .font(.callout)

                    HStack {
                        Image(systemName: "wind")
                        Text(WeatherFormatter.speedFormatter.string(from: entry.currentData.windSpeed))
                    }
                    .font(.callout)
                }
            }

            HStack(alignment: .center, spacing: 25) {
                ForEach(Array(entry.hourlyData.prefix(5))) { hourlyForecast in
                    HourForecastWidgetView(forecast: hourlyForecast)
                }
            }
        }
    }
}

struct SDL_Weather_Widget_Previews: PreviewProvider {
    static var previews: some View {
        SDL_Weather_WidgetEntryView(entry: HourlyWeatherDataEntry(date: Date(), currentData: WeatherData.testData.current, hourlyData: WeatherData.testData.hourly, configuration: ConfigurationIntent()))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
