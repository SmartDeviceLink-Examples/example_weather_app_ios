//
//  WeatherAlert.swift
//  MobileWeather
//
//  Created by Joel Fischer on 6/7/21.
//  Copyright © 2021 Ford. All rights reserved.
//

import Foundation

struct WeatherAlert: Equatable, Decodable {
    let tags: [String]
    let senderName: String
    let event: String
    let description: String
    let start: Date
    let end: Date
}
