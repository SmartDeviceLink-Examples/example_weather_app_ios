//
//  SDL_Weather_Widget.swift
//  SDL Weather Widget
//
//  Created by Joel Fischer on 12/6/21.
//  Copyright © 2021 Ford. All rights reserved.
//

import WidgetKit
import SwiftUI
import Intents

@main
struct SDL_Weather_Widget: Widget {
    let kind: String = "SDL_Weather_Widget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: WeatherDataTimelineProvider()) { entry in
            SDL_Weather_WidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Hourly Weather")
        .description("The current and next five hours of weather")
        .supportedFamilies([.systemMedium])
    }
}
