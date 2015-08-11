//
//  NSUserDefaults+RegisterSettings.h
//  MobileWeather
//
//  Copyright (c) 2013-2015 Ford Motor Company. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSUserDefaults (RegisterSettings)

/**
 * Initializes all settings based on the settings bundle inside the main bundle.
 * All these settings will be set to its default value. This will ensure that the app will always get a value (even the default value) instead of nil.
 * Getting the default value when no setting was set before eliminates the need of writing code to manually determine default values or copying it from
 * the settings bundle. This way the app will only have one place where default values must be hold.
 */
- (void)registerDefaultsFromSettingsBundle;

@end
