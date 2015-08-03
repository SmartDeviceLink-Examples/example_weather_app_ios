//
//  AppDelegate.m
//  MobileWeather
//
//  Copyright (c) 2013-2015 Ford Motor Company. All rights reserved.
//

#import "AppDelegate.h"
#import "Notifications.h"
#import "ForecastIOService.h"
#import "LocationService.h"
#import "SmartDeviceLinkService.h"

@interface AppDelegate ()
@property UIViewController *mainViewController;
@property UIViewController *lockScreenViewController;
@end

@implementation AppDelegate

- (void)lockScreen:(NSNotification *)notification {
    @synchronized (self) {
        UIViewController *root = [[self window] rootViewController];
        // Display the lock screen if it is not presented already.
        if ([root isEqual:[self lockScreenViewController]] == NO) {
            [[self window] setRootViewController:[self lockScreenViewController]];
        }
    }
}

- (void)unlockScreen:(NSNotification *)notification {
    @synchronized (self) {
        UIViewController *root = [[self window] rootViewController];
        // Display the regular screen if it is not presented already.
        if ([root isEqual:[self mainViewController]] == NO) {
            [[self window] setRootViewController:[self mainViewController]];
        }
    }
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Register every setting of the settings bundle and set it to its default value if it does not have any value set.
    [[NSUserDefaults standardUserDefaults] registerDefaultsFromSettingsBundle];
    
    [self setMainViewController:[[self window] rootViewController]];
    [self setLockScreenViewController:[[UIViewController alloc]
                                       initWithNibName:@"LockScreen" bundle:[NSBundle mainBundle]]];
    
    // Add observer to lock screen notifications
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self
               selector:@selector(lockScreen:)
                   name:SDLRequestsLockScreenNotification
                 object:nil];
    
    [center addObserver:self
               selector:@selector(unlockScreen:)
                   name:SDLRequestsUnlockScreenNotification
                 object:nil];
    
    [[SmartDeviceLinkService sharedService] start];
    
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // start the weather service
    if ([[ForecastIOService sharedService] isStarted] == NO) {
        [[ForecastIOService sharedService] start];
        // is it started? (API key etc. works)
        if ([[ForecastIOService sharedService] isStarted]) {
            // Start the services
            [[LocationService sharedService] start];
            
            // Setup background app refresh time.
            [application setMinimumBackgroundFetchInterval:30.0];
        }
    }
}

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    // Post notification that we want an update of the weather data
    [[NSNotificationCenter defaultCenter] postNotificationName:MobileWeatherTimeUpdateNotification object:self userInfo:@{@"completion": completionHandler}];
}

@end
