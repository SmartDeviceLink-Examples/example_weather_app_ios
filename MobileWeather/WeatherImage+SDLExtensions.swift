//
//  WeatherImage+SDLExtensions.swift
//  MobileWeather
//
//  Created by Joel Fischer on 12/6/21.
//  Copyright © 2021 Ford. All rights reserved.
//

import Foundation
import SmartDeviceLink

extension WeatherImage {
    static func toSDLArtwork(from openWeatherName: OpenWeatherIcon, size: WeatherImageSize) -> SDLArtwork {
        let image = toUIImage(from: openWeatherName, size: size)

        return SDLArtwork(image: image, name: openWeatherName.rawValue, persistent: true, as: .PNG)
    }
}
