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
    var text1: String
    var text2: String
    var text3: String
    var text4: String
    var artwork1: SDLArtwork

    private static let alertDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        f.doesRelativeDateFormatting = true

        return f
    }()

    init(alert: WeatherAlert) {
        text1 = alert.event
        text2 = "Starts: \(WeatherAlertSDLViewModel.alertDateFormatter.string(from: alert.startDate))"
        text3 = "Ends: \(WeatherAlertSDLViewModel.alertDateFormatter.string(from: alert.endDate))"
        text4 = alert.description
        artwork1 = SDLArtwork(image: UIImage(systemName: "exclamationmark.triangle")!, persistent: true, as: .PNG)
    }
}
