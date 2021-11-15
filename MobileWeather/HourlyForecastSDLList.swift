//
//  HourlyForecastSDLList.swift
//  MobileWeather
//
//  Created by Joel Fischer on 11/15/21.
//  Copyright © 2021 Ford. All rights reserved.
//

import SmartDeviceLink

class HourlyForecastSDLList: NSObject, WeatherSDLListType {
    var screenManager: SDLScreenManager
    var cells: [SDLChoiceCell]!

    private static let hourlyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .none
        f.doesRelativeDateFormatting = false
        f.setLocalizedDateFormatFromTemplate("h a")

        return f
    }()

    required init(screenManager: SDLScreenManager, weatherData: WeatherData) {
        self.screenManager = screenManager

        super.init()
        self.cells = self.createChoiceCells(from: weatherData)
    }

    func present() {
        let choiceSet = SDLChoiceSet(title: "Hourly Forecast", delegate: self, layout: .list, timeout: 15.0, initialPromptString: "Hourly Forecast", timeoutPromptString: "Hourly Forecast Timed Out", helpPromptString: "Select a time to see more information", vrHelpList: nil, choices: cells)
        screenManager.present(choiceSet, mode: .manualOnly)
    }

    func createChoiceCells(from weatherData: WeatherData) -> [SDLChoiceCell] {
        let hourlyForecastData = weatherData.hourly
        var hourlyForecastCells = [SDLChoiceCell]()

        for forecast in hourlyForecastData {
            let dateText = HourlyForecastSDLList.hourlyFormatter.string(from: forecast.date)
            let tempText = "\(forecast.temperature.formatted())°"
            let weatherImage = WeatherImage.fromOpenWeatherName(OpenWeatherIcon(rawValue: forecast.conditionIconNames.first!)!)
            hourlyForecastCells.append(SDLChoiceCell(text: forecast.conditionDescriptions.first!, secondaryText: dateText, tertiaryText: tempText, voiceCommands: nil, artwork: SDLArtwork(image: weatherImage, persistent: true, as: .PNG), secondaryArtwork: nil))
        }

        return hourlyForecastCells
    }
}

extension HourlyForecastSDLList: SDLChoiceSetDelegate {
    func choiceSet(_ choiceSet: SDLChoiceSet, didSelectChoice choice: SDLChoiceCell, withSource source: SDLTriggerSource, atRowIndex rowIndex: UInt) {
        // TODO: Change the hourly forecast screen
    }

    func choiceSet(_ choiceSet: SDLChoiceSet, didReceiveError error: Error) {
        // TODO: Show an SDL alert with info?
    }
}
