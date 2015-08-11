//
//  SpeedNumber.m
//  MobileWeather
//
//  Copyright (c) 2013-2015 Ford Motor Company. All rights reserved.
//

#import "SpeedNumber.h"

@implementation SpeedNumber

- (UnitSpeedType)speedUnit {
    switch ([self unit]) {
        case UnitSpeedMeterSecond:
        case UnitSpeedKiloMeterHour:
        case UnitSpeedMileHour:
            return [self unit];
        default:
            return NSUIntegerMax;
    }
}

+ (instancetype)numberWithNumber:(NSNumber *)number withUnit:(UnitSpeedType)unit {
    return [super numberWithNumber:number withUnitValue:unit];
}

- (instancetype)initWithNumber:(NSNumber *)number withUnit:(UnitSpeedType)unit {
    return [super initWithNumber:number withUnitValue:unit];
}

- (double)doubleValueForUnit:(UnitSpeedType)unit {
    return [[UnitConverter convertSpeed:[self number] from:[self speedUnit] to:unit] doubleValue];
}

- (NSString *)stringValueForUnit:(UnitSpeedType)unit shortened:(BOOL)shortened {
    return [self stringValueForUnit:unit shortened:shortened localization:[Localization defaultLocalization]];
}

- (NSString *)stringValueForUnit:(UnitSpeedType)unit shortened:(BOOL)shortened format:(NSString *)format {
    return [self stringValueForUnit:unit shortened:shortened localization:[Localization defaultLocalization] format:format];
}

- (NSString *)stringValueForUnit:(UnitSpeedType)unit shortened:(BOOL)shortened localization:(Localization *)localization {
    return [self stringValueForUnit:unit shortened:shortened localization:localization format:@"%.0f"];
}

- (NSString *)stringValueForUnit:(UnitSpeedType)unit shortened:(BOOL)shortened localization:(Localization *)localization format:(NSString *)format {
    double convertedValue = [self doubleValueForUnit:unit];
    
    NSString *prefixString = nil;
    NSString *unitString = nil;
    NSString *valueString = nil;
    NSString *string = nil;
    
    // if the value is below zero (minus prefix) and we want to use a full string for voice engine then...
    if (convertedValue < 0 && shortened == NO) {
        // append minus into our format string
        prefixString = [localization stringForKey:@"units.negative"];
        // as minus is now handled we can get the positive value
        convertedValue *= -1.0;
    }
    else {
        // we dont want "plus" or "positive" or whatever
        prefixString = @"";
    }
    
    // get the unit with all the configurations.
    unitString = [self nameForUnit:unit shortened:shortened localization:localization format:format];
    
    // convert the value string
    valueString = [NSString stringWithFormat:format, convertedValue];
    
    // get all together
    string = [localization stringForKey:@"units.format", prefixString, valueString, unitString];
    
    // trim the string and return it (could be possible that leading whitespace are in string).
    return [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

- (NSString *)nameForUnit:(UnitSpeedType)unit shortened:(BOOL)shortened {
    return [self nameForUnit:unit shortened:shortened localization:[Localization defaultLocalization]];
}

- (NSString *)nameForUnit:(UnitSpeedType)unit shortened:(BOOL)shortened format:(NSString *)format {
    return [self nameForUnit:unit shortened:shortened localization:[Localization defaultLocalization] format:format];
}

- (NSString *)nameForUnit:(UnitSpeedType)unit shortened:(BOOL)shortened localization:(Localization *)localization {
    return [self nameForUnit:unit shortened:shortened localization:localization format:@"%f"];
}

- (NSString *)nameForUnit:(UnitSpeedType)unit shortened:(BOOL)shortened localization:(Localization *)localization format:(NSString *)format {
    // convert the value to the desired unit and format this value. At the end convert it to float again.
    double convertedValue = [[NSString stringWithFormat:format, [self doubleValueForUnit:unit]] floatValue];
    
    NSMutableString *unitkey = [NSMutableString stringWithString:@"units.speed"];
    
    switch (unit) {
        case UnitSpeedMeterSecond:
            [unitkey appendString:@".meter-second"];
            break;
        case UnitSpeedKiloMeterHour:
            [unitkey appendString:@".kilometer-hour"];
            break;
        case UnitSpeedMileHour:
            [unitkey appendString:@".mile-hour"];
            break;
        default:
            return nil;
    }
    
    if (shortened) {
        [unitkey appendString:@".short"];
    } else {
        [unitkey appendString:@".full"];
    }
    
    return [localization stringForKey:unitkey, convertedValue];
}

@end
