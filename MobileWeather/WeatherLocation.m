//
//  WeatherLocation.m
//  MobileWeather
//
//  Copyright (c) 2013-2015 Ford Motor Company. All rights reserved.
//

#import "WeatherLocation.h"

@implementation WeatherLocation

- (instancetype)initWithCity:(NSString *)city state:(NSString *)state zipCode:(NSString *)zip country:(NSString *)country gpsLocation:(CLLocation *)location {
    self = [super init];
    if (!self) { return nil; }

    _city = city;
    _state = state;
    _zipCode = zip;
    _country = country;
    _gpsLocation = location;

    return self;
}

@end
