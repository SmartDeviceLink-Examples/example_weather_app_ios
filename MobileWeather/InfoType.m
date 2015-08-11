//
//  InfoType.m
//  MobileWeather
//
//  Copyright (c) 2013-2015 Ford Motor Company. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "InfoType.h"


#define ENUM_IMPLEMENT() \
static id object = nil; \
static dispatch_once_t token; \
dispatch_once(&token, ^{ object = [[self alloc] initWithValue:NSStringFromSelector(_cmd)]; }); \
return object

@implementation InfoType

+ (instancetype)NONE {
    ENUM_IMPLEMENT();
}

+ (instancetype)WEATHER_CONDITIONS {
    ENUM_IMPLEMENT();
}

+ (instancetype)DAILY_FORECAST {
    ENUM_IMPLEMENT();
}

+ (instancetype)HOURLY_FORECAST {
    ENUM_IMPLEMENT();
}

+ (instancetype)ALERTS {
    ENUM_IMPLEMENT();
}

@end