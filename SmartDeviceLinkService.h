//
//  SmartDeviceLinkService.h
//  MobileWeather
//
//  Copyright (c) 2013-2015 Ford. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NSString* MWInfoType;

extern MWInfoType const MWInfoTypeNone;
extern MWInfoType const MWInfoTypeWeatherConditions;
extern MWInfoType const MWInfoTypeDailyForecast;
extern MWInfoType const MWInfoTypeHourlyForecast;
extern MWInfoType const MWInfoTypeAlerts;

@interface SmartDeviceLinkService : NSObject
+ (instancetype)sharedService;
- (void)start;
- (void)stop;
@end
