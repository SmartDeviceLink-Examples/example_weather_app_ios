//
//  ImageProcessor.h
//  MobileWeather
//
//  Copyright (c) 2013-2015 Ford Motor Company. All rights reserved.
//

@import UIKit;

@interface ImageProcessor : NSObject

+ (ImageProcessor *)sharedProcessor;

- (UIImage *)imageByName:(NSString *) imageName;

- (UIImage *)imageFromConditionImage:(NSString *)conditionImage;

- (NSData *)dataFromConditionImage:(NSString *)conditionImage;

@end
