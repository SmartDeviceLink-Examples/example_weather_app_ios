//
//  UnitConverter.m
//  MobileWeather
//
//  Copyright (c) 2013-2015 Ford Motor Company. All rights reserved.
//

#import "UnitConverter.h"

@implementation UnitConverter

+ (NSNumber *)convertLength:(NSNumber *)length from:(UnitLengthType)fromUnit to:(UnitLengthType)toUnit {
    double multiplierFrom;
    double multiplierTo;
    
    // if input value is nil then return nil
    if (length == nil) return nil;
    
    // if we want to use the same unit then immediately return
    if (fromUnit == toUnit) return length;
    
    // first convert to SI unit meter
    switch (fromUnit) {
        case UnitLengthKiloMeter:
            multiplierFrom = 1000;
            break;
        case UnitLengthMeter:
            multiplierFrom = 1.0;
            break;
        case UnitLengthCentiMeter:
            multiplierFrom = 0.01;
            break;
        case UnitLengthMilliMeter:
            multiplierFrom = 0.001;
            break;
        case UnitLengthMile:
            multiplierFrom = 1609.344;
            break;
        case UnitLengthYard:
            multiplierFrom = 0.9144;
            break;
        case UnitLengthInch:
            multiplierFrom = 0.0254;
            break;
        default:
            return nil;
    }
    
    // convert from SI unit meter to
    switch (toUnit) {
        case UnitLengthKiloMeter:
            multiplierTo = 0.0001;
            break;
        case UnitLengthMeter:
            multiplierTo = 1.0;
            break;
        case UnitLengthCentiMeter:
            multiplierTo = 10.0;
            break;
        case UnitLengthMilliMeter:
            multiplierTo = 100.0;
            break;
        case UnitLengthMile:
            multiplierTo = 0.00062137119224;
            break;
        case UnitLengthYard:
            multiplierTo = 1.09361329833771;
            break;
        case UnitLengthInch:
            multiplierTo = 39.37007874015748;
            break;
        default:
            return nil;
    }
    
    return @(length.doubleValue * (multiplierFrom * multiplierTo));
}

+ (NSNumber *)convertTemperature:(NSNumber *)temperature from:(UnitTemperatureType)fromUnit to:(UnitTemperatureType)toUnit {
    // if input value is nil then return nil
    if (temperature == nil) return nil;
    
    // if we want to use the same unit then immediately return
    if (fromUnit == toUnit) return temperature;
    
    if (fromUnit == UnitTemperatureCelsius && toUnit == UnitTemperatureFahrenheit) {
        // from celsius to fahrenheit
        return @((temperature.doubleValue * 9/5) + 32);
    }
    else if (fromUnit == UnitTemperatureFahrenheit && toUnit == UnitTemperatureCelsius) {
        // from fahrenheit to celsius
        return @((temperature.doubleValue - 32) * 5/9);
    }
    else {
        return nil;
    }
}

+ (NSNumber *)convertSpeed:(NSNumber *)speed from:(UnitSpeedType)fromUnit to:(UnitSpeedType)toUnit {
    double multiplierFrom;
    double multiplierTo;
    
    // if input value is nil then return nil
    if (speed == nil) return nil;
    
    // if we want to use the same unit then immediately return
    if (fromUnit == toUnit) return speed;
    
    // first convert to SI unit m/s (meter per second)
    switch (fromUnit) {
        case (UnitSpeedMeterSecond):
            multiplierFrom = 1.0;
            break;
        case (UnitSpeedKiloMeterHour):
            multiplierFrom = 0.27777777777778;
            break;
        case (UnitSpeedMileHour):
            multiplierFrom = 0.44704;
            break;
        default:
            return nil;
    }
    
    switch (toUnit) {
        case (UnitSpeedMeterSecond):
            multiplierTo = 1.0;
            break;
        case (UnitSpeedKiloMeterHour):
            multiplierTo = 3.6;
            break;
        case (UnitSpeedMileHour):
            multiplierTo = 2.2369362920544;
            break;
        default:
            return nil;
    }
    
    return @(speed.doubleValue * (multiplierFrom * multiplierTo));
}

+ (NSNumber *)convertTime:(NSNumber *)time from:(UnitTimeType)fromUnit to:(UnitTimeType)toUnit {
    double multiplierFrom;
    double multiplierTo;
    
    // if input value is nil then return nil
    if (time == nil) return nil;
    
    // if we want to use the same unit then immediately return
    if (fromUnit == toUnit) return time;
    
    // first convert to SI unit s (second)
    switch (fromUnit) {
        case (UnitTimeSecond):
            multiplierFrom = 1.0;
            break;
        case (UnitTimeMinute):
            multiplierFrom = 60.0;
            break;
        case (UnitTimeHour):
            multiplierFrom = 3600.0;
            break;
        case (UnitTimeMilliSecond):
            multiplierFrom = 0.001;
            break;
        default:
            return nil;
    }
    
    switch (toUnit) {
        case (UnitTimeSecond):
            multiplierTo = 1.0;
            break;
        case (UnitTimeMinute):
            multiplierTo = 0.01666666666667;
            break;
        case (UnitTimeHour):
            multiplierTo = 0.00027777777778;
            break;
        case (UnitTimeMilliSecond):
            multiplierTo = 1000;
            break;
        default:
            return nil;
    }
    
    return @(time.doubleValue * (multiplierFrom * multiplierTo));
}

+ (NSNumber *)convertPercentage:(NSNumber *)percentage from:(UnitPercentageType)fromUnit to:(UnitPercentageType)toUnit {
    double multiplierFrom;
    double multiplierTo;
    
    // if input value is nil then return nil
    if (percentage == nil) return nil;
    
    // if we want to use the same unit then immediately return
    if (fromUnit == toUnit) return percentage;
    
    switch (fromUnit) {
        case UnitPercentageDefault:
            multiplierFrom = 1.0;
            break;
        case UnitPercentageFactor:
            multiplierFrom = 100.0;
            break;
        default:
            return nil;
    }
    
    switch (toUnit) {
        case UnitPercentageDefault:
            multiplierTo = 1.0;
            break;
        case UnitPercentageFactor:
            multiplierTo = 0.001;
        default:
            return nil;
    }
    
    return @(percentage.doubleValue * (multiplierFrom * multiplierTo));
}

@end
