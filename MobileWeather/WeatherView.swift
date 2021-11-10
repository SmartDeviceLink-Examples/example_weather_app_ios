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
    @EnvironmentObject var weatherManager: WeatherManager

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .center, spacing: 12) {
                    CurrentConditionsView(currentForecast: weatherManager.weatherData?.current)
                    HourlyConditionsView(hourlyForecast: weatherManager.weatherData?.hourly)
                    DailyConditionsView(dailyForecast: weatherManager.weatherData?.daily)
                }
            }
        }
    }
}

struct WeatherView_Previews: PreviewProvider {
    static var testWeatherManager: WeatherManager {
        let json = Bundle.main.url(forResource: "weather-api-response", withExtension: "json")!
        let jsonData = try! Data(contentsOf: json)
        let data = try! JSONDecoder().decode(WeatherData.self, from: jsonData)

        let testWeatherManager = WeatherManager()
        testWeatherManager.currentLocation = WeatherLocation(country: "United States", state: "Michigan", city: "Royal Oak", zipCode: "", gpsLocation: CLLocation(latitude: 2.0, longitude: 2.0))
        testWeatherManager.weatherData = data

        return testWeatherManager
    }

    static var previews: some View {
        WeatherView().environmentObject(testWeatherManager)
    }
}
