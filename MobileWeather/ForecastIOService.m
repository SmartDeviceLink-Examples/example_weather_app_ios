//
//  ForecastIOService.m
//  MobileWeather
//
//  Copyright (c) 2013-2015 Ford Motor Company. All rights reserved.
//

#import "ForecastIOService.h"

#import "Notifications.h"
#import "HttpConnection.h"
#import "WeatherConditions.h"
#import "ForecastIOProcessor.h"
#import "WeatherLocation.h"
#import "Alert.h"
#import "UnitType.h"
#import "WeatherLanguage.h"

NSString *const DarkSkyBaseURL = @"https://api.darksky.net/forecast";
NSString *const DarkSkyUnit = @"units=si";
NSString *const DarkSkyExclude = @"exclude=minutely,flags";
NSString *const DarkSkyLanguage = @"lang=%@";

@implementation ForecastIOService

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

- (BOOL)updateWeatherDataFromUrl:(NSURL *)url forLanguage:(WeatherLanguage *)language {
    HttpConnection *connection = [[HttpConnection alloc] init];
    WeatherConditions *conditions = nil;

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    NSDictionary *root;
    NSArray *dailyForecast;
    NSArray *hourlyForecast;
    NSArray *alerts;
    NSString *result;
    NSData *data;
    
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:4];

    if (url) {
        data = [connection sendRequestForURL:url withMethod:HttpConnectionRequestMethodGET withData:nil ofType:@"application/json"];
        
        if (data) {
            result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

            if ([connection getStatusCodeFromStatusString:result] < 0) {
                root = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            
                if (root != nil) {
                    conditions = [ForecastIOProcessor weatherConditions:root];
                    dailyForecast = [ForecastIOProcessor dailyForecast:root];
                    hourlyForecast = [ForecastIOProcessor hourlyForecast:root];
                    alerts = [ForecastIOProcessor alerts:root];
                    
                    // first add the language to the user info object
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
                }
            }
        }
    }
    
    if (userInfo.count > 0) {
        [center postNotificationName:MobileWeatherDataUpdatedNotification object:self userInfo:userInfo];
        return YES;
    }
    else {
        return NO;
    }
}

@end
