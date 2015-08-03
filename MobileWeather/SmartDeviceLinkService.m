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
@property BOOL graphicsAvailable;
@property NSUInteger textFieldsAvailable;
@property NSUInteger softButtonsAvailable;
@property NSArray *templatesAvailable;
@end

@implementation SmartDeviceLinkService

+ (instancetype)sharedService {
    static id shared = nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{ shared = [[self alloc] init]; });
    return shared;
}

- (void)resetProperties {
    [self setGraphicsAvailable:NO];
    [self setTextFieldsAvailable:0];
    [self setSoftButtonsAvailable:0];
    [self setTemplatesAvailable:nil];
}

- (void)setupProxy {
    if ([self proxy] == nil) {
        [self resetProperties];
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
    correlation = (correlation + 1) % UINT16_MAX;
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

- (void)registerDisplayLayout:(NSString *)layout {
    if ([[self templatesAvailable] containsObject:layout]) {
        SDLSetDisplayLayout *request = [[SDLSetDisplayLayout alloc] init];
        [request setDisplayLayout:layout];
        [self sendRequest:request];
    }
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

- (void)onRegisterAppInterfaceResponse:(SDLRegisterAppInterfaceResponse *)response {
    // are graphics supported?
    [self setGraphicsAvailable:[[[response displayCapabilities] graphicSupported] boolValue]];
    
    // get the display type
    SDLDisplayType *display = [[response displayCapabilities] displayType];
    
    if ([[SDLDisplayType MFD3] isEqual:display] ||
        [[SDLDisplayType MFD4] isEqual:display] ||
        [[SDLDisplayType MFD5] isEqual:display]) {
        // MFDs can show 2 lines of text and 3 soft buttons
        [self setTextFieldsAvailable:2];
        [self setSoftButtonsAvailable:3];
    } else if ([[SDLDisplayType GEN3_8_INCH] isEqual:display]) {
        // SYNC3 can show 3 lines of text and 6 soft buttons
        [self setTextFieldsAvailable:3];
        [self setSoftButtonsAvailable:6];
    } else if ([[SDLDisplayType CID] isEqual:display]) {
        // CID can show 2 lines of text but no soft buttons
        [self setTextFieldsAvailable:2];
        [self setSoftButtonsAvailable:0];
    } else {
        // All other can show at minimum 1 line of text
        [self setTextFieldsAvailable:1];
        [self setSoftButtonsAvailable:0];
    }
    
    // get the available templates
    NSMutableArray *templates = [[response displayCapabilities] templatesAvailable];
    if ([templates isKindOfClass:[NSMutableArray class]]) {
        [self setTemplatesAvailable:templates];
    } else {
        [self setTemplatesAvailable:[NSMutableArray array]];
    }
    
    // set the app display layout to the non-media template
    [self registerDisplayLayout:@"NON-MEDIA"];
}

@end
