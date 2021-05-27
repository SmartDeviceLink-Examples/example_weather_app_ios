//
//  ImageResources.h
//  MobileWeather
//
//  Created by Frank Elias on 5/27/21.
//  Copyright © 2021 Ford. All rights reserved.
//

#import <Foundation/Foundation.h>
@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@interface ImageResources : NSObject

+ (NSString *)systemImageFromAssetsImage:(NSString *) imageName;

@end

NS_ASSUME_NONNULL_END
