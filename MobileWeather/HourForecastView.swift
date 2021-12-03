//
//  HourForecastView.swift
//  MobileWeather
//
//  Created by Joel Fischer on 12/2/21.
//  Copyright © 2021 Ford. All rights reserved.
//

import SwiftUI

struct HourForecastView: View {
    let forecast: HourlyForecast

    private static var hourDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.doesRelativeDateFormatting = false
        f.setLocalizedDateFormatFromTemplate("h a")

        return f
    }()

    var body: some View {
        VStack {
            let iconName = OpenWeatherIcon(rawValue: forecast.conditionIconNames.first ?? OpenWeatherIcon.clearDay.rawValue)!
            WeatherImageView(openWeatherName: iconName)
                .frame(width: 40, height: 40)

            Text(WeatherView.temperatureFormatter.string(from: forecast.temperature))
            Text(HourForecastView.hourDateFormatter.string(from: forecast.date))
                .font(.subheadline)
        }
    }
}

struct HourForecastView_Previews: PreviewProvider {
    static var previews: some View {
        HourForecastView(forecast: HourlyForecast.testData)
    }
}
