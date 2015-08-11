//
//  WeatherLanguage.m
//  MobileWeather
//
//  Copyright (c) 2013-2015 Ford Motor Company. All rights reserved.
//

#import "WeatherLanguage.h"


#define ENUM_IMPLEMENT() \
static id object = nil; \
static dispatch_once_t token; \
dispatch_once(&token, ^{ object = [[self alloc] initWithValue:NSStringFromSelector(_cmd)]; }); \
return object

@implementation WeatherLanguage

/** Returns the language code for Bosnian. */
+ (instancetype)BS {
    ENUM_IMPLEMENT();
}

/** Returns the language code for German. */
+ (instancetype)DE {
    ENUM_IMPLEMENT();
}

/** Returns the language code for English. */
+ (instancetype)EN {
    ENUM_IMPLEMENT();
}

/** Returns the language code for Spanish. */
+ (instancetype)ES {
    ENUM_IMPLEMENT();
}

/** Returns the language code for French. */
+ (instancetype)FR {
    ENUM_IMPLEMENT();
}

/** Returns the language code for Italian. */
+ (instancetype)IT {
    ENUM_IMPLEMENT();
}

/** Returns the language code for Dutch. */
+ (instancetype)NL {
    ENUM_IMPLEMENT();
}

/** Returns the language code for Polish. */
+ (instancetype)PL {
    ENUM_IMPLEMENT();
}

/** Returns the language code for Portuguese. */
+ (instancetype)PT {
    ENUM_IMPLEMENT();
}

/** Returns the language code for Russian. */
+ (instancetype)RU {
    ENUM_IMPLEMENT();
}

/** Returns the default language if no language is specified. */
+ (instancetype)DEFAULT {
    return [self EN];
}

@end
