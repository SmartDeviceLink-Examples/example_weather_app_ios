//
//  HourForecastWidgetView.swift
//  MobileWeather
//
//  Created by Joel Fischer on 12/6/21.
//  Copyright © 2021 Ford. All rights reserved.
//

import SwiftUI

struct HourForecastWidgetView: View {
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
                .frame(width: 30, height: 30)

            Text(WeatherFormatter.temperatureFormatter.string(from: forecast.temperature))
                .font(.callout)
            Text(HourForecastWidgetView.hourDateFormatter.string(from: forecast.date))
                .font(.footnote)
        }
    }
}

struct HourForecastWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        HourForecastWidgetView(forecast: HourlyForecast.testData)
    }
}
