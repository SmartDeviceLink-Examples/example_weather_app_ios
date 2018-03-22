//
//  TemperatureNumber.m
//  MobileWeather
//
//  Copyright (c) 2013-2015 Ford Motor Company. All rights reserved.
//

#import "TemperatureNumber.h"

#import "UnitConverter.h"
#import "Localization.h"


@implementation TemperatureNumber

- (UnitTemperatureType)temperatureUnit {
    switch (self.unit) {
        case UnitTemperatureCelsius:
        case UnitTemperatureFahrenheit:
            return self.unit;
        default:
            return NSUIntegerMax;
    }
}

+ (instancetype)numberWithNumber:(NSNumber *)number withUnit:(UnitTemperatureType)unit {
    return [super numberWithNumber:number withUnitValue:unit];
}

- (instancetype)initWithNumber:(NSNumber *)number withUnit:(UnitTemperatureType)unit {
    return [super initWithNumber:number withUnitValue:unit];
}

- (double)doubleValueForUnit:(UnitTemperatureType)unit {
    return [UnitConverter convertTemperature:self.number from:self.temperatureUnit to:unit].doubleValue;
}

- (NSString *)stringValueForUnit:(UnitTemperatureType)unit shortened:(BOOL)shortened {
    return [self stringValueForUnit:unit shortened:shortened localization:[Localization defaultLocalization]];
}

- (NSString *)stringValueForUnit:(UnitTemperatureType)unit shortened:(BOOL)shortened format:(NSString *)format {
    return [self stringValueForUnit:unit shortened:shortened localization:[Localization defaultLocalization] format:format];
}

- (NSString *)stringValueForUnit:(UnitTemperatureType)unit shortened:(BOOL)shortened localization:(Localization *)localization {
    return [self stringValueForUnit:unit shortened:shortened localization:localization format:@"%.0f"];
}

- (NSString *)stringValueForUnit:(UnitTemperatureType)unit shortened:(BOOL)shortened localization:(Localization *)localization format:(NSString *)format {
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

- (NSString *)nameForUnit:(UnitTemperatureType)unit shortened:(BOOL)shortened {
    return [self nameForUnit:unit shortened:shortened localization:[Localization defaultLocalization]];
}

- (NSString *)nameForUnit:(UnitTemperatureType)unit shortened:(BOOL)shortened format:(NSString *)format {
    return [self nameForUnit:unit shortened:shortened localization:[Localization defaultLocalization] format:format];
}

- (NSString *)nameForUnit:(UnitTemperatureType)unit shortened:(BOOL)shortened localization:(Localization *)localization {
    return [self nameForUnit:unit shortened:shortened localization:localization format:@"%.0f"];
}

- (NSString *)nameForUnit:(UnitTemperatureType)unit shortened:(BOOL)shortened localization:(Localization *)localization format:(NSString *)format {
    // convert the value to the desired unit and format this value. At the end convert it to float again.
    double convertedValue = [NSString stringWithFormat:format, [self doubleValueForUnit:unit]].floatValue;
    
    NSMutableString *unitkey = [NSMutableString stringWithString:@"units.temp"];
    
    if (shortened) {
        // differ between celsius and fahrenheit when short unit name is selected (e.g. for the display).
        switch (unit) {
            case UnitTemperatureCelsius:
                [unitkey appendString:@".celsius.short"];
                break;
            case UnitTemperatureFahrenheit:
                [unitkey appendString:@".fahrenheit.short"];
                break;
            default:
                return nil;
        }
    }
    else {
        // the don't want "degrees fahrenheit" or "degrees celsius". "degrees" are just fine for long unit name (e.g. for the TTS engine).
        [unitkey appendString:@".degree.full"];
    }
    
    return [localization stringForKey:unitkey, convertedValue];
}

@end
