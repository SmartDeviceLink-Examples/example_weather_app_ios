//
//  WeatherView.swift
//  MobileWeather
//
//  Created by Joel Fischer on 9/21/21.
//  Copyright © 2021 Ford. All rights reserved.
//

import SwiftUI

struct WeatherView: View {
    @EnvironmentObject var weatherManager: WeatherManager

    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 12) {
                CurrentConditionsView(currentForecast: weatherManager.weatherData?.current)
                HourlyConditionsView(hourlyForecast: weatherManager.weatherData?.hourly)
                DailyConditionsView(dailyForecast: weatherManager.weatherData?.daily)
            }
        }
    }
}

struct WeatherView_Previews: PreviewProvider {
    static var previews: some View {
        WeatherView()
    }
}
