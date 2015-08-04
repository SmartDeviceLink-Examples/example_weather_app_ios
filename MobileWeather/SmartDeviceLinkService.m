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
#define CMDID_CHANGE_UNITS            105
#define BTNID_SHOW_WEATHER_CONDITIONS 201
#define CHOICESET_CHANGE_UNITS        300
#define CHOICE_UNIT_METRIC            301
#define CHOICE_UNIT_IMPERIAL          302

@interface SmartDeviceLinkService () <SDLProxyListener>
@property SDLProxy *proxy;
@property BOOL graphicsAvailable;
@property NSUInteger textFieldsAvailable;
@property NSUInteger softButtonsAvailable;
@property NSArray *templatesAvailable;
@property SDLLanguage *language;
@property Localization *localization;
@property BOOL isFirstTimeHmiFull;
@property NSMutableSet *currentKnownAlerts;
@property SDLHMILevel *currentHMILevel;
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
    [self setCurrentKnownAlerts:[NSMutableSet set]];
    [self setCurrentHMILevel:nil];
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
    [[NSNotificationCenter defaultCenter]
     removeObserver:self
               name:MobileWeatherDataUpdatedNotification
             object:nil];
    
    [self teardownProxy];
    [self setupProxy];
}

- (void)onProxyOpened {
    [[NSNotificationCenter defaultCenter]
     addObserver:self
        selector:@selector(handleWeatherDataUpdate:)
            name:MobileWeatherDataUpdatedNotification
          object:nil];
    
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

- (void)handleWeatherDataUpdate:(NSNotification *)notification {
    // move forward only if HMI level is not NONE
    SDLHMILevel *hmiLevel = [self currentHMILevel];
    if ([[SDLHMILevel NONE] isEqual:hmiLevel]) {
        return;
    }
    
    // get alerts and move forward if the array is not empty
    NSArray *alerts = [[notification userInfo] objectForKey:@"alerts"];
    if (alerts == nil && [alerts count] == 0) {
        return;
    }
    
    // get copies of mutable sets for known and unknown weather alerts
    NSMutableSet *known = [NSMutableSet setWithSet:[self currentKnownAlerts]];
    NSMutableSet *unknown = [NSMutableSet setWithArray:alerts];
    // remove all alerts already known
    [unknown minusSet:known];
    // move forward only if we have unknown weather alerts
    if ([unknown count] == 0) {
        return;
    }
    
    NSDateFormatter *formatterShow = [[NSDateFormatter alloc] init];
    [formatterShow setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    [formatterShow setLocale:[[self localization] locale]];
    [formatterShow setDateFormat:[[self localization] stringForKey:@"weather-alerts.format.date-time.show"]];
    
    NSDateFormatter *formatterSpeak = [[NSDateFormatter alloc] init];
    [formatterSpeak setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    [formatterSpeak setLocale:[[self localization] locale]];
    [formatterSpeak setDateFormat:[[self localization] stringForKey:@"weather-alerts.format.date-time.speak"]];
    
    NSSortDescriptor *sorter = [NSSortDescriptor
                                sortDescriptorWithKey:@"dateExpires"
                                ascending:NO];
    NSArray *unknownSorted = [unknown sortedArrayUsingDescriptors:@[sorter]];
    // get the latest alert and show this one
    Alert *alert = [unknownSorted lastObject];
    
    NSString *chunk = [[self localization] stringForKey:@"weather-alerts.speak",
                       [alert alertTitle], [formatterSpeak stringFromDate:[alert dateExpires]]];
    NSMutableArray *chunks = [SDLTTSChunkFactory buildTTSChunksFromSimple:chunk];
    
    // create an alert request
    SDLAlert *request = [[SDLAlert alloc] init];
    [request setAlertText1:[alert alertTitle]];
    [request setAlertText2:[formatterShow stringFromDate:[alert dateExpires]]];
    [request setTtsChunks:chunks];
    
    [self sendRequest:request];
    [[self currentKnownAlerts] addObject:alert];
}

- (void)createChangeUnitsInteractionChoiceSet {
    SDLCreateInteractionChoiceSet *request = [[SDLCreateInteractionChoiceSet alloc] init];
    NSMutableArray *choiceset = [NSMutableArray arrayWithCapacity:2];
    SDLChoice *choice;
    
    choice = [[SDLChoice alloc] init];
    [choice setChoiceID:@(CHOICE_UNIT_METRIC)];
    [choice setMenuName:[[self localization] stringForKey:@"choice.units.metric"]];
    [choice setVrCommands:[NSMutableArray arrayWithObjects:
                           [[self localization] stringForKey:@"vr.metric"],
                           nil]];
    [choiceset addObject:choice];
    
    choice = [[SDLChoice alloc] init];
    [choice setChoiceID:@(CHOICE_UNIT_IMPERIAL)];
    [choice setMenuName:[[self localization] stringForKey:@"choice.units.imperial"]];
    [choice setVrCommands:[NSMutableArray arrayWithObjects:
                           [[self localization] stringForKey:@"vr.imperial"],
                           nil]];
    [choiceset addObject:choice];
    
    [request setChoiceSet:choiceset];
    [request setInteractionChoiceSetID:@(CHOICESET_CHANGE_UNITS)];
    
    [self sendRequest:request];
}

- (void)performChangeUnitsInteractionWithMode:(SDLInteractionMode *)mode {
    SDLPerformInteraction *request = [[SDLPerformInteraction alloc] init];
    [request setInitialText:[[self localization] stringForKey:@"pi.units.text"]];
    [request setInitialPrompt:[SDLTTSChunkFactory buildTTSChunksFromSimple:[[self localization] stringForKey:@"pi.units.initial-prompt"]]];
    [request setHelpPrompt:[SDLTTSChunkFactory buildTTSChunksFromSimple:[[self localization] stringForKey:@"pi.units.help-prompt"]]];
    [request setTimeoutPrompt:[SDLTTSChunkFactory buildTTSChunksFromSimple:[[self localization] stringForKey:@"pi.units.timeout-prompt"]]];
    [request setInteractionChoiceSetIDList:[NSMutableArray arrayWithObject:@(CHOICESET_CHANGE_UNITS)]];
    [request setInteractionMode:(mode ? mode : [SDLInteractionMode BOTH])];
    [request setInteractionLayout:[SDLLayoutMode LIST_ONLY]];
    [request setTimeout:@(60000)];
    
    [self sendRequest:request];
}

- (void)sendWelcomeMessageWithSpeak:(BOOL)withSpeak {
    SDLShow *show = [[SDLShow alloc] init];
    [show setSoftButtons:[self buildDefaultSoftButtons]];
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
        [showRequest setSoftButtons:[self buildDefaultSoftButtons]];
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

- (void)repeatWeatherInformation {
    WeatherDataManager *manager = [WeatherDataManager sharedManager];
    // later in this tutorial we will add forecasts etc.
    [self sendWeatherConditions:[manager weatherConditions] withSpeak:YES];
}

- (void)subscribeRepeatButton {
    SDLSubscribeButton *request = [[SDLSubscribeButton alloc] init];
    [request setButtonName:[SDLButtonName PRESET_1]];
    [self sendRequest:request];
}


- (NSMutableArray *)buildDefaultSoftButtons {
    NSMutableArray *buttons = nil;
    
    if ([self softButtonsAvailable] > 0) {
        buttons = [NSMutableArray array];
        
        SDLSoftButton * button = [[SDLSoftButton alloc] init];
        [button setSoftButtonID:@(BTNID_SHOW_WEATHER_CONDITIONS)];
        [button setText:[[self localization] stringForKey:@"sb.current"]];
        [button setType:[SDLSoftButtonType TEXT]];
        [button setSystemAction:[SDLSystemAction DEFAULT_ACTION]];
        [buttons addObject:button];
    }
    
    return buttons;
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

- (void)sendChangeUnitsVoiceCommand {
    SDLAddCommand *request = nil;
    SDLMenuParams *menuparams = nil;
    
    menuparams = [[SDLMenuParams alloc] init];
    [menuparams setMenuName:[[self localization] stringForKey:@"cmd.change-units"]];
    [menuparams setPosition:@(5)];
    request = [[SDLAddCommand alloc] init];
    [request setMenuParams:menuparams];
    [request setCmdID:@(CMDID_CHANGE_UNITS)];
    [request setVrCommands:[NSMutableArray arrayWithObjects:
                            [[self localization] stringForKey:@"vr.units"],
                            [[self localization] stringForKey:@"vr.change-units"],
                            nil]];
    [self sendRequest:request]; 
}

- (void)sendDefaultGlobalProperties {
    SDLSetGlobalProperties *request = [[SDLSetGlobalProperties alloc] init];
    NSMutableArray *prompts = [NSMutableArray array];
    NSMutableArray *helpitems = [NSMutableArray array];
    SDLVRHelpItem *helpitem;
    
    helpitem = [[SDLVRHelpItem alloc] init];
    [helpitem setPosition:@(1)];
    [helpitem setText:[[self localization] stringForKey:@"cmd.current-conditions"]];
    [helpitems addObject:helpitem];
    [prompts addObject:[[self localization] stringForKey:@"vr.show-current-conditions"]];
    
    helpitem = [[SDLVRHelpItem alloc] init];
    [helpitem setPosition:@(2)];
    [helpitem setText:[[self localization] stringForKey:@"cmd.change-units"]];
    [helpitems addObject:helpitem];
    [prompts addObject:[[self localization] stringForKey:@"vr.change-units"]];
    
    NSString *promptstring = [prompts componentsJoinedByString:@","];
    
    [request setHelpPrompt:[SDLTTSChunkFactory buildTTSChunksFromSimple:promptstring]];
    [request setTimeoutPrompt:[SDLTTSChunkFactory buildTTSChunksFromSimple:promptstring]];
    [request setVrHelpTitle:[[self localization] stringForKey:@"app.name"]];
    [request setVrHelp:helpitems];
    
    [self sendRequest:request];
}

- (void)onOnHMIStatus:(SDLOnHMIStatus *)notification {
    [self setCurrentHMILevel:[notification hmiLevel]];
    
    SDLHMILevel *hmiLevel = [notification hmiLevel];
    // check current HMI level of the app
    if ([[SDLHMILevel FULL] isEqual:hmiLevel]) {
        if ([self isFirstTimeHmiFull] == NO) {
            [self setIsFirstTimeHmiFull:YES];
            // the app is just started by the user. Send everything needed to be done once
            [self sendWelcomeMessageWithSpeak:YES];
            [self sendWeatherVoiceCommands];
            [self sendChangeUnitsVoiceCommand];
            [self subscribeRepeatButton];
            [self sendDefaultGlobalProperties];
            [self createChangeUnitsInteractionChoiceSet];
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
        case CMDID_CHANGE_UNITS: {
            // the user has performed the voice command to change the units
            SDLInteractionMode *mode = nil;
            if ([[notification triggerSource] isEqual:[SDLTriggerSource MENU]]) {
                mode = [SDLInteractionMode MANUAL_ONLY];
            } else {
                mode = [SDLInteractionMode BOTH];
            }
            
            [self performChangeUnitsInteractionWithMode:mode];
        }
    }
}

- (void)onOnButtonPress:(SDLOnButtonPress *)notification {
    WeatherDataManager *manager = [WeatherDataManager sharedManager];
    
    if ([[SDLButtonName PRESET_1] isEqual:[notification buttonName]]) {
        [self repeatWeatherInformation];
    } else if ([[SDLButtonName CUSTOM_BUTTON] isEqual:[notification buttonName]]) {
        NSUInteger command = [[notification customButtonID] unsignedIntegerValue];
        switch (command) {
            case BTNID_SHOW_WEATHER_CONDITIONS: {
                [self sendWeatherConditions:[manager weatherConditions] withSpeak:YES];
                break;
            }
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
