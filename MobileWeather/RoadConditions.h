//
//  RoadConditions.h
//  MobileWeather
//
//  Copyright (c) 2013-2015 Ford Motor Company. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "EnumType.h"

@interface RoadConditions : EnumType

+ (instancetype)WET;

+ (instancetype)ICE;

+ (instancetype)FOG;

+ (instancetype)WIND;

+ (instancetype)LOW_VISIBILITY;

+ (instancetype)OK;

@end
