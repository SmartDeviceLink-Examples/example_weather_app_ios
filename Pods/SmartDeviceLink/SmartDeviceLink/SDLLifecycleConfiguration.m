//
//  SDLManagerConfiguration.m
//  SmartDeviceLink-iOS
//
//  Created by Joel Fischer on 10/7/15.
//  Copyright © 2015 smartdevicelink. All rights reserved.
//

#import "SDLLifecycleConfiguration.h"

#import "SDLFile.h"
#import "SDLVersion.h"

static NSString *const DefaultTCPIPAddress = @"192.168.0.1";
static UInt16 const DefaultTCPIPPort = 12345;


NS_ASSUME_NONNULL_BEGIN

@interface SDLLifecycleConfiguration ()

@property (assign, nonatomic, readwrite) BOOL tcpDebugMode;
@property (copy, nonatomic, readwrite, null_resettable) NSString *tcpDebugIPAddress;
@property (assign, nonatomic, readwrite) UInt16 tcpDebugPort;

@end

static NSUInteger const AppIdCharacterCount = 10;

@implementation SDLLifecycleConfiguration

#pragma mark Lifecycle

+ (SDLLifecycleConfiguration *)defaultConfigurationWithAppName:(NSString *)appName appId:(NSString *)appId {
    return [[self alloc] initDefaultConfigurationWithAppName:appName fullAppId:nil appId:appId];
}

+ (SDLLifecycleConfiguration *)defaultConfigurationWithAppName:(NSString *)appName fullAppId:(NSString *)fullAppId {
    return [[self alloc] initDefaultConfigurationWithAppName:appName fullAppId:fullAppId appId:fullAppId];
}

+ (SDLLifecycleConfiguration *)debugConfigurationWithAppName:(NSString *)appName appId:(NSString *)appId ipAddress:(NSString *)ipAddress port:(UInt16)port {
    return [[self alloc] initDefaultConfigurationWithAppName:appName fullAppId:nil appId:appId ipAddress:ipAddress port:port];
}

+ (SDLLifecycleConfiguration *)debugConfigurationWithAppName:(NSString *)appName fullAppId:(NSString *)fullAppId ipAddress:(NSString *)ipAddress port:(UInt16)port {
    return [[self alloc] initDefaultConfigurationWithAppName:appName fullAppId:fullAppId appId:fullAppId ipAddress:ipAddress port:port];
}

#pragma mark Initalization Helpers

- (instancetype)initDefaultConfigurationWithAppName:(NSString *)appName fullAppId:(nullable NSString *)fullAppId appId:(NSString *)appId  {
    self = [super init];
    if (!self) {
        return nil;
    }

    _tcpDebugMode = NO;
    _tcpDebugIPAddress = DefaultTCPIPAddress;
    _tcpDebugPort = DefaultTCPIPPort;

    _appName = appName;
    _appType = SDLAppHMITypeDefault;
    _language = SDLLanguageEnUs;
    _languagesSupported = @[_language];
    _appIcon = nil;
    _shortAppName = nil;
    _ttsName = nil;
    _voiceRecognitionCommandNames = nil;
    _minimumProtocolVersion = [SDLVersion versionWithString:@"1.0.0"];
    _minimumRPCVersion = [SDLVersion versionWithString:@"1.0.0"];
    _allowedSecondaryTransports = SDLSecondaryTransportsTCP;

    _fullAppId = fullAppId;
    _appId = fullAppId != nil ? [self.class sdlex_shortAppIdFromFullAppId:fullAppId] : appId;

    return self;
}

- (instancetype)initDefaultConfigurationWithAppName:(NSString *)appName fullAppId:(nullable NSString *)fullAppId appId:(nullable NSString *)appId ipAddress:(NSString *)ipAddress port:(UInt16)port {
    SDLLifecycleConfiguration *config = [self initDefaultConfigurationWithAppName:appName fullAppId:fullAppId appId:appId];

    config.tcpDebugMode = YES;
    config.tcpDebugIPAddress = ipAddress;
    config.tcpDebugPort = port;

    return config;
}

#pragma mark - Computed Properties

- (BOOL)isMedia {
    if ([self.appType isEqualToEnum:SDLAppHMITypeMedia] || [self.additionalAppTypes containsObject:SDLAppHMITypeMedia]) {
        return YES;
    }

    return NO;
}

- (void)setTcpDebugIPAddress:(nullable NSString *)tcpDebugIPAddress {
    if (tcpDebugIPAddress == nil) {
        _tcpDebugIPAddress = DefaultTCPIPAddress;
    } else {
        _tcpDebugIPAddress = tcpDebugIPAddress;
    }
}

- (void)setAppType:(nullable SDLAppHMIType)appType {
    if (appType == nil) {
        _appType = SDLAppHMITypeDefault;
        return;
    }

    _appType = appType;
}

#pragma mark - Full App ID Helpers

/**
 *  Generates the `appId` from the `fullAppId`
 *
 *  @discussion When an app is registered with an OEM, it is assigned an `appID` and a `fullAppID`. The `fullAppID` is the full UUID appID. The `appID` is the first 10 non-dash (i.e. "-") characters of the  `fullAppID`.
 *
 *  @param fullAppId   A `fullAppId`
 *  @return            An `appID` made of the first 10 non-dash characters of the "fullAppID"
 */
+ (NSString *)sdlex_shortAppIdFromFullAppId:(NSString *)fullAppId {
    NSString *filteredString = [self sdlex_filterDashesFromText:fullAppId];
    return [filteredString substringToIndex:MIN(AppIdCharacterCount, filteredString.length)];
}

/**
 *  Filters the dash characters from a string
 *
 *  @param text    The string
 *  @return        The string with all dash characters removed
 */
+ (NSString *)sdlex_filterDashesFromText:(NSString *)text {
    NSCharacterSet *supportedCharacters = [NSCharacterSet characterSetWithCharactersInString:@"-"];
    return [[text componentsSeparatedByCharactersInSet:supportedCharacters] componentsJoinedByString:@""];
}

#pragma mark - NSCopying

- (id)copyWithZone:(nullable NSZone *)zone {
    SDLLifecycleConfiguration *newConfig = [[self.class allocWithZone:zone] initDefaultConfigurationWithAppName:_appName fullAppId:_fullAppId appId:_appId];
    newConfig->_tcpDebugMode = _tcpDebugMode;
    newConfig->_tcpDebugIPAddress = _tcpDebugIPAddress;
    newConfig->_tcpDebugPort = _tcpDebugPort;
    newConfig->_appType = _appType;
    newConfig->_additionalAppTypes = _additionalAppTypes;
    newConfig->_language = _language;
    newConfig->_languagesSupported = _languagesSupported;
    newConfig->_appIcon = _appIcon;
    newConfig->_shortAppName = _shortAppName;
    newConfig->_ttsName = _ttsName;
    newConfig->_voiceRecognitionCommandNames = _voiceRecognitionCommandNames;
    newConfig->_dayColorScheme = _dayColorScheme;
    newConfig->_nightColorScheme = _nightColorScheme;
    newConfig->_allowedSecondaryTransports = _allowedSecondaryTransports;

    return newConfig;
}

@end

NS_ASSUME_NONNULL_END
