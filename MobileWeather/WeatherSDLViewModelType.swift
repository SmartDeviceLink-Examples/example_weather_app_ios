//
//  WeatherSDLViewModelType.swift
//  MobileWeather
//
//  Created by Joel Fischer on 11/18/21.
//  Copyright © 2021 Ford. All rights reserved.
//

import SmartDeviceLink

protocol WeatherSDLViewModelType {
    var text1: String { get }
    var text2: String { get }
    var text3: String { get }
    var text4: String { get }
    var artwork1: SDLArtwork { get }
}
