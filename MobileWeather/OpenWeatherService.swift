//
//  WeatherService.swift
//  MobileWeather
//
//  Created by Joel Fischer on 9/17/21.
//  Copyright © 2021 Ford. All rights reserved.
//

import Foundation

enum OpenWeatherService {
    static func updateWeatherData(location: WeatherLocation) async -> WeatherData? {
        guard !APIKeys.openWeatherKey.isEmpty else { fatalError("The API Key is empty. Please retrieve an API key from https://home.openweathermap.org/api_keys") }

        let urlString = "https://api.openweathermap.org/data/2.5/onecall?lat=\(location.gpsLocation.coordinate.latitude)&lon=\(location.gpsLocation.coordinate.longitude)&appid=\(APIKeys.openWeatherKey)"
        let url = URL(string: urlString)!

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            print("Received OpenWeather Response: \((response as! HTTPURLResponse).statusCode)")

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970

            return try decoder.decode(WeatherData.self, from: data)
        } catch let error {
            print("Failed to retrieve data or convert to weather data: \(error)")
            return nil
        }
    }
}
