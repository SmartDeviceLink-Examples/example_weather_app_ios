//
//  NSBundle+Language.m
//  MobileWeather
//
//  Copyright (c) 2013-2015 Ford Motor Company. All rights reserved.
//

#import "NSBundle+Language.h"

@implementation NSBundle (Language)

- (NSString *)localizedStringForKey:(NSString *)key {
    return [self localizedStringForKey:key value:@"" table:nil];
}

@end
