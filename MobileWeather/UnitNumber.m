//
//  UnitNumber.m
//  MobileWeather
//
//  Copyright (c) 2013-2015 Ford Motor Company. All rights reserved.
//

#import "UnitNumber.h"

@implementation UnitNumber

+ (instancetype)numberWithNumber:(NSNumber *)number withUnitValue:(NSUInteger)unit {
    return [[self alloc] initWithNumber:number withUnitValue:unit];
}

- (instancetype)initWithNumber:(NSNumber *)number withUnitValue:(NSUInteger)unit {
    if (self = [super init]) {
        self->_unit = unit;
        self->_number = [number copy];
    }
    
    return self;
}

@end
