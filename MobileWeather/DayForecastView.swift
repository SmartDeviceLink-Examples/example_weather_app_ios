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
        VStack(alignment: .leading) {
            Text(DayForecastView.dayFormatter.string(from: forecast.date))

            HStack {
                let iconName = OpenWeatherIcon(rawValue: forecast.conditionIconNames.first ?? OpenWeatherIcon.clearDay.rawValue)!
                Image(uiImage: WeatherImage.toUIImage(from: iconName, size: .large))
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(width: 30, height: 30)

                Spacer()

                Text(forecast.conditionDescriptions.first!.capitalized)

                Spacer()
                
                Text("\(WeatherView.temperatureFormatter.string(from: forecast.highTemperature)) / \(WeatherView.temperatureFormatter.string(from: forecast.lowTemperature))")
            }
        }
    }
}

struct DayForecastView_Previews: PreviewProvider {
    static var previews: some View {
        DayForecastView(forecast: DailyForecast.testData)
    }
}
