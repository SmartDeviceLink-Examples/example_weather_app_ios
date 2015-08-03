//
//  SmartDeviceLinkService.m
//  MobileWeather
//
//  Copyright (c) 2013-2015 Ford. All rights reserved.
//

#import "SmartDeviceLinkService.h"
#import <SmartDeviceLink.h>

@interface SmartDeviceLinkService () <SDLProxyListener>
@property SDLProxy *proxy;
@end

@implementation SmartDeviceLinkService

+ (instancetype)sharedService {
    static id shared = nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{ shared = [[self alloc] init]; });
    return shared;
}

- (void)setupProxy {
    if ([self proxy] == nil) {
        // Create a proxy object by simply using the factory class.
        [self setProxy:[SDLProxyFactory buildSDLProxyWithListener:self]];
    }
}

- (void)teardownProxy {
    if ([self proxy] != nil) {
        [[self proxy] dispose];
        [self setProxy:nil];
    }
}

- (NSNumber *)nextCorrelationID {
    static UInt32 correlation = 0;
    correlation = (correlation + 1) % UINT32_MAX;
    return @(correlation);
}

- (void)sendRequest:(SDLRPCRequest *)request {
    if ([request correlationID] == nil) {
        [request setCorrelationID:[self nextCorrelationID]];
    }
    
    [[self proxy] sendRPC:request];
}

- (void)dealloc {
    [self teardownProxy];
}

- (void)start {
    [self setupProxy];
}

- (void)stop {
    [self teardownProxy];
}

- (void)onProxyClosed {
    [self teardownProxy];
    [self setupProxy];
}

- (void)onProxyOpened {
    [self registerApplicationInterface];
}

- (void)registerApplicationInterface {
    SDLRegisterAppInterface *request = [[SDLRegisterAppInterface alloc] init];
    [request setAppName:@"MobileWeather"];
    [request setAppID:@"330533107"];
    [request setIsMediaApplication:@(NO)];
    [request setLanguageDesired:[SDLLanguage EN_US]];
    [request setHmiDisplayLanguageDesired:[SDLLanguage EN_US]];
    SDLSyncMsgVersion *version = [[SDLSyncMsgVersion alloc] init];
    [version setMajorVersion:@(1)];
    [version setMinorVersion:@(0)];
    [request setSyncMsgVersion:version];
    
    [self sendRequest:request];
}

- (void)onOnHMIStatus:(SDLOnHMIStatus *)notification {}
- (void)onOnDriverDistraction:(SDLOnDriverDistraction *)notification {}

- (void)onOnLockScreenNotification:(SDLOnLockScreenStatus *)notification {
    SDLLockScreenStatus *status = [notification lockScreenStatus];
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    
    // REQUIRED: The app must now show a lock screen.
    // OPTIONAL: The app can now optionally show a lock screen.
    // OFF: The app must not have a lock screen anymore.
    
    if ([[SDLLockScreenStatus REQUIRED] isEqual:status]) {
        [center postNotificationName:SDLRequestsLockScreenNotification object:self];
    } else if ([[SDLLockScreenStatus OPTIONAL] isEqual:status]) {
        [center postNotificationName:SDLRequestsUnlockScreenNotification object:self];
    } else {
        [center postNotificationName:SDLRequestsUnlockScreenNotification object:self];
    }
}

@end
