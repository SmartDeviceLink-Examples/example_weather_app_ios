//
//  CurrentConditionsView.swift
//  MobileWeather
//
//  Created by Joel Fischer on 9/21/21.
//  Copyright © 2021 Ford. All rights reserved.
//

import SwiftUI

struct CurrentConditionsView: View {
    var currentForecast: CurrentForecast

    var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif

        VStack {
            HStack(alignment: .center, spacing: 10) {
                let iconName = OpenWeatherIcon(rawValue: currentForecast.conditionIconNames.first ?? OpenWeatherIcon.clearDay.rawValue)!
                Image(uiImage: WeatherImage.toUIImage(from: iconName, size: .large))
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(width: 80, height: 80)

                Spacer()

                VStack(alignment: .trailing, spacing: 10) {
                    Text(WeatherView.temperatureFormatter.string(from: currentForecast.temperature))
                        .font(.title)
                        .fontWeight(.bold)
                    HStack {
                        Image(systemName: "wind")
                        Text(currentForecast.windSpeed.formatted())
                    }
                    HStack {
                        Image(systemName: "sunrise")
                        Text(currentForecast.sunriseDate.formatted(date: .omitted, time: .shortened))
                    }
                    HStack {
                        Image(systemName: "sunset")
                        Text(currentForecast.sunsetDate.formatted(date: .omitted, time: .shortened))
                    }
                    Text("UV Index: \(Int(currentForecast.uvIndex.rounded()))")
                }
            }
            Text(currentForecast.conditionDescriptions.first?.localizedCapitalized ?? "Unknown")
                .font(.title2)
                .fontWeight(.medium)
        }
    }
}

struct CurrentConditionsView_Previews: PreviewProvider {
    static var previews: some View {
        let json = Bundle.main.url(forResource: "weather-api-response", withExtension: "json")!
        let jsonData = try! Data(contentsOf: json)
        let data = try! JSONDecoder().decode(WeatherData.self, from: jsonData)

        CurrentConditionsView(currentForecast: data.current)
    }
}
