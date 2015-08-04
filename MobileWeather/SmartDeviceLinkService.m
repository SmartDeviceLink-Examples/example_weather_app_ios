//
//  SmartDeviceLinkService.m
//  MobileWeather
//
//  Copyright (c) 2013-2015 Ford. All rights reserved.
//

#import "SmartDeviceLinkService.h"
#import <SmartDeviceLink.h>
#import "Localization.h"
#import "WeatherLanguage.h"
#import "WeatherDataManager.h"

#define CMDID_SHOW_WEATHER_CONDITIONS 101

@interface SmartDeviceLinkService () <SDLProxyListener>
@property SDLProxy *proxy;
@property BOOL graphicsAvailable;
@property NSUInteger textFieldsAvailable;
@property NSUInteger softButtonsAvailable;
@property NSArray *templatesAvailable;
@property SDLLanguage *language;
@property Localization *localization;
@property BOOL isFirstTimeHmiFull;
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
    [self setLanguage:nil];
    [self setLocalization:nil];
    [self setIsFirstTimeHmiFull:NO];
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
    [request setTtsName:[SDLTTSChunkFactory buildTTSChunksFromSimple:NSLocalizedString(@"app.tts-name", nil)]];
    [request setVrSynonyms:[NSMutableArray arrayWithObject:NSLocalizedString(@"app.vr-synonym", nil)]];
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

- (void)changeRegistration {
    if ([self language] != nil && [self localization] != nil) {
        SDLChangeRegistration *request = [[SDLChangeRegistration alloc] init];
        [request setLanguage:[self language]];
        [request setHmiDisplayLanguage:[self language]];
        [self sendRequest:request];
    }
}

- (void)sendWelcomeMessageWithSpeak:(BOOL)withSpeak {
    SDLShow *show = [[SDLShow alloc] init];
    [show setMainField1:[[self localization] stringForKey:@"show.welcome.field1"]];
    [show setMainField2:[[self localization] stringForKey:@"show.welcome.field2"]];
    [show setMainField3:[[self localization] stringForKey:@"show.welcome.field3"]];
    [show setMainField4:[[self localization] stringForKey:@"show.welcome.field4"]];
    [show setAlignment:[SDLTextAlignment CENTERED]];
    [self sendRequest:show];
    
    if (withSpeak) {
        SDLSpeak *speak = [[SDLSpeak alloc] init];
        [speak setTtsChunks:[SDLTTSChunkFactory buildTTSChunksFromSimple:[[self localization] stringForKey:@"speak.welcome"]]];
        [self sendRequest:speak];
    }
}

- (void)sendWeatherConditions:(WeatherConditions *)conditions withSpeak:(BOOL)withSpeak {
    if (conditions != nil) {
        // use these types for unit conversion
        UnitPercentageType percentageType = UnitPercentageDefault;
        UnitTemperatureType temperatureType = UnitTemperatureCelsius;
        UnitSpeedType speedType = UnitSpeedMeterSecond;
        
        if ([[WeatherDataManager sharedManager] unit] == UnitTypeMetric) {
            temperatureType = UnitTemperatureCelsius;
            speedType = UnitSpeedKiloMeterHour;
        } else if ([[WeatherDataManager sharedManager] unit] == UnitTypeImperial) {
            temperatureType = UnitTemperatureFahrenheit;
            speedType = UnitSpeedMileHour;
        }
        SDLShow *showRequest = [[SDLShow alloc] init];
        [showRequest setMainField1:[conditions conditionTitle]];
        [showRequest setMainField2:@""];
        [showRequest setMainField3:@""];
        [showRequest setMainField4:@""];
        
        if ([self textFieldsAvailable] >= 2) {
            NSString *weathercondition = [[self localization] stringForKey:@"conditions.show",
                [[conditions temperature] stringValueForUnit:temperatureType shortened:YES localization:[self localization]],
                [[conditions humidity] stringValueForUnit:percentageType shortened:YES localization:[self localization]],
                [[conditions windSpeed] stringValueForUnit:speedType shortened:YES localization:[self localization]]];
            
            [showRequest setMainField2:weathercondition];
        }
        [self sendRequest:showRequest];
        
        if (withSpeak) {
            SDLSpeak *speakRequest = [[SDLSpeak alloc] init];
            SDLTTSChunk *chunk = [[SDLTTSChunk alloc] init];
            [chunk setType:[SDLSpeechCapabilities TEXT]];
            [chunk setText:[[self localization] stringForKey:@"conditions.speak",
                [conditions conditionTitle],
                [[conditions temperature] stringValueForUnit:temperatureType shortened:NO localization:[self localization]],
                [[conditions humidity] stringValueForUnit:percentageType shortened:NO localization:[self localization]],
                [[conditions windSpeed] stringValueForUnit:speedType shortened:NO localization:[self localization]]]];
        
            [speakRequest setTtsChunks:[NSMutableArray arrayWithObject:chunk]];
            [self sendRequest:speakRequest];
        }
    }
    else {
        SDLAlert *alertRequest = [[SDLAlert alloc] init];
        [alertRequest setAlertText1:[[self localization] stringForKey:@"alert.no-conditions.field1"]];
        [alertRequest setAlertText2:[[self localization] stringForKey:@"alert.no-conditions.field2"]];
        [alertRequest setTtsChunks:[SDLTTSChunkFactory buildTTSChunksFromSimple:[[self localization] stringForKey:@"alert.no-conditions.prompt"]]];
        [self sendRequest:alertRequest];
    }
}

