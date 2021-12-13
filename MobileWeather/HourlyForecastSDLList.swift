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
    var weatherData: WeatherData
    var cells: [SDLChoiceCell]!

    required init(screenManager: SDLScreenManager, weatherData: WeatherData) {
        self.screenManager = screenManager
        self.weatherData = weatherData

        super.init()
        self.cells = self._createChoiceCells(from: weatherData)
    }

    func present() {
        let choiceSet = SDLChoiceSet(title: "Hourly Forecast", delegate: self, layout: .list, timeout: 30.0, initialPromptString: "Hourly Forecast", timeoutPromptString: "Hourly Forecast Timed Out", helpPromptString: "Select a time to see more information", vrHelpList: nil, choices: cells)
        screenManager.present(choiceSet, mode: .manualOnly)
    }

    func _createChoiceCells(from weatherData: WeatherData) -> [SDLChoiceCell] {
        let hourlyViewModels = weatherData.hourly.map { HourlyWeatherSDLViewModel(forecast: $0) }.prefix(20)
        var hourlyForecastCells = [SDLChoiceCell]()

        for viewModel in hourlyViewModels {
            hourlyForecastCells.append(SDLChoiceCell(text: viewModel.text3, secondaryText: viewModel.text1, tertiaryText: viewModel.text2, voiceCommands: nil, artwork: viewModel.artwork1, secondaryArtwork: nil))
        }

        return hourlyForecastCells
    }
}

extension HourlyForecastSDLList: SDLChoiceSetDelegate {
    func choiceSet(_ choiceSet: SDLChoiceSet, didSelectChoice choice: SDLChoiceCell, withSource source: SDLTriggerSource, atRowIndex rowIndex: UInt) {
        WeatherSDLManager.shared.showHourlyForecast(weatherData.hourly[Int(rowIndex)], speak: (source == .voiceRecognition))
    }

    func choiceSet(_ choiceSet: SDLChoiceSet, didReceiveError error: Error) {
        print("Choice set failed: \(error.localizedDescription)")
    }
}
