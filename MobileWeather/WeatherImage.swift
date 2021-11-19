//
//  WeatherImage.swift
//  MobileWeather
//
//  Created by Joel Fischer on 11/10/21.
//  Copyright © 2021 Ford. All rights reserved.
//

import Foundation
import UIKit
import SmartDeviceLink

enum WeatherImageSize {
    case large, small

    var pointSize: CGFloat {
        switch self {
        case .large: return 256
        case .small: return 64
        }
    }
}

enum WeatherImage {
    static func toSDLArtwork(from openWeatherName: OpenWeatherIcon, size: WeatherImageSize) -> SDLArtwork {
        let image = toUIImage(from: openWeatherName, size: size)

        return SDLArtwork(image: image, name: openWeatherName.rawValue, persistent: true, as: .PNG)
    }

    static func toUIImage(from openWeatherName: OpenWeatherIcon, size: WeatherImageSize) -> UIImage {
        let systemName = systemImage(from: openWeatherName)

        // TODO: Palatte / Heirarchical colors w/ not template images for some things / on systems we can control the background?
        return UIImage(systemName: systemName, withConfiguration: UIImage.SymbolConfiguration(pointSize: size.pointSize))!.withRenderingMode(.alwaysTemplate)
    }

    static private func systemImage(from openWeatherName: OpenWeatherIcon) -> String {
        switch openWeatherName {
        case .clearDay: return "sun.max.fill"
        case .clearNight: return "moon.stars.fill"
        case .partlyCloudyDay, .mostlyCloudyDay: return "cloud.sun.fill"
        case .partlyCloudyNight, .mostlyCloudyNight: return "cloud.moon.fill"
        case .cloudyDay, .cloudyNight: return "cloud.fill"
        case .lightRainDay: return "cloud.sun.rain.fill"
        case .lightRainNight: return "cloud.moon.rain.fill"
        case .rainDay, .rainNight: return "cloud.rain.fill"
        case .thunderstormDay, .thunderstormNight: return "cloud.bolt.rain.fill"
        case .snowDay, .snowNight: return "cloud.snow.fill"
        case .fogDay: return "sun.haze.fill"
        case .fogNight: return "cloud.fog.fill"
        }
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
