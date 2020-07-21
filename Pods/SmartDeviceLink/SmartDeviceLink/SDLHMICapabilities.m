//
//  SDLHMICapabilities.m
//  SmartDeviceLink-iOS

#import "SDLHMICapabilities.h"

#import "NSMutableDictionary+Store.h"
#import "SDLRPCParameterNames.h"

NS_ASSUME_NONNULL_BEGIN

@implementation SDLHMICapabilities

- (void)setNavigation:(nullable NSNumber<SDLBool> *)navigation {
    [self.store sdl_setObject:navigation forName:SDLRPCParameterNameNavigation];
}

- (nullable NSNumber<SDLBool> *)navigation {
    return [self.store sdl_objectForName:SDLRPCParameterNameNavigation ofClass:NSNumber.class error:nil];
}

- (void)setPhoneCall:(nullable NSNumber<SDLBool> *)phoneCall {
    [self.store sdl_setObject:phoneCall forName:SDLRPCParameterNamePhoneCall];
}

- (nullable NSNumber<SDLBool> *)phoneCall {
    return [self.store sdl_objectForName:SDLRPCParameterNamePhoneCall ofClass:NSNumber.class error:nil];
}

- (void)setVideoStreaming:(nullable NSNumber<SDLBool> *)videoStreaming {
    [self.store sdl_setObject:videoStreaming forName:SDLRPCParameterNameVideoStreaming];
}

- (nullable NSNumber<SDLBool> *)videoStreaming {
    return [self.store sdl_objectForName:SDLRPCParameterNameVideoStreaming ofClass:NSNumber.class error:nil];
}

- (void)setRemoteControl:(nullable NSNumber<SDLBool> *)remoteControl {
    [self.store sdl_setObject:remoteControl forName:SDLRPCParameterNameRemoteControl];
}

- (nullable NSNumber<SDLBool> *)remoteControl {
    return [self.store sdl_objectForName:SDLRPCParameterNameRemoteControl ofClass:NSNumber.class error:nil];
}

- (void)setAppServices:(nullable NSNumber<SDLBool> *)appServices {
    [self.store sdl_setObject:appServices forName:SDLRPCParameterNameAppServices];
}

- (nullable NSNumber<SDLBool> *)appServices {
    return [self.store sdl_objectForName:SDLRPCParameterNameAppServices ofClass:NSNumber.class error:nil];
}

- (void)setDisplays:(nullable NSNumber<SDLBool> *)displays {
    [self.store sdl_setObject:displays forName:SDLRPCParameterNameDisplays];
}

- (nullable NSNumber<SDLBool> *)displays {
    return [self.store sdl_objectForName:SDLRPCParameterNameDisplays ofClass:NSNumber.class error:nil];
}

- (void)setSeatLocation:(nullable NSNumber<SDLBool> *)seatLocation {
    [self.store sdl_setObject:seatLocation forName:SDLRPCParameterNameSeatLocation];
}

- (nullable NSNumber<SDLBool> *)seatLocation {
    return [self.store sdl_objectForName:SDLRPCParameterNameSeatLocation ofClass:NSNumber.class error:nil];
}

@end

NS_ASSUME_NONNULL_END
