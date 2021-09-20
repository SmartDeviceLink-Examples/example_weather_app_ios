//
//  WeatherAlert.swift
//  MobileWeather
//
//  Created by Joel Fischer on 6/7/21.
//  Copyright © 2021 Ford. All rights reserved.
//

import Foundation

struct WeatherAlert: Equatable, Decodable {
    let senderName: String
    let event: String
    let description: String
    let startDate: Date
    let endDate: Date
    let tags: [String]

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        senderName = try values.decode(String.self, forKey: .senderName)
        event = try values.decode(String.self, forKey: .event)
        description = try values.decode(String.self, forKey: .description)
        startDate = try values.decode(Date.self, forKey: .startDate)
        endDate = try values.decode(Date.self, forKey: .endDate)
        tags = try values.decode([String].self, forKey: .tags)
    }

    enum CodingKeys: String, CodingKey {
        case senderName = "sender_name", event, startDate = "start", endDate = "end", description, tags
    }
}
