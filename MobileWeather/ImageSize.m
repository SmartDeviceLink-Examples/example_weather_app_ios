//
//  ImageSize.m
//  MobileWeather
//
//  Created by Frank Elias on 6/28/21.
//  Copyright © 2021 Ford. All rights reserved.
//

#import "ImageSize.h"

@implementation ImageSizeHelper

+ (CGFloat)floatForImageSize:(ImageSize)imageSize {
    if (imageSize == ImageSizeLarge) {
        return 256;
    } else {
        return 64;
    }
}

@end
