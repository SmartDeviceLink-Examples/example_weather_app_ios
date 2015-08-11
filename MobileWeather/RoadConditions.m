//
//  RoadConditions.m
//  MobileWeather
//
//  Copyright (c) 2013-2015 Ford Motor Company. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RoadConditions.h"

#define ENUM_IMPLEMENT() \
static id object = nil; \
static dispatch_once_t token; \
dispatch_once(&token, ^{ object = [[self alloc] initWithValue:NSStringFromSelector(_cmd)]; }); \
return object

@implementation RoadConditions

+ (instancetype)WET {
    ENUM_IMPLEMENT();
}

+ (instancetype)ICE {
    ENUM_IMPLEMENT();
}

+ (instancetype)FOG {
    ENUM_IMPLEMENT();
}

+ (instancetype)WIND {
    ENUM_IMPLEMENT();
}

+ (instancetype)LOW_VISIBILITY {
    ENUM_IMPLEMENT();
}

+ (instancetype)OK {
    ENUM_IMPLEMENT();
}

@end
