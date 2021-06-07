//
//  WeatherDataManager.m
//  MobileWeather
//
//  Copyright (c) 2013-2015 Ford Motor Company. All rights reserved.
//

@import WeatherLocationService;

#import "WeatherDataManager.h"

#import "Notifications.h"
#import "Settings.h"
#import "WeatherConditions.h"
#import "WeatherLanguage.h"
#import "Forecast.h"
#import "Alert.h"

@interface WeatherDataManager()

/** This property is used to remember the last known unit type that is set in the settings app. Important to do unit change notification. */
@property (nonatomic) UnitType lastKnownUnit;


@end

@implementation WeatherDataManager

+ (instancetype)sharedManager {
    static id shared = nil;
    static dispatch_once_t token;
    
    dispatch_once(&token, ^{
        shared = [[self alloc] init];
    });
    
    return shared;
}

- (instancetype)init {
    if (self = [super init]) {
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        
        // copy the unit value that is saved in the settings app.
        self.lastKnownUnit = self.unit;
        
        [center addObserver:self selector:@selector(handleLocationUpdate:) name:MobileWeatherLocationUpdateNotification object:nil];
        [center addObserver:self selector:@selector(handleWeatherDataUpdate:) name:MobileWeatherDataUpdatedNotification object:nil];
        [center addObserver:self selector:@selector(handleUserDefaultsUpdate:) name:NSUserDefaultsDidChangeNotification object:nil];
    }
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)handleLocationUpdate:(NSNotification *)notification {
    WeatherLocation *location = notification.userInfo[@"location"];
    self.currentLocation = location;
}

- (void)handleWeatherDataUpdate:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    WeatherLanguage *language = userInfo[@"language"];
    WeatherConditions *conditions = userInfo[@"weatherConditions"];
    NSArray *dailyForecast = userInfo[@"dailyForecast"];
    NSArray *hourlyForecast = userInfo[@"hourlyForecast"];
    NSArray *alerts = userInfo[@"alerts"];

    self.language = language;
    self.weatherConditions = conditions;
    self.dailyForecast = dailyForecast;
    self.hourlyForecast = hourlyForecast;
    self.alerts = alerts;
}

- (void)handleUserDefaultsUpdate:(NSNotification *)notification {
    UnitType old = self.lastKnownUnit;
    UnitType new = self.unit;
    
    if (old != new) {
        self.lastKnownUnit = new;
        [[NSNotificationCenter defaultCenter] postNotificationName:MobileWeatherUnitChangedNotification object:self userInfo:@{@"old": @(old), @"new": @(new)}];
    }
}

- (UnitType)unit {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *unit = [defaults stringForKey:@"unit"];
    
    if ([PREFS_UNITS_METRIC_KEY isEqualToString:unit]) {
        return UnitTypeMetric;
    }
    else if ([PREFS_UNITS_IMPERIAL_KEY isEqualToString:unit]) {
        return UnitTypeImperial;
    }
    else {
        return UnitTypeUnknown;
    }
}

- (void)setUnit:(UnitType)unit {
    NSString *unitstring = unit == UnitTypeImperial ? PREFS_UNITS_IMPERIAL_KEY : PREFS_UNITS_METRIC_KEY;
    
    // get the app settings and change the unit desired
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:unitstring forKey:PREFS_UNITS_KEY];
    [defaults synchronize];
}


@end
