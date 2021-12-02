//
//  WeatherView.swift
//  MobileWeather
//
//  Created by Joel Fischer on 9/21/21.
//  Copyright © 2021 Ford. All rights reserved.
//

import CoreLocation
import SwiftUI

struct WeatherView: View {
    @ObservedObject private var weatherManager = WeatherService.shared

    static var temperatureFormatter: MeasurementFormatter = {
        let m = MeasurementFormatter()
        m.numberFormatter.maximumFractionDigits = 0
        return m
    }()

    var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif

        NavigationView {
            ScrollView {
                VStack(alignment: .center, spacing: 12) {
                    CurrentConditionsView(currentForecast: weatherManager.weatherData.current)
                        .padding(.horizontal)
                    HourlyConditionsView(hourlyForecast: Array(weatherManager.weatherData.hourly.prefix(12)))
                        .padding(.horizontal)
                    DailyConditionsView(dailyForecast: Array(weatherManager.weatherData.daily.dropFirst().prefix(7)))
                        .padding(.horizontal)
                }
            }
            .redacted(reason: (weatherManager.lastUpdateTime == nil) ? .placeholder : [])
        }
    }
}

struct WeatherView_Previews: PreviewProvider {
    static var testWeatherManager: WeatherService {
        let json = Bundle.main.url(forResource: "weather-api-response", withExtension: "json")!
        let jsonData = try! Data(contentsOf: json)
        let data = try! JSONDecoder().decode(WeatherData.self, from: jsonData)

        let testWeatherManager = WeatherService()
        testWeatherManager.currentLocation = WeatherLocation(country: "United States", state: "Michigan", city: "Royal Oak", zipCode: "", gpsLocation: CLLocation(latitude: 2.0, longitude: 2.0))
        testWeatherManager.weatherData = data
        testWeatherManager.lastUpdateTime = Date()

        return testWeatherManager
    }

    static var previews: some View {
        WeatherView().environmentObject(testWeatherManager)
    }
}
