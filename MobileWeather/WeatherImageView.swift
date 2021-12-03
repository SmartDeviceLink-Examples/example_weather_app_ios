//
//  WeatherImageView.swift
//  MobileWeather
//
//  Created by Joel Fischer on 12/3/21.
//  Copyright © 2021 Ford. All rights reserved.
//

import SwiftUI

struct WeatherImageView: View {
    let openWeatherName: OpenWeatherIcon

    var body: some View {
        switch openWeatherName {
        case .clearDay:
            Image(systemName: "sun.max.fill").symbolRenderingMode(.multicolor).resizable().scaledToFit()
        case .clearNight:
            Image(systemName: "moon.stars.fill").symbolRenderingMode(.palette).resizable().scaledToFit().foregroundStyle(.primary, .yellow)
        case .partlyCloudyDay, .mostlyCloudyDay:
            Image(systemName: "cloud.sun.fill").symbolRenderingMode(.palette).resizable().scaledToFit().foregroundStyle(.gray, .yellow)
        case .partlyCloudyNight, .mostlyCloudyNight:
            Image(systemName: "cloud.moon.fill").symbolRenderingMode(.palette).resizable().scaledToFit().foregroundStyle(.gray, .primary)
        case .cloudyDay, .cloudyNight:
            Image(systemName: "cloud.fill").symbolRenderingMode(.monochrome).resizable().scaledToFit().foregroundStyle(.gray)
        case .lightRainDay:
            Image(systemName: "cloud.sun.rain.fill").symbolRenderingMode(.palette).resizable().scaledToFit().foregroundStyle(.gray, .yellow, .blue)
        case .lightRainNight:
            Image(systemName: "cloud.moon.rain.fill").symbolRenderingMode(.palette).resizable().scaledToFit().foregroundStyle(.gray, .yellow, .blue)
        case .rainDay, .rainNight:
            Image(systemName: "cloud.rain.fill").symbolRenderingMode(.palette).resizable().scaledToFit().foregroundStyle(.gray, .blue)
        case .thunderstormDay, .thunderstormNight:
            Image(systemName: "cloud.bolt.rain.fill").symbolRenderingMode(.palette).resizable().scaledToFit().foregroundStyle(.gray, .blue)
        case .snowDay, .snowNight:
            Image(systemName: "cloud.snow.fill").symbolRenderingMode(.palette).resizable().scaledToFit().foregroundStyle(.gray, .primary)
        case .fogDay:
            Image(systemName: "sun.haze.fill").symbolRenderingMode(.palette).resizable().scaledToFit().foregroundStyle(.gray, .yellow)
        case .fogNight:
            Image(systemName: "cloud.fog.fill").symbolRenderingMode(.palette).resizable().scaledToFit().foregroundStyle(.gray, .primary)
        }
    }
}

struct WeatherImageView_Previews: PreviewProvider {
    static var previews: some View {
        WeatherImageView(openWeatherName: OpenWeatherIcon.lightRainDay)
    }
}
