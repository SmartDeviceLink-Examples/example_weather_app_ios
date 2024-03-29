//
//  WeatherSDLManager.swift
//  MobileWeather
//
//  Created by Joel Fischer on 11/12/21.
//  Copyright © 2021 Ford. All rights reserved.
//

import Foundation
import SmartDeviceLink
import UIKit

class WeatherSDLManager: NSObject {
    static let shared = WeatherSDLManager()

    private var sdlManager: SDLManager!
    private var screenManager: SDLScreenManager { sdlManager.screenManager }
    private var hasFirstHMIFullOccurred = false

    private var currentDisplayType: CurrentInfoType = .current
    private var knownWeatherAlerts = Set<WeatherAlert>()

    private var alertsListInteraction: WeatherAlertsSDLList?
    private var hourlyListInteraction: HourlyForecastSDLList?
    private var dailyListInteraction: DailyForecastSDLList?

    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(weatherDataDidUpdate(_:)), name: .weatherDataUpdate, object: nil)
    }

    func start() {
        let lifecycleConfig = SDLLifecycleConfiguration(appName: "MobileWeather", fullAppId: "330533107")
//        let lifecycleConfig = SDLLifecycleConfiguration(appName: "SDL Weather", fullAppId: "330533107", ipAddress: "m.sdl.tools", port: 14513)
        lifecycleConfig.ttsName = SDLTTSChunk.textChunks(from: "S D L Weather")
        lifecycleConfig.appIcon = SDLArtwork(image: UIImage(named: "sdl-appicon")!, name: "AppIcon", persistent: true, as: .PNG)
        lifecycleConfig.language = .enUs

        let config = SDLConfiguration(lifecycle: lifecycleConfig, lockScreen: .enabledConfiguration(withAppIcon: UIImage(named: "sdl-appicon")!, backgroundColor: .systemGray), logging: logConfig, fileManager: nil, encryption: nil)
        sdlManager = SDLManager(configuration: config, delegate: self)
        sdlManager.start { success, error in
            guard let availableTemplates = self.sdlManager.systemCapabilityManager.defaultMainWindowCapability?.templatesAvailable else {
                SDLLog.e("Available templates were not communicated. This app may not work properly.")
                return
            }

            if (availableTemplates.contains(SDLPredefinedLayout.nonMedia.rawValue.rawValue)) {
                let templateConfig = SDLTemplateConfiguration(predefinedLayout: .nonMedia)
                self.screenManager.changeLayout(templateConfig, withCompletionHandler: nil)
            } else {
                SDLLog.e("The non-media template is not supported. This app may not work properly")
            }
        }
    }

    private func reset() {
        hasFirstHMIFullOccurred = false
    }

    private var logConfig: SDLLogConfiguration {
        let logConfig = SDLLogConfiguration.debug()

        let sdlFileModule = SDLLogFileModule(name: "SDL Weather/SDL", files: ["WeatherSDLManager"])
        logConfig.modules = logConfig.modules.union([sdlFileModule])

        return logConfig
    }
}

// MARK: - SDLManager Delegate
extension WeatherSDLManager: SDLManagerDelegate {
    func managerDidDisconnect() {
        reset()
    }

    func hmiLevel(_ oldLevel: SDLHMILevel, didChangeToLevel newLevel: SDLHMILevel) {
        // Setup when we hit HMI Full for the first time
        if newLevel == .full && !hasFirstHMIFullOccurred {
            hasFirstHMIFullOccurred = true
            sendDefaultGlobalProperties()
            screenManager.menuConfiguration = SDLMenuConfiguration(mainMenuLayout: .tiles, defaultSubmenuLayout: .tiles)
            screenManager.menu = menuCells
            screenManager.softButtonObjects = softButtons

            showCurrentConditions(speak: false)
        }
    }
}

// MARK: - Notification Observers
extension WeatherSDLManager {
    @objc private func weatherDataDidUpdate(_ notification: Notification) {
        guard sdlManager.hmiLevel != .some(.none) else { return }
        let weatherData = WeatherService.shared.weatherData

        // Find any unknown alerts
        if let currentAlerts = WeatherService.shared.weatherData.alerts {
            var unknownAlerts = Set<WeatherAlert>(currentAlerts)
            unknownAlerts.subtract(knownWeatherAlerts)

            knownWeatherAlerts = Set<WeatherAlert>(currentAlerts)

            if !unknownAlerts.isEmpty {
                // TODO: Show an alert about new weather alerts w/ button to take you to alerts screen, or show alerts with new alert information
            }
        }

        // Update the current info display
        switch currentDisplayType {
        case .current:
            showCurrentConditions(speak: false)
        case .hourly:
            showHourlyForecast(weatherData.hourly.first!, speak: false)
        case .daily:
            showDailyForecast(weatherData.daily.first!, speak: false)
        case .alert:
            if let firstAlert = weatherData.alerts?.first {
                showWeatherAlert(firstAlert, speak: false)
            } else {
                showCurrentConditions(speak: false)
            }
        }
    }
}

