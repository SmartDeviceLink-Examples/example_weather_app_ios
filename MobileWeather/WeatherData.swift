//
//  WeatherData.swift
//  MobileWeather
//
//  Created by Joel Fischer on 9/17/21.
//  Copyright © 2021 Ford. All rights reserved.
//

import CoreLocation
import Foundation

struct WeatherData: Decodable {
    let location: CLLocationCoordinate2D
    let current: CurrentForecast
    let minutely: [MinutelyForecast]
    let hourly: [HourlyForecast]
    let daily: [DailyForecast]
    let alerts: [WeatherAlert]

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        location = CLLocationCoordinate2D(latitude: try values.decode(Double.self, forKey: .lat), longitude: try values.decode(Double.self, forKey: .lon))
        current = try values.decode(CurrentForecast.self, forKey: .current)
        minutely = try values.decode([MinutelyForecast].self, forKey: .minutely)
        hourly = try values.decode([HourlyForecast].self, forKey: .hourly)
        daily = try values.decode([DailyForecast].self, forKey: .daily)
        alerts = try values.decode([WeatherAlert].self, forKey: .alerts)
    }

    enum CodingKeys: String, CodingKey {
        case lat, lon, current, minutely, hourly, daily, alerts
    }
}
