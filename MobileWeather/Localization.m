//
//  Localization.m
//  MobileWeather
//
//  Copyright (c) 2013-2015 Ford Motor Company. All rights reserved.
//

#import "Localization.h"

/** Private definition extending setter for the properties. */
@interface Localization ()

@property (copy, nonatomic, readwrite) NSString *language;
@property (copy, nonatomic, readwrite) NSString *region;
@property (strong, nonatomic, readwrite) NSBundle *defaultBundle;
@property (strong, nonatomic, readwrite) NSLocale *defaultLocale;
@property (strong, nonatomic, readwrite) NSBundle *fallbackBundle;
@property (strong, nonatomic, readwrite) NSLocale *fallbackLocale;

@end

@implementation Localization

- (NSBundle *)bundle {
    if (self.defaultBundle) {
        return self.defaultBundle;
    } else if (self.fallbackBundle) {
        return self.fallbackBundle;
    } else {
        return nil;
    }
}

- (NSLocale *)locale {
    if (self.defaultLocale) {
        return self.defaultLocale;
    } else if (self.fallbackLocale) {
        return self.fallbackLocale;
    } else {
        return nil;
    }
}

+ (instancetype)defaultLocalization {
    static Localization *object = nil;
    static dispatch_once_t token;

    dispatch_once(&token, ^{
        // get the locale identifier
        NSString *localeIdentifier = [NSLocale currentLocale].localeIdentifier;
        // extract language
        NSString *language = (localeIdentifier.length >= 2 ? [localeIdentifier substringWithRange:NSMakeRange(0, 2)].lowercaseString : nil);
        // extract region
        NSString *region   = (localeIdentifier.length >= 5 ? [localeIdentifier substringWithRange:NSMakeRange(3, 2)].uppercaseString : nil);
        
        NSBundle *defaultBundle = nil;
        NSLocale *defaultLocale = nil;
        NSBundle *fallbackBundle = nil;
        NSLocale *fallbackLocale = nil;
        
        // create default bundle and locale for language AND region only
        if (language != nil && region != nil) {
            // create a new locale identifier matching the bundle path for language AND region
            localeIdentifier = [NSString stringWithFormat:@"%@-%@", language.lowercaseString, language.uppercaseString];
            // try to create a bundle for language AND region
            defaultBundle = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:localeIdentifier ofType:@"lproj"]];
            // do we have a bundle for language AND region?
            if (defaultBundle != nil) {
                // we do. create a locale for language AND region
                defaultLocale = [NSLocale localeWithLocaleIdentifier:localeIdentifier];
            }
        }
        
        // create fallback bundle and locale for language ONLY
        if (language != nil) {
            // create a new locale identifier matching the bundle path for langauge ONLY
            localeIdentifier = language.lowercaseString;
            // try to create a bundle for language ONLY
            fallbackBundle = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:localeIdentifier ofType:@"lproj"]];
            // do we have a bundle for language ONLY?
            if (fallbackBundle != nil) {
                // we do. create a locale for language ONLY
                fallbackLocale = [NSLocale localeWithLocaleIdentifier:localeIdentifier];
            }
        }
        
        // do we have any bundle object?
        if (defaultBundle == nil && fallbackBundle == nil) {
            // we don't. use system objects
            fallbackBundle = [NSBundle mainBundle];
            fallbackLocale = [NSLocale currentLocale];
        }
        
        object = [[Localization alloc] init];
        object.language = language;
        object.region = region;
        object.defaultBundle = defaultBundle;
        object.defaultLocale = defaultLocale;
        object.fallbackBundle = fallbackBundle;
        object.fallbackLocale = fallbackLocale;
    });
    
    return object;
}

+ (instancetype)localizationForLanguage:(NSString *)language forRegion:(NSString *)region {
    Localization *localization = nil;
    
    // get the locale identifier
    NSString *localeIdentifier = nil;
    
    NSBundle *defaultBundle = nil;
    NSLocale *defaultLocale = nil;
    NSBundle *fallbackBundle = nil;
    NSLocale *fallbackLocale = nil;
    
    // create default bundle and locale for language AND region only
    if (language != nil && region != nil) {
        // create a new locale identifier matching the bundle path for language AND region
        localeIdentifier = [NSString stringWithFormat:@"%@-%@", language.lowercaseString, language.uppercaseString];
        // try to create a bundle for language AND region
        defaultBundle = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:localeIdentifier ofType:@"lproj"]];
        // do we have a bundle for language AND region?
        if (defaultBundle != nil) {
            // we do. create a locale for language AND region
            defaultLocale = [NSLocale localeWithLocaleIdentifier:localeIdentifier];
        }
    }
    
    // create fallback bundle and locale for language ONLY
    if (language != nil) {
        // create a new locale identifier matching the bundle path for langauge ONLY
        localeIdentifier = language.lowercaseString;
        // try to create a bundle for language ONLY
        fallbackBundle = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:localeIdentifier ofType:@"lproj"]];
        // do we have a bundle for language ONLY?
        if (fallbackBundle != nil) {
            // we do. create a locale for language ONLY
            fallbackLocale = [NSLocale localeWithLocaleIdentifier:localeIdentifier];
        }
    }
    
    // do we have any bundle object?
    if (defaultBundle == nil && fallbackBundle == nil) {
        // We don't. Use default object
        return [self defaultLocalization];
    }
    
    localization = [[Localization alloc] init];
    localization.language = language;
    localization.region = region;
    localization.defaultBundle = defaultBundle;
    localization.defaultLocale = defaultLocale;
    localization.fallbackBundle = fallbackBundle;
    localization.fallbackLocale = fallbackLocale;

    return localization;
}

- (NSString *)stringForKey:(NSString *)key, ... {
    va_list args;
    va_start(args, key);
    
    NSString *format = nil;
    NSString *string = nil;
    
    // do we have a default bundle?
    if (self.defaultBundle != nil) {
        // we do. use it
        format = [self.defaultBundle localizedStringForKey:key value:nil table:nil];
        // does the default bundle has a string for the key?
        if (format != nil) {
            // it does. get the string using the default locale.
            string = [[NSString alloc] initWithFormat:format locale:self.defaultLocale arguments:args];
        }
    }
    
    // no default bundle keeps format to be nil. if format is nil then args is still valid. do we need to use the fallback?
    if (self.fallbackBundle != nil && format == nil) {
        // we do. use it
        format = [self.fallbackBundle localizedStringForKey:key value:nil table:nil];
        // does the fallback bundle has a string for the key?
        if (format != nil) {
            // it does. get the string using the fallback locale.
            string = [[NSString alloc] initWithFormat:format locale:self.fallbackLocale arguments:args];
        }
    }
    
    
    va_end(args);
    
    return string;
}

- (id)objectForKeyedSubscript:(NSString *)key {
    return [self stringForKey:key];
}

@end
