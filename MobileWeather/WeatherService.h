//
//  WeatherService.h
//  MobileWeather
//
//  Copyright (c) 2013-2015 Ford Motor Company. All rights reserved.
//

@import UIKit;

@class Alert;
@class WeatherLanguage;
@class WeatherLocation;


@interface WeatherService : NSObject

@property NSString *serviceName;

@property NSString *serviceApiKey;

@property UIImage *serviceLogo;

@property NSURL *serviceURL;

@property BOOL isStarted;

+ (instancetype)sharedService;

- (void)start;
- (void)stop;

- (NSURL *)urlForLocation:(WeatherLocation *)location forLanguage:(WeatherLanguage *)language;

- (BOOL)updateWeatherDataFromUrl:(NSURL *)url forLanguage:(WeatherLanguage *)language;

@end
