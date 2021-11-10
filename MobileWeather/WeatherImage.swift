//
//  WeatherImage.swift
//  MobileWeather
//
//  Created by Joel Fischer on 11/10/21.
//  Copyright © 2021 Ford. All rights reserved.
//

import Foundation
import UIKit

enum WeatherImage {
    static func fromOpenWeatherName(_ openWeatherName: OpenWeatherIcon) -> UIImage {
        let symbolName: String
        switch openWeatherName {
        case .clearDay:
            symbolName = "sun.max.fill"
        case .clearNight:
            symbolName = "moon.stars.fill"
        case .partlyCloudyDay, .mostlyCloudyDay:
            symbolName = "cloud.sun.fill"
        case .partlyCloudyNight, .mostlyCloudyNight:
            symbolName = "cloud.moon.fill"
        case .cloudyDay, .cloudyNight:
            symbolName = "cloud.fill"
        case .lightRainDay:
            symbolName = "cloud.sun.rain.fill"
        case .lightRainNight:
            symbolName = "cloud.moon.rain.fill"
        case .rainDay, .rainNight:
            symbolName = "cloud.rain.fill"
        case .thunderstormDay, .thunderstormNight:
            symbolName = "cloud.bolt.rain.fill"
        case .snowDay, .snowNight:
            symbolName = "cloud.snow.fill"
        case .fogDay:
            symbolName = "sun.haze.fill"
        case .fogNight:
            symbolName = "cloud.fog.fill"
        }

        return UIImage(systemName: symbolName)!
    }
}

enum OpenWeatherIcon: String {
    case clearDay = "01d", clearNight = "01n"
    case partlyCloudyDay = "02d", partlyCloudyNight = "02n"
    case mostlyCloudyDay = "03d", mostlyCloudyNight = "03n"
    case cloudyDay = "04d", cloudyNight = "04n"
    case lightRainDay = "09d", lightRainNight = "09n"
    case rainDay = "10d", rainNight = "10n"
    case thunderstormDay = "11d", thunderstormNight = "11n"
    case snowDay = "13d", snowNight = "13n"
    case fogDay = "50d", fogNight = "50n"
}
