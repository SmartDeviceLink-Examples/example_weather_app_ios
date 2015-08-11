//
//  AlertType.m
//  MobileWeather
//
//  Copyright (c) 2013-2015 Ford Motor Company. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AlertType.h"

#define ENUM_IMPLEMENT() \
static id object = nil; \
static dispatch_once_t token; \
dispatch_once(&token, ^{ object = [[self alloc] initWithValue:NSStringFromSelector(_cmd)]; }); \
return object

@implementation AlertType

+ (instancetype)HUR {
    ENUM_IMPLEMENT();
}

+ (instancetype)TOR {
    ENUM_IMPLEMENT();
}

+ (instancetype)TOW {
    ENUM_IMPLEMENT();
}

+ (instancetype)WRN {
    ENUM_IMPLEMENT();
}

+ (instancetype)SEW {
    ENUM_IMPLEMENT();
}

+ (instancetype)WIN {
    ENUM_IMPLEMENT();
}

+ (instancetype)FLO {
    ENUM_IMPLEMENT();
}

+ (instancetype)WAT {
    ENUM_IMPLEMENT();
}

+ (instancetype)WND {
    ENUM_IMPLEMENT();
}

+ (instancetype)SVR {
    ENUM_IMPLEMENT();
}

+ (instancetype)HEA {
    ENUM_IMPLEMENT();
}

+ (instancetype)FOG {
    ENUM_IMPLEMENT();
}

+ (instancetype)SPE {
    ENUM_IMPLEMENT();
}

+ (instancetype)FIR {
    ENUM_IMPLEMENT();
}

+ (instancetype)VOL {
    ENUM_IMPLEMENT();
}

+ (instancetype)HWW {
    ENUM_IMPLEMENT();
}

+ (instancetype)REC {
    ENUM_IMPLEMENT();
}

+ (instancetype)REP {
    ENUM_IMPLEMENT();
}

+ (instancetype)PUB {
    ENUM_IMPLEMENT();
}

@end