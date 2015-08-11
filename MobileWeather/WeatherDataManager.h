//
//  WeatherDataManager.h
//  MobileWeather
//
//  Copyright (c) 2013-2015 Ford Motor Company. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WeatherLocation.h"
#import "WeatherConditions.h"
#import "WeatherLanguage.h"
#import "Forecast.h"
#import "Alert.h"
#import "UnitType.h"

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
