//
//  WeatherListType.swift
//  MobileWeather
//
//  Created by Joel Fischer on 11/15/21.
//  Copyright © 2021 Ford. All rights reserved.
//

import SmartDeviceLink

protocol WeatherSDLListType: SDLChoiceSetDelegate {
    var screenManager: SDLScreenManager { get }
    var cells: [SDLChoiceCell]! { get }

    init(screenManager: SDLScreenManager, weatherData: WeatherData)
    func present()
    func createChoiceCells(from weatherData: WeatherData) -> [SDLChoiceCell]
}