// MARK: - SDL Startup Methods
extension WeatherSDLManager {
    private func sendDefaultGlobalProperties() {
        let currentConditionsPrompt = "Current Conditions"
        let currentConditionsHelpItem = SDLVRHelpItem(text: currentConditionsPrompt, image: nil, position: 1)

        let dailyForecastPrompt = "Daily Forecast"
        let dailyForecastHelpItem = SDLVRHelpItem(text: dailyForecastPrompt, image: nil, position: 2)

        let hourlyForecastPrompt = "Hourly Forecast"
        let hourlyForecastHelpItem = SDLVRHelpItem(text: hourlyForecastPrompt, image: nil, position: 3)

        let alertsPrompt = "Alerts"
        let alertsHelpItem = SDLVRHelpItem(text: alertsPrompt, image: nil, position: 4)

        let prompts = [currentConditionsPrompt, dailyForecastPrompt, hourlyForecastPrompt, alertsPrompt].joined(separator: ",")
        let helpItems = [currentConditionsHelpItem, dailyForecastHelpItem, hourlyForecastHelpItem, alertsHelpItem]

        let setGlobalProps = SDLSetGlobalProperties(userLocation: nil, helpPrompt: SDLTTSChunk.textChunks(from: prompts), timeoutPrompt: SDLTTSChunk.textChunks(from: prompts), vrHelpTitle: "SDL Weather", vrHelp: helpItems, menuTitle: nil, menuIcon: nil, keyboardProperties: nil, menuLayout: nil)

        sdlManager.send(request: setGlobalProps) { request, response, error in
            if let error = error {
                SDLLog.e("Default global properties failed: \(error)")
            } else {
                SDLLog.d("Default global properties updated successfully")
            }
        }
    }
}

// MARK: - Weather Updates
extension WeatherSDLManager {
    private func showNoData(speak: Bool) {
        screenManager.beginUpdates()
        screenManager.textField1 = "Loading Weather Data..."
        screenManager.textField2 = nil
        screenManager.textField3 = nil
        screenManager.textField4 = nil
        screenManager.primaryGraphic = SDLArtwork(image: UIImage(systemName: "arrow.triangle.2.circlepath", withConfiguration: UIImage.SymbolConfiguration(pointSize: 256))!.withRenderingMode(.alwaysTemplate).withTintColor(.systemGray), persistent: true, as: .PNG)
        screenManager.endUpdates()
    }

    func showCurrentConditions(speak: Bool) {
        currentDisplayType = .current

        guard WeatherService.shared.lastUpdateTime != nil else { return showNoData(speak: speak) }

        let viewModel = CurrentWeatherSDLViewModel(currentWeather: WeatherService.shared.weatherData.current)
        screenManager.beginUpdates()
        screenManager.textField1 = viewModel.text1
        screenManager.textField2 = viewModel.text2
        screenManager.textField3 = viewModel.text3
        screenManager.textField4 = viewModel.text4
        screenManager.primaryGraphic = viewModel.artwork1
        screenManager.endUpdates()

        if speak {
            let speak = SDLSpeak(tts: "\(viewModel.text1) \(viewModel.text2) \(viewModel.text3) \(viewModel.text4)")
            sdlManager.send(request: speak) { request, response, error in
                if let error = error {
                    SDLLog.e("Error sending speak with string: \(speak.ttsChunks.first!.text), error: \(error)")
                } else {
                    SDLLog.d("Spoke current conditions")
                }
            }
        }
    }

    func showDailyForecast(_ forecast: DailyForecast, speak: Bool) {
        currentDisplayType = .daily

        let viewModel = DailyWeatherSDLViewModel(forecast: forecast)
        screenManager.beginUpdates()
        screenManager.textField1 = viewModel.text1
        screenManager.textField2 = viewModel.text2
        screenManager.textField3 = viewModel.text3
        screenManager.textField4 = viewModel.text4
        screenManager.primaryGraphic = viewModel.artwork1
        screenManager.endUpdates()

        if speak {
            let speak = SDLSpeak(tts: "\(viewModel.text1) \(viewModel.text2) \(viewModel.text3) \(viewModel.text4)")
            sdlManager.send(request: speak) { request, response, error in
                if let error = error {
                    SDLLog.e("Error sending speak with string: \(speak.ttsChunks.first!.text), error: \(error)")
                } else {
                    SDLLog.d("Spoke current conditions")
                }
            }
        }
    }

