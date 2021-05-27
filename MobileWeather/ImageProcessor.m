//
//  ImageProcessor.m
//  MobileWeather
//
//  Copyright (c) 2013-2015 Ford Motor Company. All rights reserved.
//

#import "ImageProcessor.h"

@interface ImageProcessor ()

@end

@implementation ImageProcessor

+ (ImageProcessor *)sharedProcessor {
    static ImageProcessor *shared = nil;
    static dispatch_once_t token;
    
    dispatch_once(&token, ^{
        shared = [[ImageProcessor alloc] init];
    });
    
    return shared;
}

- (instancetype)init {
    if (self = [super init]) {
    }
    
    return self;
}

+ (UIImage *)imageByName:(NSString *) imageName {
    UIImage *imageReturned;

    if (@available(iOS 13.0, *)) {
        return imageReturned = [[UIImage systemImageNamed:[ImageProcessor systemImageFromAssetsImage:imageName]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    } else {
        return imageReturned = [[UIImage imageNamed:imageName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
}

- (UIImage *)imageFromConditionImage:(NSString *)conditionImage {
    UIImage *image;

    if (@available(iOS 13.0, *)) {
        image = [UIImage systemImageNamed:[ImageProcessor  systemImageFromAssetsImage:conditionImage]];
    } else {
        image = [UIImage imageNamed:conditionImage];
    }

    if (image == nil) {
        image = [UIImage imageNamed:@"unknown"];
    }
    
    return image;
}

- (NSData *)dataFromConditionImage:(NSString *)conditionImage {
    UIImage *image = [self imageFromConditionImage:conditionImage];
    NSData *data = UIImagePNGRepresentation(image);
    
    return data;
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
