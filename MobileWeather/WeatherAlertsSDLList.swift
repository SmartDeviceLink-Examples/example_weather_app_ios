//
//  WeatherAlertsSDLList.swift
//  MobileWeather
//
//  Created by Joel Fischer on 11/15/21.
//  Copyright © 2021 Ford. All rights reserved.
//

import SmartDeviceLink

class WeatherAlertsSDLList: NSObject, WeatherSDLListType {
    var screenManager: SDLScreenManager
    var cells: [SDLChoiceCell]!

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        f.doesRelativeDateFormatting = false
        f.setLocalizedDateFormatFromTemplate("M/d h:mm a")

        return f
    }()

    required init(screenManager: SDLScreenManager, weatherData: WeatherData) {
        self.screenManager = screenManager

        super.init()
        self.cells = self._createChoiceCells(from: weatherData)
    }

    func present() {
        let choiceSet = SDLChoiceSet(title: "Weather Alerts", delegate: self, layout: .list, timeout: 15.0, initialPromptString: "Weather Alerts", timeoutPromptString: "Weather Alerts Timed Out", helpPromptString: "Select an alert to see more information", vrHelpList: nil, choices: cells)
        screenManager.present(choiceSet, mode: .manualOnly)
    }

    func _createChoiceCells(from weatherData: WeatherData) -> [SDLChoiceCell] {
        let alertData = weatherData.alerts
        var alertCells = [SDLChoiceCell]()

        for alert in alertData {
            let startDateText = WeatherAlertsSDLList.dateFormatter.string(from: alert.startDate)
            let endDateText = WeatherAlertsSDLList.dateFormatter.string(from: alert.endDate)
            alertCells.append(SDLChoiceCell(text: alert.event, secondaryText: "\(startDateText) — \(endDateText)", tertiaryText: nil, voiceCommands: nil, artwork: nil, secondaryArtwork: nil))
        }

        return alertCells
    }
}

extension WeatherAlertsSDLList: SDLChoiceSetDelegate {
    func choiceSet(_ choiceSet: SDLChoiceSet, didSelectChoice choice: SDLChoiceCell, withSource source: SDLTriggerSource, atRowIndex rowIndex: UInt) {
        // TODO: Show to alert on the main screen
    }

    func choiceSet(_ choiceSet: SDLChoiceSet, didReceiveError error: Error) {
        // TODO: Show an SDL alert with info?
    }
}
