//
//  HourlyConditionsView.swift
//  MobileWeather
//
//  Created by Joel Fischer on 9/21/21.
//  Copyright © 2021 Ford. All rights reserved.
//

import SwiftUI

struct HourlyConditionsView: View {
    var hourlyForecast: [HourlyForecast]

    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(hourlyForecast) { forecast in
                    HourForecastView(forecast: forecast)
                }
            }
        }
    }
}

struct HourlyConditionsView_Previews: PreviewProvider {
    static var previews: some View {
        let json = Bundle.main.url(forResource: "weather-api-response", withExtension: "json")!
        let jsonData = try! Data(contentsOf: json)
        let data = try! JSONDecoder().decode(WeatherData.self, from: jsonData)

        HourlyConditionsView(hourlyForecast: data.hourly)
    }
}
