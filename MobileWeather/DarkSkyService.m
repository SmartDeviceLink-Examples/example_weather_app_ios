//
//  ForecastIOService.m
//  MobileWeather
//
//  Copyright (c) 2013-2015 Ford Motor Company. All rights reserved.
//

#import "DarkSkyService.h"

#import "Notifications.h"
#import "WeatherConditions.h"
#import "DarkSkyProcessor.h"
#import "WeatherLocation.h"
#import "Alert.h"
#import "UnitType.h"
#import "WeatherLanguage.h"

NSString *const DarkSkyBaseURL = @"https://api.darksky.net/forecast";
NSString *const DarkSkyUnit = @"units=si";
NSString *const DarkSkyExclude = @"exclude=minutely,flags";
NSString *const DarkSkyLanguage = @"lang=%@";

@interface DarkSkyService() <NSURLSessionTaskDelegate>

@property (strong, nonatomic) NSURLSessionDataTask *currentTask;

@end

@implementation DarkSkyService

- (instancetype)init {
    if (self = [super init]) {
        self.serviceName = @"DarkSky";
        self.serviceURL = [NSURL URLWithString:@"https://darksky.net/dev"];
    }
    
    return self;
}

- (NSURL *)urlForLocation:(WeatherLocation *)location forLanguage:(WeatherLanguage *)language {
    NSMutableString *urlstring = [NSMutableString stringWithCapacity:2048];
    [urlstring appendString:DarkSkyBaseURL];
    [urlstring appendString:@"/"];
    [urlstring appendString:self.serviceApiKey];
    [urlstring appendString:@"/"];
    [urlstring appendString:[NSString stringWithFormat:@"%f", location.gpsLocation.coordinate.latitude]];
    [urlstring appendString:@","];
    [urlstring appendString:[NSString stringWithFormat:@"%f", location.gpsLocation.coordinate.longitude]];
    [urlstring appendString:@"?"];
    [urlstring appendString:DarkSkyUnit];
    [urlstring appendString:@"&"];
    [urlstring appendString:DarkSkyExclude];
    [urlstring appendString:@"&"];
    [urlstring appendString:[NSString stringWithFormat:DarkSkyLanguage, language.value.lowercaseString]];
    
    NSURL *url = [NSURL URLWithString:urlstring];
    return url;
}

- (void)updateWeatherDataFromUrl:(NSURL *)url forLanguage:(WeatherLanguage *)language {
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:4];

    self.currentTask = [[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error != nil) {
            NSLog(@"Error retrieving weather data");
            return;
        }

        NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        if (jsonData == nil) {
            NSLog(@"Error parsing weather data");
            return;
        }

        WeatherConditions *conditions = [DarkSkyProcessor weatherConditions:jsonData];
        NSArray *dailyForecast = [DarkSkyProcessor dailyForecast:jsonData];
        NSArray *hourlyForecast = [DarkSkyProcessor hourlyForecast:jsonData];
        NSArray *alerts = [DarkSkyProcessor alerts:jsonData];
        userInfo[@"language"] = language;

        if (conditions != nil) {
            userInfo[@"weatherConditions"] = conditions;
        }

        if (dailyForecast != nil) {
            userInfo[@"dailyForecast"] = dailyForecast;
        }

        if (hourlyForecast != nil) {
            userInfo[@"hourlyForecast"] = hourlyForecast;
        }

        if (alerts != nil) {
            userInfo[@"alerts"] = alerts;
        }

        if (userInfo.count > 0) {
            [[NSNotificationCenter defaultCenter] postNotificationName:MobileWeatherDataUpdatedNotification object:self userInfo:userInfo];
        }
    }];
    [self.currentTask resume];
}

@end
