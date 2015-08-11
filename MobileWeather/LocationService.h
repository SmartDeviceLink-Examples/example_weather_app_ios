//
//  LocationService.h
//  MobileWeather
//
//  Copyright (c) 2013-2015 Ford Motor Company. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WeatherLocation.h"

@interface LocationService : NSObject

+ (instancetype)sharedService;

- (void)start;
- (void)stop;

@end
