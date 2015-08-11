//
//  WeatherLanguage.h
//  MobileWeather
//
//  Copyright (c) 2013-2015 Ford Motor Company. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EnumType.h"

@interface WeatherLanguage : EnumType

/** Returns the language code for Bosnian. */
+ (instancetype)BS;

/** Returns the language code for German. */
+ (instancetype)DE;

/** Returns the language code for English. */
+ (instancetype)EN;

/** Returns the language code for Spanish. */
+ (instancetype)ES;

/** Returns the language code for French. */
+ (instancetype)FR;

/** Returns the language code for Italian. */
+ (instancetype)IT;

/** Returns the language code for Dutch. */
+ (instancetype)NL;

/** Returns the language code for Polish. */
+ (instancetype)PL;

/** Returns the language code for Portuguese. */
+ (instancetype)PT;

/** Returns the language code for Russian. */
+ (instancetype)RU;

/** Returns the default languge if no language is specified. */
+ (instancetype)DEFAULT;

@end
