//
//  HourlyConditionsView.swift
//  MobileWeather
//
//  Created by Joel Fischer on 9/21/21.
//  Copyright © 2021 Ford. All rights reserved.
//

import SwiftUI

struct HourlyConditionsView: View {
    @State var hourlyForecast: [HourlyForecast]?

    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct HourlyConditionsView_Previews: PreviewProvider {
    static var previews: some View {
        HourlyConditionsView(hourlyForecast: [])
    }
}
