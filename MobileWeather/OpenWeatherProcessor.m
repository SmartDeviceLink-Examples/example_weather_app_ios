//
//  OpenWeatherProcessor.m
//  MobileWeather
//
//  Created by Joel Fischer on 6/4/21.
//  Copyright © 2021 Ford. All rights reserved.
//

#import "OpenWeatherProcessor.h"

#import "Forecast.h"
#import "WeatherConditions.h"

@implementation OpenWeatherProcessor

typedef NS_ENUM(NSUInteger, MWForecastType) {
    MWForecastTypeCurrently,
    MWForecastTypeHourly,
    MWForecastTypeDaily
};

+ (NSArray *)alerts:(NSDictionary *)json {
    return @[];
}

+ (NSArray *)dailyForecast:(NSDictionary *)json {
    return @[];
}

+ (NSArray *)hourlyForecast:(NSDictionary *)json {
    return @[];
}

+ (WeatherConditions *)weatherConditions:(NSDictionary *)json {
    return [[WeatherConditions alloc] init];
}

+ (NSArray<Forecast *> *)mw_processForecastJSON:(NSDictionary<NSString *, id> *)json forType:(MWForecastType)type {
    return @[];
}

@end
