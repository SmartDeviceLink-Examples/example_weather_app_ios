//
//  WeatherSDLManager.swift
//  MobileWeather
//
//  Created by Joel Fischer on 11/12/21.
//  Copyright © 2021 Ford. All rights reserved.
//

import Foundation
import SmartDeviceLink

class WeatherSDLManager: NSObject {
    static let shared = WeatherSDLManager()

    private var sdlManager: SDLManager!
    private var screenManager: SDLScreenManager { sdlManager.screenManager }
    private var menuManager: WeatherSDLMenuManager!
    private var hasFirstHMIFullOccurred = false

    private var currentDisplayInfo: CurrentInfoType = .current
    private var knownWeatherAlerts = Set<WeatherAlert>()

    override init() {
        super.init()
        menuManager = WeatherSDLMenuManager(weatherSDLManager: self)
        NotificationCenter.default.addObserver(self, selector: #selector(weatherDataDidUpdate(_:)), name: .weatherDataUpdate, object: nil)
    }

    func start() {
//        private let lifecycleConfig = SDLLifecycleConfiguration(appName: "SDL Weather", fullAppId: "330533107")
        let lifecycleConfig = SDLLifecycleConfiguration(appName: "SDL Weather", fullAppId: "330533107", ipAddress: "m.sdl.tools", port: 12345)
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
        if newLevel == .full && !hasFirstHMIFullOccurred {
            hasFirstHMIFullOccurred = true
            showCurrentConditions(speak: false)
            sendDefaultGlobalProperties()

            screenManager.menuConfiguration = SDLMenuConfiguration(mainMenuLayout: .tiles, defaultSubmenuLayout: .tiles)
            screenManager.menu = menuManager.menuCells

            let currentConditionsSB = SDLSoftButtonObject(name: "Current Conditions", text: "Current", artwork: SDLArtwork, handler: <#T##SDLRPCButtonNotificationHandler?##SDLRPCButtonNotificationHandler?##(SDLOnButtonPress?, SDLOnButtonEvent?) -> Void#>)
        }
    }
}

// MARK: - Notification Observers
extension WeatherSDLManager {
    @objc private func weatherDataDidUpdate(_ notification: Notification) {
        guard sdlManager.hmiLevel != .some(.none) else { return }

        // Find any unknown alerts
        if let currentAlerts = WeatherManager.shared.weatherData?.alerts {
            var unknownAlerts = Set<WeatherAlert>(currentAlerts)
            unknownAlerts.subtract(knownWeatherAlerts)

            knownWeatherAlerts = Set<WeatherAlert>(currentAlerts)

            if !unknownAlerts.isEmpty {
                // TODO: Show an alert about new weather alerts w/ button to take you to alerts screen, or show alerts with new alert information
            }
        }

        // Update the current info display
        switch currentDisplayInfo {
        case .current:
            showCurrentConditions(speak: false)
        case .hourly:
            showCurrentConditions(speak: false)
        case .daily:
            showDailyForecast(speak: false)
        case .alert:
            showWeatherAlerts(speak: false)
        }
    }
}

// MARK: - SDL Startup Methods
extension WeatherSDLManager {
    private func sendDefaultGlobalProperties() {

    }
}

// MARK: - Weather Updates
extension WeatherSDLManager {
    func showCurrentConditions(speak: Bool) {

    }

    func showDailyForecast(speak: Bool) {

    }

    func showHourlyForecast(speak: Bool) {

    }

    func showWeatherAlerts(speak: Bool) {

    }
}

// MARK: - Popup Menus
extension WeatherSDLManager {
    private func presentHourlyForecastPopup() {

    }

    private func presentDailyForecastPopup() {

    }

    private func presentAlertsPopup() {

    }
}

enum CurrentInfoType {
    case current, daily, hourly, alert
}
