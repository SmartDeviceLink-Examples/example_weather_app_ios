//
//  AppDelegate.m
//  MobileWeather
//
//  Copyright (c) 2013-2015 Ford Motor Company. All rights reserved.
//

@import WeatherLocationService;

#import "AppDelegate.h"

#import "NSUserDefaults+RegisterSettings.h"
#import "Notifications.h"
#import "DarkSkyService.h"
#import "SmartDeviceLinkService.h"

@interface AppDelegate ()

@property UIViewController *mainViewController;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Register every setting of the settings bundle and set it to its default value if it does not have any value set.
    [[NSUserDefaults standardUserDefaults] registerDefaultsFromSettingsBundle];
    
    self.mainViewController = self.window.rootViewController;
    
    //connect & register service class to head unit.
    [[SmartDeviceLinkService sharedService] start];
    
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // start the weather service
    if ([DarkSkyService sharedService].isStarted == NO) {
        [[DarkSkyService sharedService] start];
        // is it started? (API key etc. works)
        if ([DarkSkyService sharedService].isStarted) {
            // Start the services
            [[LocationService shared] start];
            
            // Setup background app refresh time.
            [application setMinimumBackgroundFetchInterval:30.0];
        }
    }
}

@end
