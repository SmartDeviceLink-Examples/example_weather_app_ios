//
//  WeatherLocation.h
//  MobileWeather
//
//  Copyright (c) 2013-2015 Ford Motor Company. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GPSLocation.h"

@interface WeatherLocation : NSObject

@property (strong) NSString *country;
@property (strong) NSString *state;
@property (strong) NSString *city;
@property (strong) NSString *zipCode;
@property (strong) NSString *airportCode;
@property (strong) GPSLocation *gpsLocation;

@end
