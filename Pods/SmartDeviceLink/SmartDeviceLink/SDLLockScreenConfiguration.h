//
//  SDLLockScreenConfiguration.h
//  SmartDeviceLink-iOS
//
//  Created by Joel Fischer on 10/13/15.
//  Copyright © 2015 smartdevicelink. All rights reserved.
//

#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

/**
 Describes when the lock screen should be shown.
 */
typedef NS_ENUM(NSUInteger, SDLLockScreenConfigurationDisplayMode) {
    /// The lock screen should never be shown. This should almost always mean that you will build your own lock screen.
    SDLLockScreenConfigurationDisplayModeNever,

    /// The lock screen should only be shown when it is required by the head unit.
    SDLLockScreenConfigurationDisplayModeRequiredOnly,

    /// The lock screen should be shown when required by the head unit or when the head unit says that its optional, but *not* in other cases, such as before the user has interacted with your app on the head unit.
    SDLLockScreenConfigurationDisplayModeOptionalOrRequired,

    /// The lock screen should always be shown after connection.
    SDLLockScreenConfigurationDisplayModeAlways
};

/**
 A configuration describing how the lock screen should be used by the internal SDL system for your application. This configuration is provided before SDL starts and will govern the entire SDL lifecycle of your application.
 */
@interface SDLLockScreenConfiguration : NSObject <NSCopying>

/**
 Describes when the lock screen will be displayed. Defaults to `SDLLockScreenConfigurationDisplayModeRequiredOnly`.
 */
@property (assign, nonatomic) SDLLockScreenConfigurationDisplayMode displayMode;

/**
 *  Whether or not the lock screen should be shown in the "lock screen optional" state. Defaults to NO.
 *
 *  In order for the "lock screen optional" state to occur, the following must be true:
 *  1. The app should have received at least 1 driver distraction notification (i.e. a `OnDriverDistraction` notification) from SDL Core. Older versions of Core did not send a notification immediately on connection.
 *  2. The driver is not distracted (i.e. the last `OnDriverDistraction` notification received was for a driver distraction state off).
 *  3. The `hmiLevel` can not be `NONE`.
 *  4. If the `hmiLevel` is currently `BACKGROUND` then the previous `hmiLevel` should have been `FULL` or `LIMITED` (i.e. the user should have interacted with app before it was backgrounded).

 *  Since this has been deprecated, setting this to true will set `displayMode` to `OptionalOrRequired` if `enableAutomaticLockScreen` is true, or will have no effect if it is false.
 */
@property (assign, nonatomic) BOOL showInOptionalState __deprecated_msg("Use displayMode SDLLockScreenConfigurationDisplayModeOptionalOrRequired to replicate this being YES");

/**
 If YES, then the lock screen can be dismissed with a downward swipe on compatible head units. Requires a connection of SDL 6.0+ and the head unit to enable the feature. Defaults to YES.
 */
@property (assign, nonatomic) BOOL enableDismissGesture;

/**
 If YES, then the lockscreen will show the vehicle's logo if the vehicle has made it available. If NO, then the lockscreen will not show the vehicle logo. Defaults to YES.
*/
@property (assign, nonatomic) BOOL showDeviceLogo;

/**
 If YES, the lock screen should be managed by SDL and automatically engage when necessary. If NO, then the lock screen will never be engaged. Defaults to YES.

 Since this has been deprecated, setting this to false will set `displayMode` to `Never`. Setting it back to true will set it to `RequiredOnly` if `showInOptionalState` is false, or `OptionalOrRequired` if it is true.
 */
@property (assign, nonatomic, readonly) BOOL enableAutomaticLockScreen __deprecated_msg("Use displayMode SDLLockScreenConfigurationDisplayModeNever to replicate this being NO");

/**
 *  The background color of the lock screen. This could be a branding color, or leave at the default for a dark blue-gray.
 */
@property (copy, nonatomic, readonly) UIColor *backgroundColor;

/**
 *  Your app icon as it will appear on the lock screen.
 */
@property (copy, nonatomic, readonly, nullable) UIImage *appIcon;

/**
 *  A custom view controller that the lock screen will manage the presentation of.
 */
@property (strong, nonatomic, readonly, nullable) UIViewController *customViewController;

/// Initializer unavailable
- (instancetype)init NS_UNAVAILABLE;

/**
 *  Use this configuration if you wish to manage a lock screen yourself. This may be useful if the automatic presentation feature of SDLLockScreenManager is failing for some reason.
 *
 *  @return The configuration
 */
+ (instancetype)disabledConfiguration;

/**
 *  Use this configuration for the basic default lock screen. A custom app icon will not be used.
 *
 *  @return The configuration
 */
+ (instancetype)enabledConfiguration;

/**
 *  Use this configuration to provide a custom lock screen icon and a custom background color, or nil if you wish to use the default background color. This will use the default lock screen layout.
 *
 *  @param lockScreenAppIcon         The app icon to be shown on the lock screen
 *  @param lockScreenBackgroundColor The color of the lock screen background
 *
 *  @return The configuration
 */
+ (instancetype)enabledConfigurationWithAppIcon:(UIImage *)lockScreenAppIcon backgroundColor:(nullable UIColor *)lockScreenBackgroundColor;

/**
 *  Use this configuration if you wish to provide your own view controller for the lock screen. This view controller's presentation and dismissal will still be managed by the lock screen manager. Note that you may subclass SDLLockScreenViewController and pass it here to continue to have the vehicle icon set to your view controller by the manager.
 *
 *  @param viewController The view controller to be managed
 *
 *  @return The configuration
 */
+ (instancetype)enabledConfigurationWithViewController:(UIViewController *)viewController;

@end

NS_ASSUME_NONNULL_END
