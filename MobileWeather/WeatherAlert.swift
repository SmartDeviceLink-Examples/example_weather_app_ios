//
//  WeatherAlert.swift
//  MobileWeather
//
//  Created by Joel Fischer on 6/7/21.
//  Copyright © 2021 Ford. All rights reserved.
//

import Foundation

struct WeatherAlert: Equatable {
    let alertType: WeatherAlertType
    let title: String
    let text: String
    let dateIssued: Date
    let dateExpires: Date
}
