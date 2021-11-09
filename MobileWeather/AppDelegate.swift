//
//  AppDelegate.swift
//  MobileWeather
//
//  Created by Joel Fischer on 9/21/21.
//  Copyright © 2021 Ford. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI

@UIApplicationMain
class AppDelegate: NSObject, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        Preferences.shared.registerDefaults()

        let json = Bundle.main.url(forResource: "weather-api-response", withExtension: "json")!
        let jsonData = try! Data(contentsOf: json)
        let data = try! JSONDecoder().decode(WeatherData.self, from: jsonData)

        return true
    }
}
