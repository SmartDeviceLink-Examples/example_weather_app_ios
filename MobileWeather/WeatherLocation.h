//
//  WeatherLocation.h
//  MobileWeather
//
//  Copyright (c) 2013-2015 Ford Motor Company. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <CoreLocation/CoreLocation.h>

@class GPSLocation;

@interface WeatherLocation : NSObject

@property (copy, nonatomic) NSString *country;
@property (copy, nonatomic) NSString *state;
@property (copy, nonatomic) NSString *city;
@property (copy, nonatomic) NSString *zipCode;
@property (copy, nonatomic) CLLocation *gpsLocation;

- (instancetype)initWithCity:(NSString *)city state:(NSString *)state zipCode:(NSString *)zip country:(NSString *)country gpsLocation:(CLLocation *)location;

@end
