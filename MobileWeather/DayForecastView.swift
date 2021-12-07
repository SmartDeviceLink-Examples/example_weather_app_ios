//
//  DayForecastView.swift
//  MobileWeather
//
//  Created by Joel Fischer on 12/2/21.
//  Copyright © 2021 Ford. All rights reserved.
//

import SwiftUI

struct DayForecastView: View {
    let forecast: DailyForecast

    static private let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .none
        f.doesRelativeDateFormatting = true
        f.setLocalizedDateFormatFromTemplate("EE MM d")

        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(DayForecastView.dayFormatter.string(from: forecast.date))
                .font(.subheadline)

            HStack {
                let iconName = OpenWeatherIcon(rawValue: forecast.conditionIconNames.first ?? OpenWeatherIcon.clearDay.rawValue)!
                WeatherImageView(openWeatherName: iconName)
                    .frame(width: 30, height: 30)

                Spacer()

                Text(forecast.conditionDescriptions.first!.capitalized)

                Spacer()

                HStack(alignment: .center, spacing: 4) {
                    HStack(alignment: .center, spacing: 0) {
                        Image(systemName: "arrow.up")
                            .foregroundColor(.red)
                        Text(WeatherFormatter.temperatureFormatter.string(from: forecast.highTemperature))
                    }

                    HStack(alignment: .center, spacing: 0) {
                        Image(systemName: "arrow.down")
                            .foregroundColor(.blue)
                        Text(WeatherFormatter.temperatureFormatter.string(from: forecast.lowTemperature))
                    }
                }
                .font(.subheadline)
            }
        }
    }
}

struct DayForecastView_Previews: PreviewProvider {
    static var previews: some View {
        DayForecastView(forecast: DailyForecast.testData)
    }
}
