//
//  UnitConverter.h
//  MobileWeather
//
//  Copyright (c) 2013-2015 Ford Motor Company. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UnitType.h"

@interface UnitConverter : NSObject

+ (NSNumber *)convertLength:(NSNumber *)length from:(UnitLengthType)fromUnit to:(UnitLengthType)toUnit;

+ (NSNumber *)convertTemperature:(NSNumber *)temperature from:(UnitTemperatureType)fromUnit to:(UnitTemperatureType)toUnit;

+ (NSNumber *)convertSpeed:(NSNumber *)speed from:(UnitSpeedType)fromUnit to:(UnitSpeedType)toUnit;

+ (NSNumber *)convertTime:(NSNumber *)time from:(UnitTimeType)fromUnit to:(UnitTimeType)toUnit;

+ (NSNumber *)convertPercentage:(NSNumber *)percentage from:(UnitPercentageType)fromUnit to:(UnitPercentageType)toUnit;

@end
