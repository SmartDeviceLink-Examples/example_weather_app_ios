//
//  WeatherMinutelyData.swift
//  MobileWeather
//
//  Created by Joel Fischer on 9/17/21.
//  Copyright © 2021 Ford. All rights reserved.
//

import Foundation

struct WeatherMinutelyData: Decodable {
    let date: Date
    let precipitationVolume: Measurement<UnitVolume>

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        date = try values.decode(Date.self, forKey: .date)
        precipitationVolume = Measurement(value: try values.decode(Double.self, forKey: .precipitationVolume), unit: UnitVolume.cubicMillimeters)
    }

    enum CodingKeys: String, CodingKey {
        case date = "dt", precipitationVolume = "precipitation"
    }
}
