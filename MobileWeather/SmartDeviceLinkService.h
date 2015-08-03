//
//  SmartDeviceLinkService.h
//  MobileWeather
//
//  Copyright (c) 2013-2015 Ford. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SmartDeviceLinkService : NSObject
+ (instancetype)sharedService;
- (void)start;
- (void)stop;
@end
