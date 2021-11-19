//
//  WeatherSDLViewModelType.swift
//  MobileWeather
//
//  Created by Joel Fischer on 11/18/21.
//  Copyright © 2021 Ford. All rights reserved.
//

import SmartDeviceLink

protocol WeatherSDLViewModelType {
    var dateText: String { get }
    var temperatureText: String { get }
    var conditionText: String { get }
    var additionalText: String { get }
    var artwork1: SDLArtwork { get }
}