    func showHourlyForecast(_ forecast: HourlyForecast, speak: Bool) {
        currentDisplayType = .hourly

        let viewModel = HourlyWeatherSDLViewModel(forecast: forecast)
        screenManager.beginUpdates()
        screenManager.textField1 = viewModel.text1
        screenManager.textField2 = viewModel.text2
        screenManager.textField3 = viewModel.text3
        screenManager.textField4 = viewModel.text4
        screenManager.primaryGraphic = viewModel.artwork1
        screenManager.endUpdates()

        if speak {
            let speak = SDLSpeak(tts: "\(viewModel.text1) \(viewModel.text2) \(viewModel.text3) \(viewModel.text4)")
            sdlManager.send(request: speak) { request, response, error in
                if let error = error {
                    SDLLog.e("Error sending speak with string: \(speak.ttsChunks.first!.text), error: \(error)")
                } else {
                    SDLLog.d("Spoke current conditions")
                }
            }
        }
    }

    func showWeatherAlert(_ alert: WeatherAlert, speak: Bool) {
        currentDisplayType = .alert

        let viewModel = WeatherAlertSDLViewModel(alert: alert)
        let scrollableMessage = SDLScrollableMessage(message:
        """
        \(viewModel.text1)
        \(viewModel.text2) — \(viewModel.text3)

        \(viewModel.text4)
        """)
        let alertView = SDLAlertView(text: viewModel.text1, secondaryText: "\(viewModel.text2) - \(viewModel.text3)", tertiaryText: viewModel.text4.replacingOccurrences(of: "\n", with: " ", options: .literal), timeout: NSNumber(10), showWaitIndicator: nil, audioIndication: nil, buttons: nil, icon: viewModel.artwork1)

        sdlManager.send(request: scrollableMessage) { request, response, error in
            if let response = response, response.success.boolValue == false {
                self.screenManager.presentAlert(alertView, withCompletionHandler: nil)
            }
        }

        if speak {
            let speak = SDLSpeak(tts: "\(viewModel.text1) from \(viewModel.text2) to \(viewModel.text3)")
            sdlManager.send(request: speak) { request, response, error in
                if let error = error {
                    SDLLog.e("Error sending speak with string: \(speak.ttsChunks.first!.text), error: \(error)")
                } else {
                    SDLLog.d("Spoke current conditions")
                }
            }
        }
    }
}

// MARK: - Popup Menus
extension WeatherSDLManager {
    func presentHourlyForecastPopup() {
        guard WeatherService.shared.lastUpdateTime != nil else { return presentNoDataAlert() }
        let weatherData = WeatherService.shared.weatherData

        hourlyListInteraction = HourlyForecastSDLList(screenManager: screenManager, weatherData: weatherData)
        hourlyListInteraction!.present()
    }

    func presentDailyForecastPopup() {
        guard WeatherService.shared.lastUpdateTime != nil else { return presentNoDataAlert() }
        let weatherData = WeatherService.shared.weatherData

        dailyListInteraction = DailyForecastSDLList(screenManager: screenManager, weatherData: weatherData)
        dailyListInteraction!.present()
    }

    func presentAlertsPopup() {
        guard WeatherService.shared.lastUpdateTime != nil else { return presentNoDataAlert() }
        let weatherData = WeatherService.shared.weatherData
        guard let alerts = weatherData.alerts, !alerts.isEmpty else { return presentNoWeatherAlertsAlert() }

        alertsListInteraction = WeatherAlertsSDLList(screenManager: screenManager, weatherData: weatherData)
        alertsListInteraction!.present()
    }
}

// MARK: - Alerts
extension WeatherSDLManager {
    func presentNoDataAlert() {
        let alert = SDLAlertView(text: "No Data Available", secondaryText: "Cannot display because weather data is still loading", tertiaryText: nil, timeout: NSNumber(5), showWaitIndicator: NSNumber(true), audioIndication: nil, buttons: [SDLSoftButtonObject(name: "Okay", text: "Ok", artwork: nil, handler: nil)], icon: SDLArtwork(image: UIImage(systemName: "arrow.triangle.2.circlepath", withConfiguration: UIImage.SymbolConfiguration(pointSize: 256))!, persistent: true, as: .PNG))
        screenManager.presentAlert(alert, withCompletionHandler: nil)
    }

    func presentNoWeatherAlertsAlert() {
        let alert = SDLAlertView(text: "No Weather Alerts", secondaryText: nil, tertiaryText: nil, timeout: NSNumber(5), showWaitIndicator: NSNumber(true), audioIndication: nil, buttons: [SDLSoftButtonObject(name: "Okay", text: "Ok", artwork: nil, handler: nil)], icon: SDLArtwork(image: UIImage(systemName: "arrow.triangle.2.circlepath", withConfiguration: UIImage.SymbolConfiguration(pointSize: 256))!, persistent: true, as: .PNG))
        screenManager.presentAlert(alert, withCompletionHandler: nil)
    }
}

enum CurrentInfoType {
    case current, daily, hourly, alert
}
