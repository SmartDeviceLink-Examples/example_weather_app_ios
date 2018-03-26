//
//  WeatherService.m
//  MobileWeather
//
//  Copyright (c) 2013-2015 Ford Motor Company. All rights reserved.
//

#import "WeatherService.h"

#import "Notifications.h"
#import "Settings.h"
#import "WeatherLanguage.h"

@interface WeatherService () <UIAlertViewDelegate>

@property WeatherLocation *lastLocation;

@property WeatherLanguage *language;

@end

@implementation WeatherService

+ (instancetype)sharedService {
    static id shared = nil;
    static dispatch_once_t token;
    
    // when no subclass of weather service is initialized and sharedService is called by the base class then return nil.
    if (shared == nil && [self class] == [WeatherService class])
        return nil;
    
    dispatch_once(&token, ^{
        shared = [[self alloc] init];
    });
    
    return shared;
}

- (instancetype)init {
    if (self = [super init]) {
        [self setIsStarted:NO];
        [self setServiceApiKey:nil];
        
        // init the weather service using the phones language
        NSString *language = [[NSLocale preferredLanguages][0] substringToIndex:2];
        self.language = [WeatherLanguage elementWithValue:language.uppercaseString];
    }
    
    return self;
}

- (void)dealloc {
    [self stop];
}

- (void)start {
    if (self.isStarted) return;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleUpdateNotification:) name:MobileWeatherLocationUpdateNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleUpdateNotification:) name:MobileWeatherLanguageUpdateNotification object:nil];
    
    // load api key from settings
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.serviceApiKey = PREFS_WEATHER_API_KEY;
    
    if (self.serviceApiKey == nil || [self.serviceApiKey isEqualToString:@""]) {
        NSString *message = [NSString stringWithFormat:@"In order to use this demo app you need to get an API key of %@.\nIf you already have an API key please open Settings app and copy the key into MobileWeather settings.", self.serviceName];

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"API Key" message:message preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"Website" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[UIApplication sharedApplication] openURL:self.serviceURL];
        }];
        [alert addAction:action1];

        UIAlertAction *action2 = [UIAlertAction actionWithTitle:@"Close" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            [alert dismissViewControllerAnimated:YES completion:nil];
        }];
        [alert addAction:action2];

        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
        
        [self stop];
    } else {
        self.isStarted = YES;
    }
}

- (void)stop {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.serviceApiKey = nil;
    self.isStarted = NO;
}

- (void)handleUpdateNotification:(NSNotification *)notification {
    if ([notification.name isEqualToString:MobileWeatherLocationUpdateNotification]) {
        self.lastLocation = notification.userInfo[@"location"];
    }
    
    if ([notification.name isEqualToString:MobileWeatherLanguageUpdateNotification]) {
        WeatherLanguage *newlanguage = notification.userInfo[@"language"];
        if (newlanguage != self.language) {
            self.language = newlanguage;
        } else {
            // language notification received but language has not changed. No update please.
            return;
        }
    }
    
    // a location is the most important property needed. if we have a location please update weather data.
    if (self.lastLocation != nil) {
        // get the language desired
        WeatherLanguage *language = self.language ?: [WeatherLanguage DEFAULT];
        // get the url based on location and language.
        NSURL *url = [self urlForLocation:self.lastLocation forLanguage:language];
        // get the weather data based on the url and update the weather data manager.
        [self updateWeatherDataFromUrl:url forLanguage:language];
    }
}

- (NSURL *)urlForLocation:(WeatherLocation *)location forLanguage:(WeatherLanguage *)language {
    @throw [NSException exceptionWithName:@"NotImplementedException" reason:@"This method must be implemented from subclass" userInfo:nil];
    return nil;
}

- (void)updateWeatherDataFromUrl:(NSURL *)url forLanguage:(WeatherLanguage *)language {
    @throw [NSException exceptionWithName:@"NotImplementedException" reason:@"This method must be implemented from subclass" userInfo:nil];
}

@end
