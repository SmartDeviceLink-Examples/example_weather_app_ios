//
//  ImageProcessor.h
//  MobileWeather
//
//  Copyright (c) 2013-2015 Ford Motor Company. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ImageProcessor : NSObject

+ (ImageProcessor *)sharedProcessor;

- (UIImage *)imageFromConditionImage:(NSString *)conditionImage;

- (NSData *)dataFromConditionImage:(NSString *)conditionImage;

@end
