//
//  UnitNumber.m
//  MobileWeather
//
//  Copyright (c) 2013-2015 Ford Motor Company. All rights reserved.
//

#import "UnitNumber.h"

@interface UnitNumber()

@property (assign, nonatomic, readwrite) NSUInteger unit;
@property (copy, nonatomic, readwrite) NSNumber *number;

@end

@implementation UnitNumber

+ (instancetype)numberWithNumber:(NSNumber *)number withUnitValue:(NSUInteger)unit {
    return [[self alloc] initWithNumber:number withUnitValue:unit];
}

- (instancetype)initWithNumber:(NSNumber *)number withUnitValue:(NSUInteger)unit {
    if (self = [super init]) {
        self.unit = unit;
        self.number = [number copy];
    }
    
    return self;
}

@end
