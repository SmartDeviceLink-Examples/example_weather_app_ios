//
//  WeatherAlertSDLViewModel.swift
//  MobileWeather
//
//  Created by Joel Fischer on 11/18/21.
//  Copyright © 2021 Ford. All rights reserved.
//

import Foundation
import SmartDeviceLink

struct WeatherAlertSDLViewModel: WeatherSDLViewModelType {
    var dateText: String
    var temperatureText: String
    var conditionText: String
    var additionalText: String
    var artwork1: SDLArtwork

    private static let alertDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        f.doesRelativeDateFormatting = true

        return f
    }()

    init(alert: WeatherAlert) {
        dateText = alert.event
        temperatureText = "Starts: \(WeatherAlertSDLViewModel.alertDateFormatter.string(from: alert.startDate))"
        conditionText = "Ends: \(WeatherAlertSDLViewModel.alertDateFormatter.string(from: alert.endDate))"
        additionalText = alert.description
        artwork1 = SDLArtwork(image: UIImage(systemName: "exclamationmark.triangle")!, persistent: true, as: .PNG)
    }
}
