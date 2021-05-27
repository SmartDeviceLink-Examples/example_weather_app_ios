//
//  ImageResources.m
//  MobileWeather
//
//  Created by Frank Elias on 5/27/21.
//  Copyright © 2021 Ford. All rights reserved.
//

#import "ImageResources.h"

@implementation ImageResources

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    return self;
}

+ (NSString *)systemImageFromAssetsImage:(NSString *) imageName {
    NSString *newImageName = imageName;
    if ([imageName isEqual:@"chancerain"]) {
        newImageName = @"cloud.drizzle";
    } else if ([imageName isEqual:@"chancesnow"]) {
        newImageName = @"cloud.snow";
    } else if ([imageName isEqual:@"clear-day"]) {
        newImageName = @"sun.max";
    } else if ([imageName isEqual:@"clear-night"]) {
        newImageName = @"moon";
    } else if ([imageName isEqual:@"cloudy"]) {
        newImageName = @"smoke";
    } else if ([imageName isEqual:@"flurries"]) {
        newImageName = @"snow";
    } else if ([imageName isEqual:@"fog"]) {
        newImageName = @"cloud.fog";
    } else if ([imageName isEqual:@"hazy"]) {
        newImageName = @"sun.haze";
    } else if ([imageName isEqual:@"partly-cloudy-day"]) {
        newImageName = @"cloud.sun";
    } else if ([imageName isEqual:@"partly-cloudy-night"]) {
        newImageName = @"cloud.moon";
    } else if ([imageName isEqual:@"partlycloudy"]) {
        newImageName = @"cloud";
    } else if ([imageName isEqual:@"partlysunny"]) {
        newImageName = @"cloud.sun";
    } else if ([imageName isEqual:@"rain"]) {
        newImageName = @"cloud.rain";
    } else if ([imageName isEqual:@"sleet"]) {
        newImageName = @"cloud.sleet";
    } else if ([imageName isEqual:@"snow"]) {
        newImageName = @"cloud.snow";
    } else if ([imageName isEqual:@"sunny"]) {
        newImageName = @"sun.max";
    } else if ([imageName isEqual:@"tstorms"]) {
        newImageName = @"cloud.bolt";
    } else if ([imageName isEqual:@"menu-alert"]) {
        newImageName = @"exclamationmark.triangle";
    } else if ([imageName isEqual:@"menu-day"]) {
        newImageName = @"calendar";
    } else if ([imageName isEqual:@"menu-time"]) {
        newImageName = @"clock";
    }
    return newImageName;
}

@end
