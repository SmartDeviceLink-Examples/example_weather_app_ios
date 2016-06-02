//
//  Notifications.h
//  MobileWeather
//
//  Copyright (c) 2013-2015 Ford Motor Company. All rights reserved.
//

#import <Foundation/Foundation.h>

/** A notification that informs observing receivers about significant location updates. */
NSString * const MobileWeatherLocationUpdateNotification;

/** A notification taht informs observing receivers that the language settings have been changed. */
NSString * const MobileWeatherLanguageUpdateNotification;

/** A notification that informs observiing receivers about significant time updates. */
NSString * const MobileWeatherTimeUpdateNotification;

/** A notificaiton that informs observing receivers that weather data has been updated. */
NSString * const MobileWeatherDataUpdatedNotification;

/** A notification used from the single instance of the weather service. */
NSString * const MobileWeatherServiceLoadedNotification;

/** A notification used to inform that the unit has been changed. */
NSString * const MobileWeatherUnitChangedNotification;

NSString * const SDLRequestsLockScreenNotification;
NSString * const SDLRequestsUnlockScreenNotification;