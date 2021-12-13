//
//  WeatherLocation.swift
//  WeatherLocationService
//
//  Created by Joel Fischer on 6/7/21.
//  Copyright © 2021 Ford. All rights reserved.
//

import CoreLocation
import Foundation

public struct WeatherLocation {
    let country: String?
    let state: String?
    let city: String?
    let zipCode: String?
    let gpsLocation: CLLocation
}