- (void)sendWeatherVoiceCommands {
    SDLAddCommand *request = nil;
    SDLMenuParams *menuparams = nil;
    
    menuparams = [[SDLMenuParams alloc] init];
    [menuparams setMenuName:[[self localization] stringForKey:@"cmd.current-conditions"]];
    [menuparams setPosition:@(1)];
    request = [[SDLAddCommand alloc] init];
    [request setMenuParams:menuparams];
    [request setCmdID:@(CMDID_SHOW_WEATHER_CONDITIONS)];
    [request setVrCommands:[NSMutableArray arrayWithObjects:
        [[self localization] stringForKey:@"vr.current"],
        [[self localization] stringForKey:@"vr.conditions"],
        [[self localization] stringForKey:@"vr.current-conditions"],
        [[self localization] stringForKey:@"vr.show-conditions"],
        [[self localization] stringForKey:@"vr.show-current-conditions"],
        nil]];
    [self sendRequest:request];
}

- (void)onOnHMIStatus:(SDLOnHMIStatus *)notification {
    SDLHMILevel *hmiLevel = [notification hmiLevel];
    // check current HMI level of the app
    if ([[SDLHMILevel FULL] isEqual:hmiLevel]) {
        if ([self isFirstTimeHmiFull] == NO) {
            [self setIsFirstTimeHmiFull:YES];
            // the app is just started by the user. Send everything needed to be done once
            [self sendWelcomeMessageWithSpeak:YES];
            [self sendWeatherVoiceCommands];
        }
    }
}

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

- (void)onOnCommand:(SDLOnCommand *)notification {
    WeatherDataManager *manager = [WeatherDataManager sharedManager];
    NSInteger command = [[notification cmdID] integerValue];
    switch (command) {
        case CMDID_SHOW_WEATHER_CONDITIONS: {
            // the user has performed the voice command to see the current conditions.
            [self sendWeatherConditions:[manager weatherConditions] withSpeak:YES];
            break;
        }
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
    
    [self setLanguage:[response language]];
    
    NSString *language = [[[response language] value] substringToIndex:2];
    NSString *region = [[[response language] value] substringFromIndex:3];
    [self setLocalization:[Localization localizationForLanguage:language forRegion:region]];
    
    // inform the app about language change to get new weather data
    WeatherLanguage *wlanguage = [WeatherLanguage elementWithValue:[language uppercaseString]];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:MobileWeatherLanguageUpdateNotification object:self userInfo:@{ @"language" : wlanguage }];
    
    // send a change registration
    [self changeRegistration];
    
    // print out the app name for the language
    NSLog(@"%@", [[self localization] stringForKey:@"app.name"]);
}

@end
