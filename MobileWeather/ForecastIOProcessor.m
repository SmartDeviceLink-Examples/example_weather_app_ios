//
//  ForecastIOProcessor.m
//  MobileWeather
//
//  Copyright (c) 2013-2015 Ford Motor Company. All rights reserved.
//

#import "ForecastIOProcessor.h"
#import "UnitConverter.h"
#import "Alert.h"

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

@implementation ForecastIOProcessor

+ (WeatherConditions *)weatherConditions:(NSDictionary *)json {
    WeatherConditions *conditions = nil;
    
    if (json != nil) {
        conditions = [[WeatherConditions alloc] init];
        NSDictionary *currently = [json objectForKey:KEY_CURRENTLY];

        if (currently != nil) {
            [conditions setDate:[self dateFromTime:[currently objectForKey:KEY_TIME] withOffset:[json objectForKey:KEY_OFFSET]]];
            
            [conditions setConditionTitle:[currently objectForKey:KEY_SUMMARY]];
            [conditions setConditionIcon:[
                                          currently objectForKey:KEY_ICON]];
            
            [conditions setTemperature:[TemperatureNumber numberWithNumber:[currently objectForKey:KEY_TEMPERATURE] withUnit:UnitTemperatureCelsius]];
            [conditions setFeelsLikeTemperature:[TemperatureNumber numberWithNumber:[currently objectForKey:KEY_APPARENT_TEMPERATURE] withUnit:UnitTemperatureCelsius]];
            [conditions setWindSpeed:[SpeedNumber numberWithNumber:[currently objectForKey:KEY_WIND_SPEED] withUnit:UnitSpeedMeterSecond]];
            [conditions setVisibility:[LengthNumber numberWithNumber:[currently objectForKey:KEY_VISIBILITY] withUnit:UnitLengthKiloMeter]];
            [conditions setHumidity:[PercentageNumber numberWithNumber:[currently objectForKey:KEY_HUMIDITY] withUnit:UnitPercentageFactor]];
            [conditions setPrecipitation:[PercentageNumber numberWithNumber:[currently objectForKey:KEY_PRECIP_PROBABILITY] withUnit:UnitPercentageFactor]];
        }
    }
    
    return conditions;
}

+ (NSArray *)dailyForecast:(NSDictionary *)json {
    NSLog(@"starting daily forecast");
    return [self processForecast:json forType:KEY_DAILY];
}

+ (NSArray *)hourlyForecast:(NSDictionary *)json {
    NSLog(@"starting hourly forecast");
    return [self processForecast:json forType:KEY_HOURLY];
}

+ (NSArray *)processForecast:(NSDictionary *)json forType:(NSString *)type {
    NSMutableArray *forecasts = [NSMutableArray array];
    NSDictionary *section = [json objectForKey:type];
    NSArray *data = nil;

    if (section != nil) {
        data = [section objectForKey:KEY_DATA];

        if (data != nil) {
            NSUInteger numberOfDays = [data count];
            
            for (int dayCounter = 0; dayCounter < numberOfDays; dayCounter++) {
                NSDictionary *day = [data objectAtIndex:dayCounter];
                Forecast *currentForecast = [[Forecast alloc] init];
                
                if (day != nil && currentForecast != nil) {
                    [currentForecast setDate:[self dateFromTime:[day objectForKey:KEY_TIME] withOffset:[json objectForKey:KEY_OFFSET]]];

                    [currentForecast setConditionTitle:[day objectForKey:KEY_SUMMARY]];
                    [currentForecast setConditionIcon:[day objectForKey:KEY_ICON]];
                    
                    [currentForecast setTemperature:[TemperatureNumber numberWithNumber:[day objectForKey:KEY_TEMPERATURE] withUnit:UnitTemperatureCelsius]];
                    [currentForecast setHighTemperature:[TemperatureNumber numberWithNumber:[day objectForKey:KEY_TEMPERATURE_MAX] withUnit:UnitTemperatureCelsius]];
                    [currentForecast setLowTemperature:[TemperatureNumber numberWithNumber:[day objectForKey:KEY_TEMPERATURE_MIN] withUnit:UnitTemperatureCelsius]];
                    [currentForecast setWindSpeed:[SpeedNumber numberWithNumber:[day objectForKey:KEY_WIND_SPEED] withUnit:UnitSpeedMeterSecond]];
                    [currentForecast setSnow:[LengthNumber numberWithNumber:[day objectForKey:KEY_PRECIP_ACCUMULATION] withUnit:UnitLengthCentiMeter]];
                    [currentForecast setHumidity:[PercentageNumber numberWithNumber:[day objectForKey:KEY_HUMIDITY] withUnit:UnitPercentageFactor]];
                    [currentForecast setPrecipitationChance:[PercentageNumber numberWithNumber:[day objectForKey:KEY_PRECIP_PROBABILITY] withUnit:UnitPercentageFactor]];
                    
                    [forecasts addObject:currentForecast];
                }
            }
        }
    }
    
    if ([forecasts count] > 0) {
        return [NSArray arrayWithArray:forecasts];
    }
    else {
        return nil;
    }
}

+ (NSArray *)alerts:(NSDictionary *)json {
    NSMutableArray *alerts = [NSMutableArray array];
    NSArray *data = [json objectForKey:KEY_ALERTS];
    
    if (data != nil) {
        NSUInteger numberOfAlerts = [data count];
        
        for (int alertCounter = 0; alertCounter < numberOfAlerts; alertCounter++) {
            NSDictionary *dataAlert = [data objectAtIndex:alertCounter];
            Alert *currentAlert = [[Alert alloc] init];
            
            if (dataAlert != nil && currentAlert != nil) {
                [currentAlert setDateIssued:[self dateFromTime:[dataAlert objectForKey:KEY_TIME] withOffset:[json objectForKey:KEY_OFFSET]]];
                [currentAlert setDateExpires:[self dateFromTime:[dataAlert objectForKey:KEY_EXPIRES] withOffset:[json objectForKey:KEY_OFFSET]]];
                
                [currentAlert setAlertTitle:[dataAlert objectForKey:KEY_TITLE]];
                [currentAlert setAlertDescription:[dataAlert objectForKey:KEY_DESCRIPTION]];
                
                [alerts addObject:currentAlert];
            }
        }
    }
    
    if ([alerts count] > 0) {
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
        
        date = [NSDate dateWithTimeIntervalSince1970:[number longValue] + [offsetseconds longValue]];
    }
    
    return date;
}


@end
