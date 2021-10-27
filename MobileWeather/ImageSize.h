//
//  ImageSize.h
//  MobileWeather
//
//  Created by Frank Elias on 6/28/21.
//  Copyright © 2021 Ford. All rights reserved.
//

@import UIKit;

typedef NS_ENUM(NSUInteger, ImageSize) {
    ImageSizeLarge,
    ImageSizeSmall
};

@interface ImageSizeHelper : NSObject

+ (CGFloat)floatForImageSize:(ImageSize)imageSize;

@end
