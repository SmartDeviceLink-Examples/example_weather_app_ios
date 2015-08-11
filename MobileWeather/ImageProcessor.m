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

- (UIImage *)imageFromConditionImage:(NSString *)conditionImage {
    UIImage *image = [UIImage imageNamed:conditionImage];
    
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

@end
