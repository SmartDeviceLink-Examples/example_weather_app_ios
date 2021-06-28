//
//  ImageProcessor.h
//  MobileWeather
//
//  Copyright (c) 2013-2015 Ford Motor Company. All rights reserved.
//

@import UIKit;
#include "ImageSize.h"

@interface ImageProcessor : NSObject

+ (ImageProcessor *)sharedProcessor;

- (UIImage *)imageFromConditionImage:(NSString *)conditionImage imageSize:(ImageSize)imageSize;

- (NSData *)dataFromConditionImage:(NSString *)conditionImage;

@end
