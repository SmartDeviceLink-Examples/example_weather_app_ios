//
//  SmartDeviceLinkService.h
//  MobileWeather
//
//  Created by Ryan Conroy on 5/24/16.
//  Copyright © 2016 Ford. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SmartDeviceLinkService : NSObject

+ (instancetype)sharedService;

- (void)start;
- (void)stop;

@end
