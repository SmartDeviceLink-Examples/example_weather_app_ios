//
//  WeatherProcessor.swift
//  WeatherDataService
//
//  Created by Joel Fischer on 6/7/21.
//  Copyright © 2021 Ford. All rights reserved.
//

import Foundation

protocol WeatherProcessor {
    class func weatherConditions(from json: [String: AnyObject]) -> WeatherConditions
}
