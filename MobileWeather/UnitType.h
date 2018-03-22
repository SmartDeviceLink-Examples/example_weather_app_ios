//
//  UnitType.h
//  MobileWeather
//
//  Copyright (c) 2013-2015 Ford Motor Company. All rights reserved.
//

#import <Foundation/Foundation.h>

/** Lists frequently used length types. Overall 18 types can be covered by this enum. */
typedef NS_OPTIONS(NSUInteger, UnitLengthType) {
    UnitLengthMilliMeter    = 1 << 0,
    UnitLengthCentiMeter    = 1 << 1,
    UnitLengthMeter         = 1 << 2,
    UnitLengthKiloMeter     = 1 << 3,
    UnitLengthMile          = 1 << 4,
    UnitLengthYard          = 1 << 5,
    UnitLengthInch          = 1 << 6,
};

/** Lists frequently used time types. Overall 8 types can be covered by this enum. */
typedef NS_OPTIONS(NSUInteger, UnitTimeType) {
    UnitTimeMilliSecond     = 1 << 18,
    UnitTimeSecond          = 1 << 19,
    UnitTimeMinute          = 1 << 20,
    UnitTimeHour            = 1 << 21,
};

/** Lists frequently used temperature types. Overall 4 types can be covered by this enum. */
typedef NS_OPTIONS(NSUInteger, UnitTemperatureType) {
    UnitTemperatureCelsius      = 1 << 26,
    UnitTemperatureFahrenheit   = 1 << 27,
};

/** Lists possibilities to represent a value by percentage or as a factor. */
typedef NS_OPTIONS(NSUInteger, UnitPercentageType) {
    UnitPercentageDefault  = 1 << 30,
    UnitPercentageFactor   = 1 << 31,
};

typedef NS_OPTIONS(NSUInteger, UnitSpeedType) {
    UnitSpeedMeterSecond    = UnitLengthMeter     | UnitTimeSecond,
    UnitSpeedKiloMeterHour  = UnitLengthKiloMeter | UnitTimeHour,
    UnitSpeedMileHour       = UnitLengthMile      | UnitTimeHour,
};

/** Lists general unit groups. */
typedef NS_ENUM(NSUInteger, UnitType) {
    UnitTypeUnknown     = 0,
    UnitTypeImperial    = 1,
    UnitTypeMetric      = 2,
};
