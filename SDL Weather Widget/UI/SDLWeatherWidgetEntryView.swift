//
//  SDLWeatherWidgetEntryView.swift
//  MobileWeather
//
//  Created by Joel Fischer on 12/6/21.
//  Copyright © 2021 Ford. All rights reserved.
//

import SwiftUI

struct SDL_Weather_WidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack {
            HStack(alignment: .center, spacing: 15) {
                let iconName = OpenWeatherIcon(rawValue: entry.data.current.conditionIconNames.first!)!
                WeatherImageView(openWeatherName: iconName)
                    .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.data.current.conditionDescriptions.first!)
                        .font(.callout)

                    HStack {
                        Image(systemName: "thermometer")
                        Text(entry.data.current.temperature.formatted())
                    }
                    .font(.callout)

                    HStack {
                        Image(systemName: "wind")
                        Text(entry.data.current.windSpeed.formatted())
                    }
                    .font(.callout)
                }
            }

            HStack(alignment: .center, spacing: 25) {
                ForEach(Array(entry.data.hourly.prefix(5))) { hourlyForecast in
                    HourForecastWidgetView(forecast: hourlyForecast)
                }
            }
        }
    }
}

struct SDL_Weather_Widget_Previews: PreviewProvider {
    static var previews: some View {
        SDL_Weather_WidgetEntryView(entry: WeatherDataEntry(date: Date(), data: WeatherData.testData, configuration: ConfigurationIntent()))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
