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

    var body: some View {
        VStack {
            let iconName = OpenWeatherIcon(rawValue: forecast.conditionIconNames.first ?? OpenWeatherIcon.clearDay.rawValue)!
            Image(uiImage: WeatherImage.toUIImage(from: iconName, size: .large))
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .frame(width: 40, height: 40)

            Text(WeatherView.temperatureFormatter.string(from: forecast.temperature))
            Text(forecast.date.formatted(date: .omitted, time: .shortened))
        }
    }
}

struct HourForecastView_Previews: PreviewProvider {
    static var previews: some View {
        HourForecastView(forecast: HourlyForecast.testData)
    }
}
