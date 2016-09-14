//
//  WeatherDataManager.h
//  MobileWeather
//
//  Copyright (c) 2013-2015 Ford Motor Company. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "UnitType.h"

@class WeatherConditions;
@class WeatherLanguage;
@class WeatherLocation;


@interface WeatherDataManager : NSObject

+ (instancetype)sharedManager;

@property UnitType unit;

@property WeatherLanguage *language;

@property WeatherLocation *currentLocation;

@property WeatherConditions *weatherConditions;

@property NSArray *dailyForecast;

@property NSArray *hourlyForecast;

@property NSArray *alerts;

@end
