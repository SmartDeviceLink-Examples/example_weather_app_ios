//
//  ImageProcessor.h
//  MobileWeather
//
//  Copyright (c) 2013-2015 Ford Motor Company. All rights reserved.
//

@import UIKit;
@import SmartDeviceLink;
#include "ImageSize.h"

@interface ImageProcessor : NSObject

+ (ImageProcessor *)sharedProcessor;

- (UIImage *)imageFromConditionImage:(NSString *)conditionImage imageSize:(ImageSize)imageSize;

- (SDLArtwork *)artworkFromConditionImage:(NSString *)conditionImage imageSize:(ImageSize)imageSize isPersistent:(BOOL)isPersistent;

- (NSData *)dataFromConditionImage:(NSString *)conditionImage;

@end
