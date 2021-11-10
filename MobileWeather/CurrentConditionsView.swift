//
//  CurrentConditionsView.swift
//  MobileWeather
//
//  Created by Joel Fischer on 9/21/21.
//  Copyright © 2021 Ford. All rights reserved.
//

import SwiftUI

struct CurrentConditionsView: View {
    @State var currentForecast: CurrentForecast?

    var body: some View {
        Text(currentForecast?.conditionDescriptions.first ?? "Unknown")
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
