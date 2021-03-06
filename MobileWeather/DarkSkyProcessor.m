//
//  ForecastIOProcessor.m
//  MobileWeather
//
//  Copyright (c) 2013-2015 Ford Motor Company. All rights reserved.
//

@import SmartDeviceLink;

#import "DarkSkyProcessor.h"

#import "Forecast.h"
#import "UnitConverter.h"
#import "Alert.h"
#import "WeatherConditions.h"
#import "PercentageNumber.h"
#import "TemperatureNumber.h"
#import "SpeedNumber.h"
#import "LengthNumber.h"

#define KEY_CURRENTLY @"currently"
#define KEY_HOURLY @"hourly"
#define KEY_DAILY @"daily"
#define KEY_ALERTS @"alerts"
#define KEY_ICON @"icon"
#define KEY_SUMMARY @"summary"
#define KEY_TEMPERATURE @"temperature"
#define KEY_HUMIDITY @"humidity"
#define KEY_WIND_SPEED @"windSpeed"
#define KEY_VISIBILITY @"visibility"
#define KEY_APPARENT_TEMPERATURE @"apparentTemperature"
#define KEY_PRECIP_PROBABILITY @"precipProbability"
#define KEY_DATA @"data"
#define KEY_TIME @"time"
#define KEY_TEMPERATURE_MAX @"temperatureMax"
#define KEY_TEMPERATURE_MIN @"temperatureMin"
#define KEY_PRECIP_ACCUMULATION @"precipAccumulation"
#define KEY_EXPIRES @"expires"
#define KEY_TITLE @"title"
#define KEY_DESCRIPTION @"description"
#define KEY_TIMEZONE @"timezone"
#define KEY_OFFSET @"offset"

@implementation DarkSkyProcessor

+ (WeatherConditions *)weatherConditions:(NSDictionary *)json {
    WeatherConditions *conditions = nil;
    
    if (json != nil) {
        conditions = [[WeatherConditions alloc] init];
        NSDictionary *currently = json[KEY_CURRENTLY];

        if (currently != nil) {
            conditions.date = [self dateFromTime:currently[KEY_TIME] withOffset:json[KEY_OFFSET]];
            
            conditions.conditionTitle = currently[KEY_SUMMARY];
            conditions.conditionIcon = currently[KEY_ICON];
            
            conditions.temperature = [TemperatureNumber numberWithNumber:currently[KEY_TEMPERATURE] withUnit:UnitTemperatureCelsius];
            conditions.feelsLikeTemperature = [TemperatureNumber numberWithNumber:currently[KEY_APPARENT_TEMPERATURE] withUnit:UnitTemperatureCelsius];
            conditions.windSpeed = [SpeedNumber numberWithNumber:currently[KEY_WIND_SPEED] withUnit:UnitSpeedMeterSecond];
            conditions.visibility = [LengthNumber numberWithNumber:currently[KEY_VISIBILITY] withUnit:UnitLengthKiloMeter];
            conditions.humidity = [PercentageNumber numberWithNumber:currently[KEY_HUMIDITY] withUnit:UnitPercentageFactor];
            conditions.precipitation = [PercentageNumber numberWithNumber:currently[KEY_PRECIP_PROBABILITY] withUnit:UnitPercentageFactor];
        }
    }
    
    return conditions;
}

+ (NSArray *)dailyForecast:(NSDictionary *)json {
    SDLLogD(@"Processing daily forecast");
    return [self processForecast:json forType:KEY_DAILY];
}

+ (NSArray *)hourlyForecast:(NSDictionary *)json {
    SDLLogD(@"Processing hourly forecast");
    return [self processForecast:json forType:KEY_HOURLY];
}

+ (NSArray *)processForecast:(NSDictionary *)json forType:(NSString *)type {
    NSMutableArray *forecasts = [NSMutableArray array];
    NSDictionary *section = json[type];
    NSArray *data = nil;

    if (section != nil) {
        data = section[KEY_DATA];

        if (data != nil) {
            NSUInteger numberOfDays = data.count;
            
            for (int dayCounter = 0; dayCounter < numberOfDays; dayCounter++) {
                NSDictionary *day = data[dayCounter];
                Forecast *currentForecast = [[Forecast alloc] init];
                
                if (day != nil && currentForecast != nil) {
                    currentForecast.date = [self dateFromTime:day[KEY_TIME] withOffset:json[KEY_OFFSET]];

                    currentForecast.conditionTitle = day[KEY_SUMMARY];
                    currentForecast.conditionIcon = day[KEY_ICON];
                    
                    currentForecast.temperature = [TemperatureNumber numberWithNumber:day[KEY_TEMPERATURE] withUnit:UnitTemperatureCelsius];
                    currentForecast.highTemperature = [TemperatureNumber numberWithNumber:day[KEY_TEMPERATURE_MAX] withUnit:UnitTemperatureCelsius];
                    currentForecast.lowTemperature = [TemperatureNumber numberWithNumber:day[KEY_TEMPERATURE_MIN] withUnit:UnitTemperatureCelsius];
                    currentForecast.windSpeed = [SpeedNumber numberWithNumber:day[KEY_WIND_SPEED] withUnit:UnitSpeedMeterSecond];
                    currentForecast.snow = [LengthNumber numberWithNumber:day[KEY_PRECIP_ACCUMULATION] withUnit:UnitLengthCentiMeter];
                    currentForecast.humidity = [PercentageNumber numberWithNumber:day[KEY_HUMIDITY] withUnit:UnitPercentageFactor];
                    currentForecast.precipitationChance = [PercentageNumber numberWithNumber:day[KEY_PRECIP_PROBABILITY] withUnit:UnitPercentageFactor];
                    
                    [forecasts addObject:currentForecast];
                }
            }
        }
    }
    
    if (forecasts.count > 0) {
        return [NSArray arrayWithArray:forecasts];
    }
    else {
        return nil;
    }
}

+ (NSArray *)alerts:(NSDictionary *)json {
    NSMutableArray *alerts = [NSMutableArray array];
    NSArray *data = json[KEY_ALERTS];
    
    if (data != nil) {
        NSUInteger numberOfAlerts = data.count;
        
        for (int alertCounter = 0; alertCounter < numberOfAlerts; alertCounter++) {
            NSDictionary *dataAlert = data[alertCounter];
            Alert *currentAlert = [[Alert alloc] init];
            
            if (dataAlert != nil && currentAlert != nil) {
                currentAlert.dateIssued = [self dateFromTime:dataAlert[KEY_TIME] withOffset:json[KEY_OFFSET]];
                currentAlert.dateExpires = [self dateFromTime:dataAlert[KEY_EXPIRES] withOffset:json[KEY_OFFSET]];
                
                currentAlert.title = dataAlert[KEY_TITLE];
                currentAlert.text = dataAlert[KEY_DESCRIPTION];
                
                [alerts addObject:currentAlert];
            }
        }
    }
    
    if (alerts.count > 0) {
        return [NSArray arrayWithArray:alerts];
    }
    else {
        return nil;
    }
}

+ (NSDate *)dateFromTime:(NSNumber *)number withOffset:(NSNumber *)offset {
    NSDate *date = nil;
    if (number) {
        NSNumber *offsetseconds = nil;
        
        if (offset) {
            offsetseconds = [UnitConverter convertTime:offset from:UnitTimeHour to:UnitTimeSecond];
        }
        else {
            offsetseconds = @(0);
        }
        
        date = [NSDate dateWithTimeIntervalSince1970:number.longValue + offsetseconds.longValue];
    }
    
    return date;
}


@end
