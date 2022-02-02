//
//  WeatherImage.swift
//  MobileWeather
//
//  Created by Joel Fischer on 11/10/21.
//  Copyright © 2021 Ford. All rights reserved.
//

import Foundation
import SwiftUI
import UIKit

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
    static func toUIImage(from openWeatherName: OpenWeatherIcon, size: WeatherImageSize) -> UIImage {
        return Self.systemImage(from: openWeatherName).applyingSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: size.pointSize))!
    }

    static private func systemImage(from openWeatherName: OpenWeatherIcon) -> UIImage {
        switch openWeatherName {
        case .clearDay: return UIImage(systemName: "sun.max.fill")!.withRenderingMode(.alwaysOriginal)
        case .clearNight: return UIImage(systemName: "moon.stars.fill", withConfiguration: UIImage.SymbolConfiguration(paletteColors: [.label, .systemYellow]))!
        case .partlyCloudyDay, .mostlyCloudyDay: return UIImage(systemName: "cloud.sun.fill", withConfiguration: UIImage.SymbolConfiguration(paletteColors: [.systemGray, .systemYellow]))!
        case .partlyCloudyNight, .mostlyCloudyNight: return UIImage(systemName: "cloud.moon.fill", withConfiguration: UIImage.SymbolConfiguration(paletteColors: [.systemGray, .label]))!
        case .cloudyDay, .cloudyNight: return UIImage(systemName: "cloud.fill")!.withTintColor(.systemGray)
        case .lightRainDay: return UIImage(systemName: "cloud.sun.rain.fill", withConfiguration: UIImage.SymbolConfiguration(paletteColors: [.systemGray, .systemYellow, .systemBlue]))!
        case .lightRainNight: return UIImage(systemName: "cloud.moon.rain.fill", withConfiguration: UIImage.SymbolConfiguration(paletteColors: [.systemGray, .systemYellow, .systemBlue]))!
        case .rainDay, .rainNight: return UIImage(systemName: "cloud.rain.fill", withConfiguration: UIImage.SymbolConfiguration(paletteColors: [.systemGray, .systemBlue]))!
        case .thunderstormDay, .thunderstormNight: return UIImage(systemName: "cloud.bolt.rain.fill", withConfiguration: UIImage.SymbolConfiguration(paletteColors: [.systemGray, .systemBlue]))!
        case .snowDay, .snowNight: return UIImage(systemName: "cloud.snow.fill", withConfiguration: UIImage.SymbolConfiguration(paletteColors: [.systemGray, .label]))!
        case .fogDay: return UIImage(systemName: "sun.haze.fill", withConfiguration: UIImage.SymbolConfiguration(paletteColors: [.systemGray, .systemYellow]))!
        case .fogNight: return UIImage(systemName: "cloud.fog.fill", withConfiguration: UIImage.SymbolConfiguration(paletteColors: [.systemGray, .label]))!
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
