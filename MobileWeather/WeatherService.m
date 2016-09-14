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
        NSString *language = [[[NSLocale preferredLanguages] objectAtIndex:0] substringToIndex:2];
        [self setLanguage:[WeatherLanguage elementWithValue:[language uppercaseString]]];
    }
    
    return self;
}

- (void)dealloc {
    [self stop];
}

- (void)start {
    if ([self isStarted]) return;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleUpdateNotification:) name:MobileWeatherLocationUpdateNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleUpdateNotification:) name:MobileWeatherTimeUpdateNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleUpdateNotification:) name:MobileWeatherLanguageUpdateNotification object:nil];
    
    // load api key from settings
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [self setServiceApiKey:[defaults objectForKey:PREFS_WEATHER_API_KEY]];
    
    if ([self serviceApiKey] == nil || [[self serviceApiKey] isEqualToString:@""]) {
        NSString *message = [NSString stringWithFormat:@"In order to use this demo app you need to get an API key of %@.\nIf you already have an API key please open Settings app and copy the key into MobileWeather settings.", [self serviceName]];
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"API key" message:message delegate:self cancelButtonTitle:@"Close" otherButtonTitles:@"Website", nil];
        
        [alertView show];
        
        [self stop];
    } else {
        [self setIsStarted:YES];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:MobileWeatherServiceLoadedNotification object:self userInfo:@{ @"image": [self serviceLogo] }];
    }
}

- (void)stop {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self setServiceApiKey:nil];
    [self setIsStarted:NO];
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [[UIApplication sharedApplication] openURL:[self serviceURL]];
    }
}

- (void)handleUpdateNotification:(NSNotification *)notification {
    BOOL success = NO;
    
    if ([[notification name] isEqualToString:MobileWeatherLocationUpdateNotification]) {
        [self setLastLocation:[[notification userInfo] objectForKey:@"location"]];
    }
    
    if ([[notification name] isEqualToString:MobileWeatherLanguageUpdateNotification]) {
        WeatherLanguage *newlanguage = [[notification userInfo] objectForKey:@"language"];
        if (newlanguage != [self language]) {
            [self setLanguage:newlanguage];
        } else {
            // language notification received but language has not changed. No update please.
            return;
        }
    }
    
    // a location is the most important property needed. if we have a location please update weather data.
    if ([self lastLocation]) {
        // get the language desired
        WeatherLanguage *language = [self language] ?: [WeatherLanguage DEFAULT];
        // get the url based on location and language.
        NSURL *url = [self urlForLocation:[self lastLocation] forLanguage:language];
        // get the weather data based on the url and update the weather data manager.
        success = [self updateWeatherDataFromUrl:url forLanguage:language];
    }
    
    // just in case we have received the time update notification we need to inform for completion
    if ([[notification name] isEqualToString:MobileWeatherTimeUpdateNotification]) {
        // get the completion handler
        void (^completionHandler)(UIBackgroundFetchResult)  = [[notification userInfo] objectForKey:@"completion"];
        
        // do we have a completion handler?
        if (completionHandler) {
            if (success) {
                // if the weather data update was successful then tell we have new data
                completionHandler(UIBackgroundFetchResultNewData);
            } else {
                // unsucessful update will result in no new data.
                completionHandler(UIBackgroundFetchResultNoData);
            }
        }
    }
}

- (NSURL *)urlForLocation:(WeatherLocation *)location forLanguage:(WeatherLanguage *)language {
    @throw [NSException exceptionWithName:@"NotImplementedException" reason:@"This method must be implemented from subclass" userInfo:nil];
    return nil;
}

- (BOOL)updateWeatherDataFromUrl:(NSURL *)url forLanguage:(WeatherLanguage *)language {
    @throw [NSException exceptionWithName:@"NotImplementedException" reason:@"This method must be implemented from subclass" userInfo:nil];
    return NO;
}

@end
