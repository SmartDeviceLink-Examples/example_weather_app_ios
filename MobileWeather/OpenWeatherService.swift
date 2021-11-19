//
//  WeatherService.swift
//  MobileWeather
//
//  Created by Joel Fischer on 9/17/21.
//  Copyright © 2021 Ford. All rights reserved.
//

import Foundation
import SmartDeviceLink

class OpenWeatherService: NSObject {
    static private let baseURLFormat = "https://api.openweathermap.org/data/2.5/onecall?lat=%@&lon=%@&appid=%@"

    private var apiKey: String?
    private var currentURLTask: URLSessionTask?

    func updateWeatherData(location: WeatherLocation) async {
        guard let apiKey = apiKey else { fatalError("API Key must exist") }

        let urlString = String(format: OpenWeatherService.baseURLFormat, arguments: [location.gpsLocation.coordinate.latitude, location.gpsLocation.coordinate.longitude, apiKey])
        let url = URL(string: urlString)!

        currentURLTask = URLSession.shared.dataTask(with: url, completionHandler: { data, response, error in
            if let error = error {
                SDLLog.e("Error retrieving weather data: \(error)")
                return
            } else if let data = data {
                do {
                    let weatherData = try JSONDecoder().decode(WeatherData.self, from: data)
                    SDLLog.d("Downloaded new weather data: \(weatherData)")
                    NotificationCenter.default.post(name: .weatherDataUpdate, object: self, userInfo: ["data": weatherData])
                } catch {
                    fatalError("Unable to decode weather data: \(error)")
                }
            }
        })
        currentURLTask?.resume()
    }
}

extension OpenWeatherService: URLSessionTaskDelegate {

}
