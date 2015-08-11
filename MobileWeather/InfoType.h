//
//  InfoType.h
//  MobileWeather
//
//  Copyright (c) 2013-2015 Ford Motor Company. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "EnumType.h"

@interface InfoType : EnumType

+ (instancetype)NONE;

+ (instancetype)WEATHER_CONDITIONS;

+ (instancetype)DAILY_FORECAST;

+ (instancetype)HOURLY_FORECAST;

+ (instancetype)ALERTS;

@end
