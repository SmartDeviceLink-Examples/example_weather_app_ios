//
//  DailyForecastSDLList.swift
//  MobileWeather
//
//  Created by Joel Fischer on 11/15/21.
//  Copyright © 2021 Ford. All rights reserved.
//

import SmartDeviceLink

class DailyForecastSDLList: NSObject, WeatherSDLListType {
    var screenManager: SDLScreenManager
    var cells: [SDLChoiceCell]!

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .none
        f.doesRelativeDateFormatting = true
        f.setLocalizedDateFormatFromTemplate("EEEE MMMM d")

        return f
    }()

    required init(screenManager: SDLScreenManager, weatherData: WeatherData) {
        self.screenManager = screenManager

        super.init()
        self.cells = self.createChoiceCells(from: weatherData)
    }

    func present() {
        let choiceSet = SDLChoiceSet(title: "Daily Forecast", delegate: self, layout: .list, timeout: 15.0, initialPromptString: "Daily Forecast", timeoutPromptString: "Daily Forecast Timed Out", helpPromptString: "Select a day to see more information", vrHelpList: nil, choices: cells)
        screenManager.present(choiceSet, mode: .manualOnly)
    }

    func createChoiceCells(from weatherData: WeatherData) -> [SDLChoiceCell] {
        let dailyForecastData = weatherData.daily
        var dailyForecastCells = [SDLChoiceCell]()

        for forecast in dailyForecastData {
            let dateText = DailyForecastSDLList.dayFormatter.string(from: forecast.date)
            let tempText = "H \(forecast.highTemperature)° | L \(forecast.lowTemperature)°"
            let weatherImage = WeatherImage.fromOpenWeatherName(OpenWeatherIcon(rawValue: forecast.conditionIconNames.first!)!)
            dailyForecastCells.append(SDLChoiceCell(text: forecast.conditionDescriptions.first!, secondaryText: dateText, tertiaryText: tempText, voiceCommands: nil, artwork: SDLArtwork(image: weatherImage, persistent: true, as: .PNG), secondaryArtwork: nil))
        }

        return dailyForecastCells
    }
}

extension DailyForecastSDLList: SDLChoiceSetDelegate {
    func choiceSet(_ choiceSet: SDLChoiceSet, didSelectChoice choice: SDLChoiceCell, withSource source: SDLTriggerSource, atRowIndex rowIndex: UInt) {
        // TODO: Change the daily forecast screen
    }

    func choiceSet(_ choiceSet: SDLChoiceSet, didReceiveError error: Error) {
        // TODO: Show an SDL alert with info?
    }
}
