//
//  SDLPredefinedWindows.h
//  SmartDeviceLink

#import "SDLEnum.h"

/**
 Specifies which windows and IDs are predefined and pre-created on behalf of the app. The default window is always available and represents the app window on the main display. It's an equivalent to today's app window. For backward compatibility, this will ensure the app always has at least the default window on the main display. The app can choose to use this predefined enum element to specifically address app's main window or to duplicate window content. It is not possible to duplicate another window to the default window. The primary widget is a special widget, that can be associated with a service type, which is used by the HMI whenever a single widget needs to represent the whole app. The primary widget should be named as the app and can be pre-created by the HMI.
 
  @since SDL 6.0
 */
typedef NS_ENUM(NSUInteger, SDLPredefinedWindows){
    /// The default window is a main window pre-created on behalf of the app.
    SDLPredefinedWindowsDefaultWindow = 0,

    /// The primary widget of the app.
    SDLPredefinedWindowsPrimaryWidget = 1
};
