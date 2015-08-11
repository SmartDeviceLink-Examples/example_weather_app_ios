//
//  WeatherConditions.h
//  MobileWeather
//
//  Copyright (c) 2013-2015 Ford Motor Company. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TemperatureNumber.h"
#import "LengthNumber.h"
#import "SpeedNumber.h"
#import "PercentageNumber.h"

@interface WeatherConditions : NSObject

@property (strong) NSDate *date;

@property (strong) NSString *conditionTitle;

@property (strong) NSString *conditionIcon;

@property (strong) TemperatureNumber *temperature;

@property (strong) TemperatureNumber *feelsLikeTemperature;

@property (strong) SpeedNumber *windSpeed;

@property (strong) SpeedNumber *windSpeedGust;

@property (strong) LengthNumber *visibility;

@property (strong) PercentageNumber *humidity;

@property (strong) PercentageNumber *precipitation;

@end
