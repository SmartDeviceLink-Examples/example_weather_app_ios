//
//  Notifications.h
//  MobileWeather
//
//  Copyright (c) 2013-2015 Ford Motor Company. All rights reserved.
//

#import <Foundation/Foundation.h>

/** A notification that informs observing receivers about significant location updates. */
extern NSString * const MobileWeatherLocationUpdateNotification;

/** A notification taht informs observing receivers that the language settings have been changed. */
extern NSString * const MobileWeatherLanguageUpdateNotification;

/** A notification that informs observiing receivers about significant time updates. */
extern NSString * const MobileWeatherTimeUpdateNotification;

/** A notificaiton that informs observing receivers that weather data has been updated. */
extern NSString * const MobileWeatherDataUpdatedNotification;

/** A notification used from the single instance of the weather service. */
extern NSString * const MobileWeatherServiceLoadedNotification;

/** A notification used to inform that the unit has been changed. */
extern NSString * const MobileWeatherUnitChangedNotification;
