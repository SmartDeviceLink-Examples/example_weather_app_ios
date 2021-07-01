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

- (UIImage *)imageFromConditionImage:(NSString *)conditionImage imageSize:(ImageSize)imageSize {
    UIImage *image = [UIImage systemImageNamed:[self mw_systemImageFromAssetsImage:conditionImage] withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:[ImageSizeHelper floatForImageSize:imageSize] weight:UIImageSymbolWeightBold]];

    if (image == nil) {
        image = [UIImage imageNamed:@"unknown"];
    }
    
    return image;
}

- (NSData *)dataFromConditionImage:(NSString *)conditionImage {
    UIImage *image = [self imageFromConditionImage:conditionImage imageSize:ImageSizeSmall];
    NSData *data = UIImagePNGRepresentation(image);
    
    return data;
}

- (NSString *)mw_systemImageFromAssetsImage:(NSString *)imageName {
    NSString *newImageName = imageName;
    if ([imageName isEqualToString:@"chancerain"]) {
        newImageName = @"cloud.drizzle";
    } else if ([imageName isEqualToString:@"chancesnow"]) {
        newImageName = @"cloud.snow";
    } else if ([imageName isEqualToString:@"clear-day"]) {
        newImageName = @"sun.max";
    } else if ([imageName isEqualToString:@"clear-night"]) {
        newImageName = @"moon";
    } else if ([imageName isEqualToString:@"cloudy"]) {
        newImageName = @"smoke";
    } else if ([imageName isEqualToString:@"flurries"]) {
        newImageName = @"snow";
    } else if ([imageName isEqualToString:@"fog"]) {
        newImageName = @"cloud.fog";
    } else if ([imageName isEqualToString:@"hazy"]) {
        newImageName = @"sun.haze";
    } else if ([imageName isEqualToString:@"partly-cloudy-day"]) {
        newImageName = @"cloud.sun";
    } else if ([imageName isEqualToString:@"partly-cloudy-night"]) {
        newImageName = @"cloud.moon";
    } else if ([imageName isEqualToString:@"partlycloudy"]) {
        newImageName = @"cloud";
    } else if ([imageName isEqualToString:@"partlysunny"]) {
        newImageName = @"cloud.sun";
    } else if ([imageName isEqualToString:@"rain"]) {
        newImageName = @"cloud.rain";
    } else if ([imageName isEqualToString:@"sleet"]) {
        newImageName = @"cloud.sleet";
    } else if ([imageName isEqualToString:@"snow"]) {
        newImageName = @"cloud.snow";
    } else if ([imageName isEqualToString:@"sunny"]) {
        newImageName = @"sun.max";
    } else if ([imageName isEqualToString:@"tstorms"]) {
        newImageName = @"cloud.bolt";
    } else if ([imageName isEqualToString:@"menu-alert"]) {
        newImageName = @"exclamationmark.triangle";
    } else if ([imageName isEqualToString:@"menu-day"]) {
        newImageName = @"calendar";
    } else if ([imageName isEqualToString:@"menu-time"]) {
        newImageName = @"clock";
    }
    return newImageName;
}

@end
