//
//  NSUserDefaults+RegisterSettings.m
//  MobileWeather
//
//  Copyright (c) 2013-2015 Ford Motor Company. All rights reserved.
//

#import "NSUserDefaults+RegisterSettings.h"

@implementation NSUserDefaults (RegisterSettings)

- (void)registerDefaultsFromSettingsBundle {
    // create a string to the settings bundle
    NSString *settingsPath = [[NSBundle mainBundle] pathForResource:@"Settings" ofType:@"bundle"];
    NSString *settingsFile = [settingsPath stringByAppendingPathComponent:@"Root.plist"];
    
    // load the bundle into a dictionary
    NSDictionary *settingsBundle = [NSDictionary dictionaryWithContentsOfFile:settingsFile];
    
    // get the internal list of preferences
    NSArray *preferences = [settingsBundle objectForKey:@"PreferenceSpecifiers"];
    
    // create a dictionary that will be used for the default settings
    NSMutableDictionary *defaults = [[NSMutableDictionary alloc] initWithCapacity:[preferences count]];
    
    // inside of the following iteration this variable will be used in combination with checks
    NSString *key;
    id defaultValue;
    
    // iterate through all preferences in the settings
    for (NSDictionary *preference in preferences) {
        key = [preference objectForKey:@"Key"];
        defaultValue = [preference objectForKey:@"DefaultValue"];

        // if the preference contains a key and default value (that will not match for groups etc.) set a default for it
        if (key && defaultValue) {
            // set the default value for our registration
            [defaults setObject:defaultValue forKey:key];
        }
    }
    
    if ([defaults count] > 0) {
        // register default values and synchronize
        [self registerDefaults:defaults];
        [self synchronize];
    }
}


@end
