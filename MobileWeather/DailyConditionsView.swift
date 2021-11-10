//
//  DailyConditionsView.swift
//  MobileWeather
//
//  Created by Joel Fischer on 9/21/21.
//  Copyright © 2021 Ford. All rights reserved.
//

import SwiftUI

struct DailyConditionsView: View {
    @State var dailyForecast: [DailyForecast]?

    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct DailyConditionsView_Previews: PreviewProvider {
    static var previews: some View {
        let json = Bundle.main.url(forResource: "weather-api-response", withExtension: "json")!
        let jsonData = try! Data(contentsOf: json)
        let data = try! JSONDecoder().decode(WeatherData.self, from: jsonData)

        DailyConditionsView(dailyForecast: [])
    }
}