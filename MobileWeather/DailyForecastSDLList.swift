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
    var weatherData: WeatherData
    var cells: [SDLChoiceCell]!

    required init(screenManager: SDLScreenManager, weatherData: WeatherData) {
        self.screenManager = screenManager
        self.weatherData = weatherData

        super.init()
        self.cells = self._createChoiceCells(from: weatherData)
    }

    func present() {
        let choiceSet = SDLChoiceSet(title: "Daily Forecast", delegate: self, layout: .list, timeout: 30.0, initialPromptString: "Daily Forecast", timeoutPromptString: "Daily Forecast Timed Out", helpPromptString: "Select a day to see more information", vrHelpList: nil, choices: cells)
        screenManager.present(choiceSet, mode: .manualOnly)
    }

    func _createChoiceCells(from weatherData: WeatherData) -> [SDLChoiceCell] {
        let dailyViewModels = weatherData.daily.map { DailyWeatherSDLViewModel(forecast: $0) }
        var dailyForecastCells = [SDLChoiceCell]()

        for viewModel in dailyViewModels {
            dailyForecastCells.append(SDLChoiceCell(text: viewModel.text3, secondaryText: viewModel.text1, tertiaryText: viewModel.text2, voiceCommands: nil, artwork: viewModel.artwork1, secondaryArtwork: nil))
        }

        return dailyForecastCells
    }
}

extension DailyForecastSDLList: SDLChoiceSetDelegate {
    func choiceSet(_ choiceSet: SDLChoiceSet, didSelectChoice choice: SDLChoiceCell, withSource source: SDLTriggerSource, atRowIndex rowIndex: UInt) {
        WeatherSDLManager.shared.showDailyForecast(weatherData.daily[Int(rowIndex)], speak: (source == .voiceRecognition))
    }

    func choiceSet(_ choiceSet: SDLChoiceSet, didReceiveError error: Error) {
        print("Choice set failed: \(error.localizedDescription)")
    }
}
