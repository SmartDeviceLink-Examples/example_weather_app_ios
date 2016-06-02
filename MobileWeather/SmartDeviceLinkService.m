//
//  SmartDeviceLinkService.m
//  MobileWeather
//
//  Created by Ryan Conroy on 5/24/16.
//  Copyright © 2016 Ford. All rights reserved.
//

#import "SmartDeviceLinkService.h"

#import "WeatherDataManager.h"
#import "SmartDeviceLink.h"
#import "WeatherLanguage.h"
#import "ImageProcessor.h"
#import "Localization.h"
#import "SDLChoice.h"
#import "InfoType.h"

#import "SDLUploadFileOperation.h"


#define CMDID_SHOW_WEATHER_CONDITIONS 101
#define CMDID_SHOW_DAILY_FORECAST     102
#define CMDID_SHOW_HOURLY_FORECAST    103
#define CMDID_SHOW_ALERTS             104
#define CMDID_CHANGE_UNITS            105
#define CMDID_LIST_NEXT               111
#define CMDID_LIST_PREVIOUS           112
#define CMDID_LIST_SHOW_LIST          113
#define CMDID_LIST_BACK               114
#define CMDID_LIST_HOURLY_NOW         115
#define CMDID_LIST_DAILY_TODAY        116
#define CMDID_LIST_DAILY_TOMORROW     117
#define CMDID_LIST_SHOW_MESSAGE       118

#define BTNID_SHOW_WEATHER_CONDITIONS 201
#define BTNID_SHOW_DAILY_FORECAST     202
#define BTNID_SHOW_HOURLY_FORECAST    203
#define BTNID_SHOW_ALERTS             204
#define BTNID_LIST_NEXT               211
#define BTNID_LIST_PREVIOUS           212
#define BTNID_LIST_INACTIVE           213
#define BTNID_LIST_SHOW_LIST          214
#define BTNID_LIST_BACK               215
#define BTNID_LIST_SHOW_MESSAGE       216

#define CHOICESET_CHANGE_UNITS        300
#define CHOICE_UNIT_METRIC            301
#define CHOICE_UNIT_IMPERIAL          302

#define CHOICESET_LIST                400


@interface SmartDeviceLinkService () <SDLProxyListener>


@property SDLManager *manager;

@property SDLLanguage *language;

@property InfoType *currentInfoType;

@property Localization *localization;

@property SDLHMILevel *currentHMILevel;

@property BOOL isAppIconSet;
@property BOOL graphicsAvailable;
@property BOOL isFirstTimeHmiFull;

@property NSArray *templatesAvailable;
@property NSArray  *currentInfoTypeList;
@property NSArray *currentForecastChoices;

@property NSMutableSet *currentFiles;
@property NSMutableSet *currentKnownAlerts;

@property NSMutableDictionary *currentFilesPending;
@property NSMutableDictionary *pendingSequentialRequests;

@property NSUInteger textFieldsAvailable;
@property NSUInteger softButtonsAvailable;
@property NSInteger currentInfoTypeListIndex;

@end




@implementation SmartDeviceLinkService



+ (instancetype)sharedService {
    static id shared = nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{ shared = [[self alloc] init]; });
    return shared;
}

#pragma mark - Proxy Lifecycle
- (void)dealloc {
    [self.manager stop];
}

- (void)start {
    [self.manager start];
}

- (void)stop {
    [self.manager stop];
}

- (void)setupProxy {
    
    if(self.manager == nil){
        [self resetProperties];
        [self.manager start];
    }
}


- (void)teardownProxy {
    
    if(self.manager != nil){
        [self.manager stop];
    }
}

- (void)onProxyOpened {
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(repeatWeatherInformation)
     name:MobileWeatherUnitChangedNotification
     object:nil];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(handleWeatherDataUpdate:)
     name:MobileWeatherDataUpdatedNotification
     object:nil];
    [self registerApplicationInterface];
}

- (void)onProxyClosed {
    
    [[NSNotificationCenter defaultCenter]
     removeObserver:self
     name:MobileWeatherUnitChangedNotification
     object:nil];
    
    [[NSNotificationCenter defaultCenter]
     removeObserver:self
     name:MobileWeatherDataUpdatedNotification
     object:nil];
    [self teardownProxy];
    [self setupProxy];
}

- (void)onPutFileResponse:(SDLPutFileResponse *)response {
    
    [self handleSequentialRequestsForResponse:response];
    
    //correlation ID: used to identify a response to a specific request you sent to the head unit.
    
    NSString *filename = [[self currentFilesPending] objectForKey:[response correlationID]];
    
    if (filename) {
        [[self currentFilesPending] removeObjectForKey:[response correlationID]];
        if ([[SDLResult SUCCESS] isEqual:[response resultCode]]) {
            [[self currentFiles] addObject:filename];
        }
    }
}

-(void)onDeleteFileResponse:(SDLDeleteFileResponse*) response {
    
    [self handleSequentialRequestsForResponse:response];
    
    NSString *filename = [[self currentFilesPending] objectForKey:[response correlationID]];
    
    if (filename) {
        [[self currentFilesPending] removeObjectForKey:[response correlationID]];
        if ([[SDLResult SUCCESS] isEqual:[response resultCode]]) {
            [[self currentFiles] removeObject:filename];
        }
    }
}

- (void)onRegisterAppInterfaceResponse:(SDLRegisterAppInterfaceResponse *)response {
    
    [self setGraphicsAvailable:[[[response displayCapabilities] graphicSupported] boolValue]];
    
    [self handleSequentialRequestsForResponse:response];
    
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
    
    [self sendListFiles];
}

- (void)onSetAppIconResponse:(SDLSetAppIconResponse *)response {
    
    [self handleSequentialRequestsForResponse:response];
    
    if ([[SDLResult SUCCESS] isEqual:[response resultCode]]) {
        [self setIsAppIconSet:YES];
    }
}

- (void)onCommmand:(SDLOnCommand *)notification {
    
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
            break;
        }
        case CMDID_SHOW_DAILY_FORECAST: {
            [self sendForecastList:[manager dailyForecast] infoType:[InfoType DAILY_FORECAST] withSpeak:YES];
            break;
        }
        case CMDID_SHOW_HOURLY_FORECAST: {
            [self sendForecastList:[manager hourlyForecast] infoType:[InfoType HOURLY_FORECAST] withSpeak:YES];
            break;
        }
        case CMDID_LIST_NEXT: {
            InfoType *infoType = [self currentInfoType];
            if ([self currentInfoTypeListIndex] + 1 < [[self currentInfoTypeList] count]) {
                NSInteger index = [self currentInfoTypeListIndex] + 1;
                if ([infoType isEqual:[InfoType DAILY_FORECAST]] || [infoType isEqual:[InfoType HOURLY_FORECAST]]) {
                    [self sendForecastAtIndex:index fromList:[self currentInfoTypeList] infoType:infoType withSpeak:YES];
                } else if ([infoType isEqual:[InfoType ALERTS]]) {
                    [self sendAlertAtIndex:index fromList:[self currentInfoTypeList] withSpeak:YES];
                }
                [self setCurrentInfoTypeListIndex:index];
            }
            
            break;
        }
        case CMDID_LIST_PREVIOUS: {
            InfoType *infoType = [self currentInfoType];
            if ([self currentInfoTypeListIndex] > 0) {
                NSInteger index = [self currentInfoTypeListIndex] - 1;
                if ([infoType isEqual:[InfoType DAILY_FORECAST]] || [infoType isEqual:[InfoType HOURLY_FORECAST]]) {
                    [self sendForecastAtIndex:index fromList:[self currentInfoTypeList] infoType:infoType withSpeak:YES];
                }else if ([infoType isEqual:[InfoType ALERTS]]) {
                    [self sendAlertAtIndex:index fromList:[self currentInfoTypeList] withSpeak:YES];
                }
                [self setCurrentInfoTypeListIndex:index];
            }
            break;
        }
        case CMDID_LIST_HOURLY_NOW: {
            [self sendForecastAtIndex:0 fromList:[self currentInfoTypeList] infoType:[self currentInfoType] withSpeak:YES];
            [self setCurrentInfoTypeListIndex:0];
            break;
        }
        case CMDID_LIST_DAILY_TODAY: {
            [self sendForecastAtIndex:0 fromList:[self currentInfoTypeList] infoType:[self currentInfoType] withSpeak:YES];
            [self setCurrentInfoTypeListIndex:0];
            break;
        }
        case CMDID_LIST_DAILY_TOMORROW: {
            [self sendForecastAtIndex:1 fromList:[self currentInfoTypeList] infoType:[self currentInfoType] withSpeak:YES];
            [self setCurrentInfoTypeListIndex:1];
            break;
        }
        case CMDID_LIST_BACK: {
            [self closeListInfoType:[self currentInfoType]];
            break;
        }
        case CMDID_LIST_SHOW_LIST: {
            SDLInteractionMode * mode = nil;
            if ([[SDLTriggerSource MENU] isEqual:[notification triggerSource]]) {
                mode = [SDLInteractionMode MANUAL_ONLY];
            } else {
                mode = [SDLInteractionMode BOTH];
            }
            [self performForecastInteractionWithMode:mode];
            break;
        }
        case CMDID_SHOW_ALERTS: {
            [self sendAlertList:[manager alerts] withSpeak:YES];
            break;
        }
        case CMDID_LIST_SHOW_MESSAGE: {
            [self sendAlertMessageAtIndex:[self currentInfoTypeListIndex]];
            break;
        }
            
            
    }
}

- (void)onPerformInteractionResponse:(SDLPerformInteractionResponse *)response {
    
    //Handles response
    [self handleSequentialRequestsForResponse:response];
    
    if ([[SDLResult SUCCESS] isEqual:[response resultCode]] == NO) {
        return;
    }
    
    NSUInteger choiceID = [[response choiceID] unsignedIntegerValue];
    if (choiceID == CHOICE_UNIT_IMPERIAL || choiceID == CHOICE_UNIT_METRIC) {
        UnitType unit;
        if (choiceID == CHOICE_UNIT_IMPERIAL) {
            unit = UnitTypeImperial;
        } else {
            unit = UnitTypeMetric;
        }
        
        [[WeatherDataManager sharedManager] setUnit:unit];
    } else if ([self currentForecastChoices]) {
        for (SDLChoice *choice in [self currentForecastChoices]) {
            NSUInteger listChoiceID = [[choice choiceID] unsignedIntegerValue];
            if (listChoiceID == choiceID) {
                NSUInteger index = listChoiceID - CHOICESET_LIST - 1;
                [self sendForecastAtIndex:index fromList:[self currentInfoTypeList] infoType:[self currentInfoType] withSpeak:YES];
                [self setCurrentInfoTypeListIndex:index];
                break;
            }
        }
    }
}

- (void)onListFilesResponse:(SDLListFilesResponse *)response {
    
    [self handleSequentialRequestsForResponse:response];
    
    if ([[SDLResult SUCCESS] isEqual:[response resultCode]]) {
        if ([response filenames]) {
            [self setCurrentFiles:[NSMutableSet setWithArray:[response filenames]]];
        } else {
            [self setCurrentFiles:[NSMutableSet set]];
        }
    }
    [self setAppIcon];
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
            case BTNID_SHOW_DAILY_FORECAST: {
                [self sendForecastList:[manager dailyForecast] infoType:[InfoType DAILY_FORECAST] withSpeak:YES];
                break;
            }
            case BTNID_SHOW_HOURLY_FORECAST: {
                [self sendForecastList:[manager hourlyForecast] infoType:[InfoType HOURLY_FORECAST] withSpeak:YES];
                break;
            }
            case BTNID_SHOW_ALERTS: {
                [self sendAlertList:[manager alerts] withSpeak:YES];
                break;
            }
            case BTNID_LIST_NEXT: {
                InfoType *infoType = [self currentInfoType];
                if ([self currentInfoTypeListIndex] + 1 < [[self currentInfoTypeList] count]) {
                    NSInteger index = [self currentInfoTypeListIndex] + 1;
                    if ([infoType isEqual:[InfoType DAILY_FORECAST]] || [infoType isEqual:[InfoType HOURLY_FORECAST]]) {
                        [self sendForecastAtIndex:index fromList:[self currentInfoTypeList] infoType:infoType withSpeak:YES];
                    }
                    [self setCurrentInfoTypeListIndex:index];
                }
                break;
            }
            case BTNID_LIST_PREVIOUS: {
                InfoType *infoType = [self currentInfoType];
                if ([self currentInfoTypeListIndex] > 0) {
                    NSInteger index = [self currentInfoTypeListIndex] - 1;
                    if ([infoType isEqual:[InfoType DAILY_FORECAST]] || [infoType isEqual:[InfoType HOURLY_FORECAST]]) {
                        [self sendForecastAtIndex:index fromList:[self currentInfoTypeList] infoType:infoType withSpeak:YES];
                    }
                    [self setCurrentInfoTypeListIndex:index];
                }
                break;
            }
            case BTNID_LIST_BACK: {
                [self closeListInfoType:[self currentInfoType]];
                break;
            }
            case BTNID_LIST_SHOW_MESSAGE: {
                [self sendAlertMessageAtIndex:[self currentInfoTypeListIndex]];
                break;
            }
            case BTNID_LIST_SHOW_LIST: {
                [self performForecastInteractionWithMode:[SDLInteractionMode MANUAL_ONLY]];
                break;
            }
        }
    }
}

- (void)onOnHMIStatus:(SDLOnHMIStatus *)notification {
    
    [self setCurrentHMILevel:[notification hmiLevel]];
    
    SDLHMILevel *hmiLevel = [notification hmiLevel];
    
    [self sendWelcomeMessageWithSpeak:TRUE];
    [self sendWeatherVoiceCommands];
    [self sendChangeUnitsVoiceCommand];
    [self subscribeRepeatButton];
    [self createChangeUnitsInteractionChoiceSet];
    
    // check current HMI level of the app
    if ([[SDLHMILevel FULL] isEqual:hmiLevel]) {
        if ([self isFirstTimeHmiFull] == NO) {
            [self setIsFirstTimeHmiFull:YES];
            // the app is just started by the user. Send everything needed to be done once
            [self sendWelcomeMessageWithSpeak:YES];
        }
    }
}

- (void)onOnDriverDistraction:(SDLOnDriverDistraction *)notification {


}

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

- (NSNumber *)nextCorrelationID {
    
    static UInt32 correlation = 0;
    correlation = (correlation + 1) % UINT32_MAX;
    return @(correlation);
}

- (void)sendRequest:(SDLRPCRequest *)request {
    
    if ([request correlationID] == nil) {
        [request setCorrelationID:[self nextCorrelationID]];
    }
    
    if ([request isMemberOfClass:[SDLPutFile class]] || [request isMemberOfClass:[SDLDeleteFile class]]) {
        NSString *filename = [(id)request syncFileName];
        [[self currentFilesPending] setObject:filename forKey:[request correlationID]];
    }
    
    [self.manager sendRequest:request withCompletionHandler:^(__kindof SDLRPCRequest * _Nullable request, __kindof SDLRPCResponse * _Nullable response, NSError * _Nullable error) {
        
        if(!error){
            
            
            
        }else{
            
            
            NSLog(@"Error! Send request failed: %@", error);
        }
    }];
    
}

- (void)resetProperties {
    
    [self setLanguage:nil];
    [self setLocalization:nil];
    [self setCurrentHMILevel:nil];
    [self setCurrentInfoType:nil];
    [self setGraphicsAvailable:NO];
    [self setIsFirstTimeHmiFull:NO];
    [self setTextFieldsAvailable:0];
    [self setSoftButtonsAvailable:0];
    [self setTemplatesAvailable:nil];
    [self setCurrentInfoTypeList:nil];
    [self setCurrentInfoTypeListIndex:-1];
    [self setCurrentKnownAlerts:[NSMutableSet set]];
    [self setPendingSequentialRequests:[NSMutableDictionary dictionary]];

}

- (void)handleSequentialRequestsForResponse:(SDLRPCResponse *)response {
    
    if (response) {
        NSNumber *correlationID = [response correlationID];
        SDLRPCRequest *request = [[self pendingSequentialRequests] objectForKey:correlationID];
        if (request) {
            [self sendRequest:request];
        }
    }
}

- (void)setAppIcon {
    
    if ([self graphicsAvailable] == YES && [self isAppIconSet] == NO) {
        NSString *filename = @"AppIcon.png";
        
        SDLSetAppIcon *request = [[SDLSetAppIcon alloc] init];
        [request setSyncFileName:filename];
        
        if ([[self currentFiles] containsObject:filename] == NO) {
            SDLPutFile *putfile = [self buildPutFile:filename ofType:[SDLFileType GRAPHIC_PNG] persistentFile:YES systemFile:NO];
            [self sendRequestArray:@[putfile, request] sequentially:YES];
        } else {
            [self sendRequest:request];
        }
    }
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
        
        [[self localization] stringForKey:@"key"];
    }
}

- (void)sendWelcomeMessageWithSpeak:(BOOL)withSpeak {
    
    [self setCurrentInfoType:[InfoType NONE]];
    
    SDLShow *show = [[SDLShow alloc] init];
    [show setSoftButtons:[self buildDefaultSoftButtons]];
    [show setMainField1:@"Welcome to"];
    [show setMainField2:@"MobileWeather"];
    [show setMainField3:@""];
    [show setMainField4:@""];
    [show setAlignment:[SDLTextAlignment CENTERED]];
    [self sendRequest:show];
    
    if (withSpeak) {
        SDLSpeak *speak = [[SDLSpeak alloc] init];
        [speak setTtsChunks:[SDLTTSChunkFactory buildTTSChunksFromSimple:@"Welcome to MobileWeather"]];
        [self sendRequest:speak];
    }
}

- (void)sendWeatherConditions:(WeatherConditions *)conditions withSpeak:(BOOL)withSpeak {
    
    if (conditions != nil) {
        // use these types for unit conversion
        [self setCurrentInfoType:[InfoType WEATHER_CONDITIONS]];
        UnitPercentageType percentageType = UnitPercentageDefault;
        UnitTemperatureType temperatureType = UnitTemperatureCelsius;
        UnitSpeedType speedType = UnitSpeedMeterSecond;
        
        if ([[WeatherDataManager sharedManager] unit] == UnitTypeMetric) {
            temperatureType = UnitTemperatureCelsius;
            speedType = UnitSpeedKiloMeterHour;
        }
        else if ([[WeatherDataManager sharedManager] unit] == UnitTypeImperial) {
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
            NSString *weathercondition = [NSString stringWithFormat:@"%@ %@ %@",
                                          [[conditions temperature] stringValueForUnit:temperatureType shortened:YES],
                                          [[conditions humidity] stringValueForUnit:percentageType shortened:YES],
                                          [[conditions windSpeed] stringValueForUnit:speedType shortened:YES]];
            
            [showRequest setMainField2:weathercondition];
        }
        //[self sendRequest:showRequest];
        [self sendShowRequest:showRequest withImageNamed:[conditions conditionIcon]];
        
        if (withSpeak) {
            SDLSpeak *speakRequest = [[SDLSpeak alloc] init];
            SDLTTSChunk *chunk = [[SDLTTSChunk alloc] init];
            [chunk setType:[SDLSpeechCapabilities TEXT]];
            [chunk setText:[NSString stringWithFormat:
                            @"Currently it is %@, and %@, with %@ humidity and %@ precipitation chance.",
                            [conditions conditionTitle],
                            [[conditions temperature] stringValueForUnit:temperatureType shortened:NO],
                            [[conditions humidity] stringValueForUnit:percentageType shortened:NO],
                            [[conditions windSpeed] stringValueForUnit:speedType shortened:NO]]];
            
            [speakRequest setTtsChunks:[NSMutableArray arrayWithObject:chunk]];
            [self sendRequest:speakRequest];
        }else {
            SDLAlert  *alertRequest = [[SDLAlert alloc] init];
            [alertRequest setAlertText1:@"Weather conditions"];
            [alertRequest setAlertText2:@"not available"];
            [alertRequest setTtsChunks:[SDLTTSChunkFactory buildTTSChunksFromSimple:@"Current weather conditions not available"]];
            [self sendRequest:alertRequest];
        }
    }
}

- (void)sendWeatherVoiceCommands {
    
    SDLAddCommand *request = nil;
    SDLMenuParams *menuparams = nil;
    
    menuparams = [[SDLMenuParams alloc] init];
    [menuparams setMenuName:@"Current conditions"];
    [menuparams setPosition:@(1)];
    request = [[SDLAddCommand alloc] init];
    [request setMenuParams:menuparams];
    [request setCmdID:@(CMDID_SHOW_WEATHER_CONDITIONS)];
    [request setVrCommands:[NSMutableArray arrayWithObjects:
                            @"Conditions", @"Current conditions", @"Show current conditions", nil]];
    [self sendRequest:request];
    
    menuparams = [[SDLMenuParams alloc] init];
    [menuparams setMenuName:@"Daily forecast"];
    [menuparams setPosition:@(2)];
    request = [[SDLAddCommand alloc] init];
    [request setMenuParams:menuparams];
    [request setCmdID:@(CMDID_SHOW_DAILY_FORECAST)];
    [request setVrCommands:[NSMutableArray arrayWithObjects:
                            @"Daily", @"Daily forecast", @"Show daily forecast", nil]];
    [self sendRequest:request];
    
    menuparams = [[SDLMenuParams alloc] init];
    [menuparams setMenuName:@"Hourly forecast"];
    [menuparams setPosition:@(3)];
    request = [[SDLAddCommand alloc] init];
    [request setMenuParams:menuparams];
    [request setCmdID:@(CMDID_SHOW_HOURLY_FORECAST)];
    [request setVrCommands:[NSMutableArray arrayWithObjects:
                            @"Hourly", @"Hourly forecast", @"Show hourly forecast", nil]];
    [self sendRequest:request];
    
    menuparams = [[SDLMenuParams alloc] init];
    [menuparams setMenuName:@"Alerts"];
    [menuparams setPosition:@(4)];
    request = [[SDLAddCommand alloc] init];
    [request setMenuParams:menuparams];
    [request setCmdID:@(CMDID_SHOW_ALERTS)];
    [request setVrCommands:[NSMutableArray arrayWithObjects:
                            @"alerts", @"show alerts", nil]];
    [self sendRequest:request];
}


- (SDLPutFile *)buildPutFile:(NSString *)filename ofType:(SDLFileType *)type persistentFile:(BOOL)persistentFile systemFile:(BOOL)systemFile {
    
    SDLPutFile *request = nil;
    
    if ([self graphicsAvailable]) {
        NSData *data = [[ImageProcessor sharedProcessor] dataFromConditionImage:filename];
        if (data) {
            request = [[SDLPutFile alloc] init];
            [request setSyncFileName:filename];
            [request setFileType:type];
            [request setSystemFile:@(systemFile)];
            [request setPersistentFile:@(persistentFile)];
            [request setOffset:@(0)];
            [request setLength:@(0)];
            [request setBulkData:data];
        }
    }
    
    return request;
}

- (SDLDeleteFile *)buildDeleteFile:(NSString *)filename {
    
    SDLDeleteFile *request = nil;
    if ([self graphicsAvailable]) {
        request = [[SDLDeleteFile alloc] init];
        [request setSyncFileName:filename];
    }
    return request;
}

- (void)sendListFiles {
    if ([self graphicsAvailable]) {
        [self sendRequest:[[SDLListFiles alloc] init]];
    }
}

- (void)sendShowRequest:(SDLShow *)request withImageNamed:(NSString *)filename {
    
    if ([self graphicsAvailable] && filename) {
        SDLImage *image = [[SDLImage alloc] init];
        [image setImageType:[SDLImageType DYNAMIC]];
        [image setValue:filename];
        
        if ([[self currentFiles] containsObject:filename]) {
            [request setGraphic:image];
            [self sendRequest:request];
            
        } else {
            [self sendRequest:request];
            
            SDLPutFile *putfile = [self buildPutFile:filename ofType:[SDLFileType GRAPHIC_PNG] persistentFile:NO systemFile:NO];
            if (putfile) {
                SDLShow *showImage = [[SDLShow alloc] init];
                [showImage setGraphic:image];
                [self sendRequestArray:@[putfile, showImage] sequentially:YES];
            } else {
                [self sendRequest:request];
            }
        }
    }
    
}


- (void)repeatWeatherInformation {
    
    WeatherDataManager *manager = [WeatherDataManager sharedManager];
    InfoType *infoType = [self currentInfoType];
    if ([[InfoType WEATHER_CONDITIONS] isEqual:infoType]) {
        [self sendWeatherConditions:[manager weatherConditions] withSpeak:YES];
    } else if ([[InfoType DAILY_FORECAST] isEqual:infoType] || [[InfoType HOURLY_FORECAST] isEqual:infoType]) {
        [self sendForecastAtIndex:[self currentInfoTypeListIndex]
                         fromList:[self currentInfoTypeList]
                         infoType:infoType
                        withSpeak:YES];
    } else if ([[InfoType ALERTS] isEqual:infoType]) {
        [self sendAlertAtIndex:[self currentInfoTypeListIndex]
                      fromList:[self currentInfoTypeList]
                     withSpeak:YES];
    }
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
        [button setText:@"Weather"];
        [button setType:[SDLSoftButtonType TEXT]];
        [button setSystemAction:[SDLSystemAction DEFAULT_ACTION]];
        [buttons addObject:button];
    }
    
    if ([self softButtonsAvailable] > 1) {
        SDLSoftButton *button = [[SDLSoftButton alloc] init];
        [button setSoftButtonID:@(BTNID_SHOW_DAILY_FORECAST)];
        [button setText:@"Daily"];
        [button setType:[SDLSoftButtonType TEXT]];
        [button setSystemAction:[SDLSystemAction DEFAULT_ACTION]];
        [buttons addObject:button];
    }
    
    if ([self softButtonsAvailable] > 2) {
        SDLSoftButton *button = [[SDLSoftButton alloc] init];
        [button setSoftButtonID:@(BTNID_SHOW_HOURLY_FORECAST)];
        [button setText:@"Hourly"];
        [button setType:[SDLSoftButtonType TEXT]];
        [button setSystemAction:[SDLSystemAction DEFAULT_ACTION]];
        [buttons addObject:button];
    }
    
    if ([self softButtonsAvailable] > 3) {
        SDLSoftButton *button = [[SDLSoftButton alloc] init];
        [button setSoftButtonID:@(BTNID_SHOW_ALERTS)];
        [button setText:@"Alerts"];
        [button setType:[SDLSoftButtonType TEXT]];
        [button setSystemAction:[SDLSystemAction DEFAULT_ACTION]];
        [buttons addObject:button];
        
    }
    
    return buttons;
}


- (void)sendDefaultGlobalProperties {
    
    SDLSetGlobalProperties *request = [[SDLSetGlobalProperties alloc] init];
    NSMutableArray *prompts = [NSMutableArray array];
    NSMutableArray *helpitems = [NSMutableArray array];
    SDLVRHelpItem *helpitem;
    
    helpitem = [[SDLVRHelpItem alloc] init];
    [helpitem setPosition:@(1)];
    [helpitem setText:@"Current conditions"];
    [helpitems addObject:helpitem];
    [prompts addObject:@"Show current conditions"];
    
    helpitem = [[SDLVRHelpItem alloc] init];
    [helpitem setPosition:@(2)];
    [helpitem setText:@"Daily forecast"];
    [helpitems addObject:helpitem];
    [prompts addObject:@"Daily forecast"];
    
    helpitem = [[SDLVRHelpItem alloc] init];
    [helpitem setPosition:@(3)];
    [helpitem setText:@"Hourly forecast"];
    [helpitems addObject:helpitem];
    [prompts addObject:@"Hourly forecast"];
    
    helpitem = [[SDLVRHelpItem alloc] init];
    [helpitem setPosition:@(4)];
    [helpitem setText:@"change units"];
    [helpitems addObject:helpitem];
    [prompts addObject:@"Change units"];
    
    NSString *promptstring = [prompts componentsJoinedByString:@","];
    
    [request setHelpPrompt:[SDLTTSChunkFactory buildTTSChunksFromSimple:promptstring]];
    [request setTimeoutPrompt:[SDLTTSChunkFactory buildTTSChunksFromSimple:promptstring]];
    [request setVrHelpTitle:@"MobileWeather"];
    [request setVrHelp:helpitems];
    
    [self sendRequest:request];
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
    NSMutableArray *requests = [NSMutableArray arrayWithCapacity:[unknownSorted count]];
    
    for (Alert *alert in unknownSorted) {
        NSString *chunk = [NSString stringWithFormat:@"%@ until %@",
                           [alert alertTitle], [formatterSpeak stringFromDate:[alert dateExpires]]];
        NSMutableArray *chunks = [SDLTTSChunkFactory buildTTSChunksFromSimple:chunk];
        
        // create an alert request
        SDLAlert *request = [[SDLAlert alloc] init];
        [request setAlertText1:[alert alertTitle]];
        [request setAlertText2:[formatterShow stringFromDate:[alert dateExpires]]];
        [request setTtsChunks:chunks];
        [requests addObject:request];
    }
    
    [self sendRequestArray:requests sequentially:YES];
    [[self currentKnownAlerts] unionSet:unknown];
    
    InfoType *infoType = [self currentInfoType];
    if ([[InfoType WEATHER_CONDITIONS] isEqual:infoType]) {
        WeatherConditions *conditions = [[notification userInfo] objectForKey:@"weatherConditions"];
        [self sendWeatherConditions:conditions withSpeak:NO];
    } else if ([[InfoType DAILY_FORECAST] isEqual:infoType]) {
        NSArray *forecast = [[notification userInfo] objectForKey:@"dailyForecast"];
        [self sendForecastList:forecast infoType:infoType withSpeak:NO];
    } else if ([[InfoType HOURLY_FORECAST] isEqual:infoType]) {
        NSArray *forecast = [[notification userInfo] objectForKey:@"hourlyForecast"];
        [self sendForecastList:forecast infoType:infoType withSpeak:NO];
    } else if ([[InfoType ALERTS] isEqual:infoType]) {
        NSArray *alerts = [[notification userInfo] objectForKey:@"alerts"];
        [self sendAlertList:alerts withSpeak:NO];
    }
}

- (void)createChangeUnitsInteractionChoiceSet {
    
    SDLCreateInteractionChoiceSet *request = [[SDLCreateInteractionChoiceSet alloc] init];
    NSMutableArray *choiceset = [NSMutableArray arrayWithCapacity:2];
    SDLChoice *choice;
    
    choice = [[SDLChoice alloc] init];
    [choice setChoiceID:@(CHOICE_UNIT_METRIC)];
    [choice setMenuName:@"Metric"];
    [choice setVrCommands:[NSMutableArray arrayWithObjects:@"Metric", nil]];
    [choiceset addObject:choice];
    
    choice = [[SDLChoice alloc] init];
    [choice setChoiceID:@(CHOICE_UNIT_IMPERIAL)];
    [choice setMenuName:@"Imperial"];
    [choice setVrCommands:[NSMutableArray arrayWithObjects:@"Imperial", nil]];
    [choiceset addObject:choice];
    
    [request setChoiceSet:choiceset];
    [request setInteractionChoiceSetID:@(CHOICESET_CHANGE_UNITS)];
    
    [self sendRequest:request];
}

- (void)performChangeUnitsInteractionWithMode:(SDLInteractionMode *)mode {
    
    SDLPerformInteraction *request = [[SDLPerformInteraction alloc] init];
    [request setInitialText:@"Change units"];
    [request setInitialPrompt:[SDLTTSChunkFactory buildTTSChunksFromSimple:@"Please select a unit in metric or imperial"]];
    [request setHelpPrompt:[SDLTTSChunkFactory buildTTSChunksFromSimple:@"metric, imperial"]];
    [request setTimeoutPrompt:[SDLTTSChunkFactory buildTTSChunksFromSimple:@"metric, imperial"]];
    [request setInteractionChoiceSetIDList:[NSMutableArray arrayWithObject:@(CHOICESET_CHANGE_UNITS)]];
    [request setInteractionMode:(mode ? mode : [SDLInteractionMode BOTH])];
    [request setTimeout:@(60000)];
    
    [self sendRequest:request];
}

- (void)sendChangeUnitsVoiceCommand {
    
    SDLAddCommand *request = nil;
    SDLMenuParams *menuparams = nil;
    
    menuparams = [[SDLMenuParams alloc] init];
    [menuparams setMenuName:@"Change units"];
    [menuparams setPosition:@(5)];
    request = [[SDLAddCommand alloc] init];
    [request setMenuParams:menuparams];
    [request setCmdID:@(CMDID_CHANGE_UNITS)];
    [request setVrCommands:[NSMutableArray arrayWithObjects:
                            @"Units", @"Change units", nil]];
    [self sendRequest:request]; 
}

- (void)deleteWeatherVoiceCommands {
    
    SDLDeleteCommand *request = nil;
    
    request = [[SDLDeleteCommand alloc] init];
    [request setCmdID:@(CMDID_SHOW_WEATHER_CONDITIONS)];
    [self sendRequest:request];
    
    request = [[SDLDeleteCommand alloc] init];
    [request setCmdID:@(CMDID_SHOW_DAILY_FORECAST)];
    [self sendRequest:request];
    
    request = [[SDLDeleteCommand alloc] init];
    [request setCmdID:@(CMDID_SHOW_HOURLY_FORECAST)];
    [self sendRequest:request];
    
    request = [[SDLDeleteCommand alloc] init];
    [request setCmdID:@(CMDID_SHOW_ALERTS)];
    [self sendRequest:request];
}

- (void)sendListVoiceCommands:(InfoType *)infoType {
    
    SDLAddCommand *request;
    SDLMenuParams *menuparams;
    
    if ([[InfoType DAILY_FORECAST] isEqual:infoType] || [[InfoType HOURLY_FORECAST] isEqual:infoType]) {
        menuparams = [[SDLMenuParams alloc] init];
        [menuparams setMenuName:@"Show list"];
        [menuparams setPosition:@(3)];
        request = [[SDLAddCommand alloc] init];
        [request setMenuParams:menuparams];
        [request setCmdID:@(CMDID_LIST_SHOW_LIST)];
        [request setVrCommands:[NSMutableArray arrayWithObjects:@"List", @"Show list", nil]];
        [self sendRequest:request];
    }
    
    menuparams = [[SDLMenuParams alloc] init];
    [menuparams setMenuName:@"Back"];
    [menuparams setPosition:@(4)];
    request = [[SDLAddCommand alloc] init];
    [request setMenuParams:menuparams];
    [request setCmdID:@(CMDID_LIST_BACK)];
    [request setVrCommands:[NSMutableArray arrayWithObject:@"Back"]];
    [self sendRequest:request];
    
    if ([[InfoType HOURLY_FORECAST] isEqual:infoType]) {
        request = [[SDLAddCommand alloc] init];
        [request setCmdID:@(CMDID_LIST_HOURLY_NOW)];
        [request setVrCommands:[NSMutableArray arrayWithObject:@"Now"]];
        [self sendRequest:request];
    } else {
        request = [[SDLAddCommand alloc] init];
        [request setCmdID:@(CMDID_LIST_DAILY_TODAY)];
        [request setVrCommands:[NSMutableArray arrayWithObject:@"Today"]];
        [self sendRequest:request];
        
        request = [[SDLAddCommand alloc] init];
        [request setCmdID:@(CMDID_LIST_DAILY_TOMORROW)];
        [request setVrCommands:[NSMutableArray arrayWithObject:@"Tomorrow"]];
        [self sendRequest:request];
    }
}

- (void)deleteListVoiceCommands:(InfoType *)infoType {
    
    SDLDeleteCommand *request;
    
    if ([[InfoType DAILY_FORECAST] isEqual:infoType] || [[InfoType HOURLY_FORECAST] isEqual:infoType]) {
        request = [[SDLDeleteCommand alloc] init];
        [request setCmdID:@(CMDID_LIST_SHOW_LIST)];
        [self sendRequest:request];
    }
    
    request = [[SDLDeleteCommand alloc] init];
    [request setCmdID:@(CMDID_LIST_BACK)];
    [self sendRequest:request];
    
    if ([infoType isEqual:[InfoType HOURLY_FORECAST]]) {
        request = [[SDLDeleteCommand alloc] init];
        [request setCmdID:@(CMDID_LIST_HOURLY_NOW)];
        [self sendRequest:request];
    } else if ([[InfoType ALERTS] isEqual:infoType]) {
        request = [[SDLDeleteCommand alloc] init];
        [request setCmdID:@(CMDID_LIST_SHOW_MESSAGE)];
        [self sendRequest:request];
    } else {
        request = [[SDLDeleteCommand alloc] init];
        [request setCmdID:@(CMDID_LIST_DAILY_TODAY)];
        [self sendRequest:request];
        
        request = [[SDLDeleteCommand alloc] init];
        [request setCmdID:@(CMDID_LIST_DAILY_TOMORROW)];
        [self sendRequest:request];
    }
}

- (void)sendListNextVoiceCommand {
    SDLMenuParams *menuparams = [[SDLMenuParams alloc] init];
    [menuparams setMenuName:@"Next"];
    [menuparams setPosition:@(1)];
    SDLAddCommand *request = [[SDLAddCommand alloc] init];
    [request setMenuParams:menuparams];
    [request setCmdID:@(CMDID_LIST_NEXT)];
    [request setVrCommands:[NSMutableArray arrayWithObject:@"Next"]];
    [self sendRequest:request];
}

- (void)deleteListNextVoiceCommand {
    SDLDeleteCommand *request = [[SDLDeleteCommand alloc] init];
    [request setCmdID:@(CMDID_LIST_NEXT)];
    [self sendRequest:request];
}

- (void)sendListPreviousVoiceCommand {
    SDLMenuParams *menuparams = [[SDLMenuParams alloc] init];
    [menuparams setMenuName:@"Previous"];
    [menuparams setPosition:@(2)];
    SDLAddCommand *request = [[SDLAddCommand alloc] init];
    [request setMenuParams:menuparams];
    [request setCmdID:@(CMDID_LIST_PREVIOUS)];
    [request setVrCommands:[NSMutableArray arrayWithObject:@"Previous"]];
    [self sendRequest:request];
}

- (void)deleteListPreviousVoiceCommand {
    SDLDeleteCommand *request = [[SDLDeleteCommand alloc] init];
    [request setCmdID:@(CMDID_LIST_PREVIOUS)];
    [self sendRequest:request];
}

- (BOOL)updateListVoiceCommandsWithNewIndex:(NSInteger)newIndex
                                  ofNewList:(NSArray *)newList
                               withOldIndex:(NSInteger)oldIndex
                                  ofOldList:(NSArray *)oldList {
    BOOL newIsFirst, newIsLast, oldIsFirst, oldIsLast, modified;
    
    modified = NO;
    newIsFirst = (newIndex == 0);
    newIsLast = (newIndex + 1 == [newList count]);
    
    if (oldIndex == -1) {
        oldIsFirst = YES;
        oldIsLast = YES;
    } else {
        oldIsFirst = (oldIndex == 0);
        oldIsLast = (oldIndex + 1 == [oldList count]);
    }
    
    if (newIsFirst == NO && oldIsFirst == YES) {
        [self sendListPreviousVoiceCommand];
        modified = YES;
    } else if (newIsFirst == YES && oldIsFirst == NO) {
        [self deleteListPreviousVoiceCommand];
        modified = YES;
    }
    
    if (newIsLast == NO && oldIsLast == YES) {
        [self sendListNextVoiceCommand];
        modified = YES;
    } else if (newIsLast == YES && oldIsLast == NO) {
        [self deleteListNextVoiceCommand];
        modified = YES;
    }
    
    return modified;
}

- (void)sendForecastAtIndex:(NSUInteger)index fromList:(NSArray *)forecasts infoType:(InfoType *)infoType withSpeak:(BOOL)withSpeak {
    SDLShow *request = [[SDLShow alloc] init];
    
    if ([infoType isEqual:[InfoType DAILY_FORECAST]]) {
        [request setMainField1:@"Daily forecast"];
    } else {
        [request setMainField1:@"Hourly forecast"];
    }
    
    [request setMainField2:[NSString stringWithFormat:@"%i/%i", (int)index, (int)[forecasts count]]];
    [request setMainField3:@""];
    [request setMainField4:@""];
    [request setSoftButtons:[NSMutableArray array]];
    [request setSoftButtons:[self buildListSoftButtons:infoType withPrevious:YES withNext:YES]];
    [self sendRequest:request];
    
    BOOL isHourlyForecast = [infoType isEqual:[InfoType HOURLY_FORECAST]];
    Forecast *forecast = [forecasts objectAtIndex:index];
    
    NSDateFormatter *dateTimeFormatShow = [[NSDateFormatter alloc] init];
    [dateTimeFormatShow setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    [dateTimeFormatShow setLocale:[[self localization] locale]];
    
    NSDateFormatter *weekDayFormatShow = [[NSDateFormatter alloc] init];
    [weekDayFormatShow setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    [weekDayFormatShow setLocale:[[self localization] locale]];
    
    if (isHourlyForecast) {
        [dateTimeFormatShow setDateFormat:@"h a"];
        [weekDayFormatShow setDateFormat:@"E"];
    } else {
        [dateTimeFormatShow setDateFormat:@"MM/d"];
        [weekDayFormatShow setDateFormat:@"E"];
    }
    
    NSString *conditionTitleShow = [forecast conditionTitle];
    NSString *dateTimeStringShow = [dateTimeFormatShow stringFromDate:[forecast date]];
    NSString *weekDayStringShow = [weekDayFormatShow stringFromDate:[forecast date]];
    
    UnitPercentageType percentageType = UnitPercentageDefault;
    UnitTemperatureType temperatureType = UnitTemperatureCelsius;
    
    if ([[WeatherDataManager sharedManager] unit] == UnitTypeImperial) {
        temperatureType = UnitTemperatureFahrenheit;
    }
    
    if ([self updateListVoiceCommandsWithNewIndex:index
                                        ofNewList:forecasts
                                     withOldIndex:[self currentInfoTypeListIndex]
                                        ofOldList:[self currentInfoTypeList]]) {
        [self sendListGlobalProperties:infoType
                          withPrevious:(index != 0)
                              withNext:(index + 1 != [forecasts count])];
    }
    
    SDLShow *showRequest = [[SDLShow alloc] init];
    [showRequest setSoftButtons:
     [self buildListSoftButtons:infoType
                   withPrevious:(index != 0)
                       withNext:(index + 1 != [forecasts count])]];
    [showRequest setMainField1:@""];
    [showRequest setMainField2:@""];
    [showRequest setMainField3:@""];
    [showRequest setMainField4:@""];
    
    if (isHourlyForecast) {
        [showRequest setMainField1:[NSString stringWithFormat:
                                    @"%1$@: %2$@", dateTimeStringShow, conditionTitleShow]];
        
        if ([self textFieldsAvailable] >= 2) {
            [showRequest setMainField2:[NSString stringWithFormat:@"%1$@, %2$@, %3$@",
                                        [[forecast temperature] stringValueForUnit:temperatureType shortened:YES],
                                        [[forecast humidity] stringValueForUnit:percentageType shortened:YES],
                                        [[forecast precipitationChance] stringValueForUnit:percentageType shortened:YES]]]; 
        }
    }
    
    else {
        [showRequest setMainField1:[NSString stringWithFormat:
                                    @"%1$@: %2$@", weekDayStringShow, conditionTitleShow]];
        
        if ([self textFieldsAvailable] >= 2) {
            [showRequest setMainField2:[NSString stringWithFormat:
                                        @"%1$.0f - %2$.0f %3$@, %4$@, %5$@",
                                        [[forecast lowTemperature] doubleValueForUnit:temperatureType],
                                        [[forecast highTemperature] doubleValueForUnit:temperatureType],
                                        [[forecast highTemperature] nameForUnit:temperatureType shortened:YES],
                                        [[forecast humidity] stringValueForUnit:percentageType shortened:YES],
                                        [[forecast precipitationChance] stringValueForUnit:percentageType shortened:YES]]];
        }
    }
    
    //[self sendRequest:showRequest];
    [self sendShowRequest:showRequest withImageNamed:[forecast conditionIcon]];
    
    if (withSpeak) {
        NSDateFormatter *dateTimeFormatSpeak = [[NSDateFormatter alloc] init];
        [dateTimeFormatSpeak setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
        [dateTimeFormatSpeak setLocale:[[self localization] locale]];
        
        NSDateFormatter *weekDayFormatSpeak = [[NSDateFormatter alloc] init];
        [weekDayFormatSpeak setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
        [weekDayFormatSpeak setLocale:[[self localization] locale]];
        
        if (isHourlyForecast) {
            [dateTimeFormatSpeak setDateFormat:@"h a"];
            [weekDayFormatSpeak setDateFormat:@"EEEE"];
        } else {
            [dateTimeFormatSpeak setDateFormat:@"MMMM d"];
            [weekDayFormatSpeak setDateFormat:@"EEEE"];
        }
        
        NSString *dateTimeStringSpeak = [dateTimeFormatSpeak stringFromDate:[forecast date]];
        NSString *weekDayStringSpeak = [weekDayFormatSpeak stringFromDate:[forecast date]];
        NSString *speakString;
        
        if (isHourlyForecast) {
            speakString = [NSString stringWithFormat:@"At %1$@ it will be %2$@, %3$@ with %4$@ humidity, and a %5$@ precipitation chance.",
                           dateTimeStringSpeak,
                           [forecast conditionTitle],
                           [[forecast temperature] stringValueForUnit:temperatureType shortened:NO],
                           [[forecast humidity] stringValueForUnit:percentageType shortened:NO],
                           [[forecast precipitationChance] stringValueForUnit:percentageType shortened:NO]];
        }
        
        else {
            speakString = [NSString stringWithFormat:@"%1$@ it will be %2$@, %3$.0f to %4$.0f %5$@ with %6$@ humidity, and a %7$@ precipitation chance.",
                           weekDayStringSpeak,
                           [forecast conditionTitle],
                           [[forecast lowTemperature] doubleValueForUnit:temperatureType],
                           [[forecast highTemperature] doubleValueForUnit:temperatureType],
                           [[forecast highTemperature] nameForUnit:temperatureType shortened:NO],
                           [[forecast humidity] stringValueForUnit:percentageType shortened:NO],
                           [[forecast precipitationChance] stringValueForUnit:percentageType shortened:NO]];
        }
        
        SDLSpeak *speakRequest = [[SDLSpeak alloc] init];
        [speakRequest setTtsChunks:[SDLTTSChunkFactory buildTTSChunksFromSimple:speakString]];
        [self sendRequest:speakRequest];
    }
}

- (void)sendForecastList:(NSArray *)forecasts infoType:(InfoType *)infoType withSpeak:(BOOL)withSpeak {
    if (forecasts && [forecasts count] > 0) {
        if ([infoType isEqual:[InfoType DAILY_FORECAST]]) {
            forecasts = [forecasts subarrayWithRange:NSMakeRange(0, MIN([forecasts count], 7))];
        } else if ([infoType isEqual:[InfoType HOURLY_FORECAST]]) {
            forecasts = [forecasts subarrayWithRange:NSMakeRange(0, MIN([forecasts count], 24))];
        }
        
        NSUInteger index = 0;
        if ([infoType isEqual:[self currentInfoType]]) {
            [self deleteForecastChoiceSet];
            Forecast *oldForecast = [[self currentInfoTypeList]
                                     objectAtIndex:[self currentInfoTypeListIndex]];
            
            for (NSUInteger newindex = 0; newindex < [forecasts count]; newindex++) {
                Forecast *newForecast = [forecasts objectAtIndex:index];
                
                if ([[newForecast date] isEqualToDate:[oldForecast date]]) {
                    index = newindex;
                    break;
                }
            }
        } else {
            [self createForecastChoiceSetWithList:forecasts ofType:infoType];
            [self deleteWeatherVoiceCommands];
            [self sendListVoiceCommands:infoType];
        }
        
        [self sendForecastAtIndex:index fromList:forecasts infoType:infoType withSpeak:withSpeak];
        
        [self setCurrentInfoType:infoType];
        [self setCurrentInfoTypeList:forecasts];
        [self setCurrentInfoTypeListIndex:index];
        
        BOOL isHourlyForecast = [infoType isEqual:[InfoType HOURLY_FORECAST]];
        Forecast *forecast = [forecasts objectAtIndex:index];
        
        NSDateFormatter *dateTimeFormatShow = [[NSDateFormatter alloc] init];
        [dateTimeFormatShow setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
        [dateTimeFormatShow setLocale:[[self localization] locale]];
        
        NSDateFormatter *weekDayFormatShow = [[NSDateFormatter alloc] init];
        [weekDayFormatShow setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
        [weekDayFormatShow setLocale:[[self localization] locale]];
        
        if (isHourlyForecast) {
            [dateTimeFormatShow setDateFormat:@"h a"];
            [weekDayFormatShow setDateFormat:@"E"];
        } else {
            [dateTimeFormatShow setDateFormat:@"MM/d"];
            [weekDayFormatShow setDateFormat:@"E"];
        }
        
        NSString *conditionTitleShow = [forecast conditionTitle];
        NSString *dateTimeStringShow = [dateTimeFormatShow stringFromDate:[forecast date]];
        NSString *weekDayStringShow = [weekDayFormatShow stringFromDate:[forecast date]];
        
        UnitPercentageType percentageType = UnitPercentageDefault;
        UnitTemperatureType temperatureType = UnitTemperatureCelsius;
        
        if ([[WeatherDataManager sharedManager] unit] == UnitTypeImperial) {
            temperatureType = UnitTemperatureFahrenheit;
        }
        
        if ([self updateListVoiceCommandsWithNewIndex:index
                                            ofNewList:forecasts
                                         withOldIndex:[self currentInfoTypeListIndex]
                                            ofOldList:[self currentInfoTypeList]]) {
            [self sendListGlobalProperties:infoType
                              withPrevious:(index != 0)
                                  withNext:(index + 1 != [forecasts count])];
        }
        
        SDLShow *showRequest = [[SDLShow alloc] init];
        [showRequest setSoftButtons:
         [self buildListSoftButtons:infoType
                       withPrevious:(index != 0)
                           withNext:(index + 1 != [forecasts count])]];
        [showRequest setMainField1:@""];
        [showRequest setMainField2:@""];
        [showRequest setMainField3:@""];
        [showRequest setMainField4:@""];
        
        if (isHourlyForecast) {
            [showRequest setMainField1:[NSString stringWithFormat:
                                        @"%1$@: %2$@", dateTimeStringShow, conditionTitleShow]];
            
            if ([self textFieldsAvailable] >= 2) {
                [showRequest setMainField2:[NSString stringWithFormat:@"%1$@, %2$@, %3$@",
                                            [[forecast temperature] stringValueForUnit:temperatureType shortened:YES],
                                            [[forecast humidity] stringValueForUnit:percentageType shortened:YES],
                                            [[forecast precipitationChance] stringValueForUnit:percentageType shortened:YES]]];
            }
        }
        else {
            [showRequest setMainField1:[NSString stringWithFormat:
                                        @"%1$@: %2$@", weekDayStringShow, conditionTitleShow]];
            
            if ([self textFieldsAvailable] >= 2) {
                [showRequest setMainField2:[NSString stringWithFormat:
                                            @"%1$.0f - %2$.0f %3$@, %4$@, %5$@",
                                            [[forecast lowTemperature] doubleValueForUnit:temperatureType],
                                            [[forecast highTemperature] doubleValueForUnit:temperatureType],
                                            [[forecast highTemperature] nameForUnit:temperatureType shortened:YES],
                                            [[forecast humidity] stringValueForUnit:percentageType shortened:YES],
                                            [[forecast precipitationChance] stringValueForUnit:percentageType shortened:YES]]];
            }
        }
        
        [self sendRequest:showRequest];
        
        if (withSpeak) {
            NSDateFormatter *dateTimeFormatSpeak = [[NSDateFormatter alloc] init];
            [dateTimeFormatSpeak setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
            [dateTimeFormatSpeak setLocale:[[self localization] locale]];
            
            NSDateFormatter *weekDayFormatSpeak = [[NSDateFormatter alloc] init];
            [weekDayFormatSpeak setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
            [weekDayFormatSpeak setLocale:[[self localization] locale]];
            
            if (isHourlyForecast) {
                [dateTimeFormatSpeak setDateFormat:@"h a"];
                [weekDayFormatSpeak setDateFormat:@"EEEE"];
            } else {
                [dateTimeFormatSpeak setDateFormat:@"MMMM d"];
                [weekDayFormatSpeak setDateFormat:@"EEEE"];
            }
            NSString *dateTimeStringSpeak = [dateTimeFormatSpeak stringFromDate:[forecast date]];
            NSString *weekDayStringSpeak = [weekDayFormatSpeak stringFromDate:[forecast date]];
            NSString *speakString;
            if (isHourlyForecast) {
                speakString = [NSString stringWithFormat:@"At %1$@ it will be %2$@, %3$@ with %4$@ humidity, and a %5$@ precipitation chance.",
                               dateTimeStringSpeak,
                               [forecast conditionTitle],
                               [[forecast temperature] stringValueForUnit:temperatureType shortened:NO],
                               [[forecast humidity] stringValueForUnit:percentageType shortened:NO],
                               [[forecast precipitationChance] stringValueForUnit:percentageType shortened:NO]];
            } else {
                speakString = [NSString stringWithFormat:@"%1$@ it will be %2$@, %3$.0f to %4$.0f %5$@ with %6$@ humidity, and a %7$@ precipitation chance.",
                               weekDayStringSpeak,
                               [forecast conditionTitle],
                               [[forecast lowTemperature] doubleValueForUnit:temperatureType],
                               [[forecast highTemperature] doubleValueForUnit:temperatureType],
                               [[forecast highTemperature] nameForUnit:temperatureType shortened:NO],
                               [[forecast humidity] stringValueForUnit:percentageType shortened:NO],
                               [[forecast precipitationChance] stringValueForUnit:percentageType shortened:NO]];
            }
            
            SDLSpeak *speakRequest = [[SDLSpeak alloc] init];
            [speakRequest setTtsChunks:[SDLTTSChunkFactory buildTTSChunksFromSimple:speakString]];
            [self sendRequest:speakRequest];
        }
        
        
    } else {
        SDLAlert *alertRequest = [[SDLAlert alloc] init];
        [alertRequest setAlertText1:@"Forecast"];
        [alertRequest setAlertText2:@"not available"];
        [alertRequest setTtsChunks:[SDLTTSChunkFactory buildTTSChunksFromSimple:@"Forecast not available"]];
        [self sendRequest:alertRequest];
    }
}

- (void)sendRequestArray:(NSArray *)requests sequentially:(BOOL)sequential {
    
    if (requests == nil || [requests count] == 0) {
        return;
    }
    
    if (sequential) {
        for (NSUInteger index = 0; index < [requests count] - 1; index++) {
            // get the request to that a sequential request should be performed
            SDLRPCRequest *request = [requests objectAtIndex:index];
            // the next request that has to be performed after the current one
            SDLRPCRequest *next = [requests objectAtIndex:index + 1];
            
            // specify a correlation ID for the request
            [request setCorrelationID:[self nextCorrelationID]];
            
            // use this correlation ID to send the next one
            [[self pendingSequentialRequests] setObject:next forKey:[request correlationID]];
        }
        
        [self sendRequest:[requests objectAtIndex:0]];
        
    } else {
        for (SDLRPCRequest *request in requests) {
            [self sendRequest:request];
        }
    }
}

- (void)closeListInfoType:(InfoType *)infoType {
    [self deleteForecastChoiceSet];
    [self deleteListVoiceCommands:infoType];
    [self deleteListNextVoiceCommand];
    [self deleteListPreviousVoiceCommand];
    
    [self setCurrentInfoType:[InfoType NONE]];
    [self setCurrentInfoTypeList:nil];
    [self setCurrentInfoTypeListIndex:-1];
    
    [self sendWelcomeMessageWithSpeak:NO];
    [self sendWeatherVoiceCommands];
    [self sendDefaultGlobalProperties];
}

- (NSMutableArray *)buildListSoftButtons:(InfoType *)infoType withPrevious:(BOOL)withPrevious withNext:(BOOL)withNext {
    NSMutableArray *buttons = nil;
    
    
    if ([self softButtonsAvailable] > 0) {
        buttons = [NSMutableArray arrayWithCapacity:4];
        
        SDLSoftButton *button = [[SDLSoftButton alloc] init];
        if (withPrevious) {
            [button setSoftButtonID:@(BTNID_LIST_PREVIOUS)];
            [button setText:@"<"];
        } else {
            [button setSoftButtonID:@(BTNID_LIST_INACTIVE)];
            [button setText:@"-"];
        }
        
        [button setType:[SDLSoftButtonType TEXT]];
        [button setSystemAction:[SDLSystemAction DEFAULT_ACTION]];
        [buttons addObject:button];
    }
    
    
    if ([self softButtonsAvailable] > 1) {
        SDLSoftButton *button = [[SDLSoftButton alloc] init];
        if (withNext) {
            [button setSoftButtonID:@(BTNID_LIST_NEXT)];
            [button setText:@">"];
        } else {
            [button setSoftButtonID:@(BTNID_LIST_INACTIVE)];
            [button setText:@"-"];
        }
        
        [button setType:[SDLSoftButtonType TEXT]];
        [button setSystemAction:[SDLSystemAction DEFAULT_ACTION]];
        [buttons addObject:button];
    }
    
    if ([self softButtonsAvailable] > 2) {
        SDLSoftButton *button = [[SDLSoftButton alloc] init];
        if ([[InfoType DAILY_FORECAST] isEqual:infoType] || [[InfoType HOURLY_FORECAST] isEqual:infoType]) {
            [button setSoftButtonID:@(BTNID_LIST_SHOW_LIST)];
            [button setText:@"List"];
        }else if ([[InfoType ALERTS] isEqual:infoType]) {
            [button setSoftButtonID:@(BTNID_LIST_SHOW_MESSAGE)];
            [button setText:@"Message"];
        
        [button setType:[SDLSoftButtonType TEXT]];
        [button setSystemAction:[SDLSystemAction DEFAULT_ACTION]];
        [buttons addObject:button];
        }
    }
    
    if ([self softButtonsAvailable] > 3) {
        SDLSoftButton *button = [[SDLSoftButton alloc] init];
        [button setSoftButtonID:@(BTNID_LIST_BACK)];
        [button setText:@"Back"];
        [button setType:[SDLSoftButtonType TEXT]]; 
        [button setSystemAction:[SDLSystemAction DEFAULT_ACTION]]; 
        [buttons addObject:button]; 
    }
    
    
    return buttons; 
}

- (void)sendListGlobalProperties:(InfoType *)infoType withPrevious:(BOOL)withPrevious withNext:(BOOL)withNext {
    SDLSetGlobalProperties *request = [[SDLSetGlobalProperties alloc] init];
    NSMutableArray *prompts = [NSMutableArray array];
    NSMutableArray *items = [NSMutableArray array];
    SDLVRHelpItem *helpitem;
    NSUInteger position = 1;
    
    if (withPrevious) {
        helpitem = [[SDLVRHelpItem alloc] init];
        [helpitem setPosition:@(position++)];
        [helpitem setText:@"Previous"];
        [items addObject:helpitem];
        [prompts addObject:@"Previous"];
    }
    
    if (withNext) {
        helpitem = [[SDLVRHelpItem alloc] init];
        [helpitem setPosition:@(position++)];
        [helpitem setText:@"Next"];
        [items addObject:helpitem];
        [prompts addObject:@"Next"];
    }
    
    helpitem = [[SDLVRHelpItem alloc] init];
    [helpitem setPosition:@(position++)];
    [helpitem setText:@"Back"];
    [items addObject:helpitem];
    [prompts addObject:@"Back"];
    
    if ([[InfoType DAILY_FORECAST] isEqual:infoType] || [[InfoType HOURLY_FORECAST] isEqual:infoType]) {
        helpitem = [[SDLVRHelpItem alloc] init];
        [helpitem setPosition:@(position++)];
        [helpitem setText:@"Show list"];
        [items addObject:helpitem];
        [prompts addObject:@"Show list"];
    }else if ([[InfoType ALERTS] isEqual:infoType]) {
        helpitem = [[SDLVRHelpItem alloc] init];
        [helpitem setPosition:@(position++)];
        [helpitem setText:@"Show message"];
        [items addObject:helpitem];
        [prompts addObject:@"Show message"];
    }
    
    helpitem = [[SDLVRHelpItem alloc] init];
    [helpitem setPosition:@(position++)];
    [helpitem setText:@"Change units"];
    [items addObject:helpitem];
    [prompts addObject:@"Change units"];
    
    NSString *promptstring = [prompts componentsJoinedByString:@","];
    
    [request setHelpPrompt:[SDLTTSChunkFactory buildTTSChunksFromSimple:promptstring]];
    [request setTimeoutPrompt:[SDLTTSChunkFactory buildTTSChunksFromSimple:promptstring]];
    [request setVrHelpTitle:@"MobileWeather"];
    [request setVrHelp:items];
    [self sendRequest:request]; 
}

- (void)createForecastChoiceSetWithList:(NSArray *)forecasts ofType:(InfoType *)infoType {
    BOOL isHourlyForecast = [infoType isEqual:[InfoType HOURLY_FORECAST]];
    
    NSDateFormatter *dateFormatShow = [[NSDateFormatter alloc] init];
    [dateFormatShow setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    [dateFormatShow setLocale:[[self localization] locale]];
    
    NSDateFormatter *dateFormatSpeak = [[NSDateFormatter alloc] init];
    [dateFormatSpeak setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    [dateFormatSpeak setLocale:[[self localization] locale]];
    
    if (isHourlyForecast) {
        [dateFormatShow setDateFormat:@"MM/d h a"];
        [dateFormatSpeak setDateFormat:@"h a"];
    } else {
        [dateFormatShow setDateFormat:@"EEEE"];
        [dateFormatSpeak setDateFormat:@"EEEE"];
    }
    
    SDLCreateInteractionChoiceSet *request = [[SDLCreateInteractionChoiceSet alloc] init];
    [request setChoiceSet:[NSMutableArray arrayWithCapacity:[forecasts count]]];
    [request setInteractionChoiceSetID:@(CHOICESET_LIST)];
    
    for (Forecast *forecast in forecasts) {
        SDLChoice *choice = [[SDLChoice alloc] init];
        [choice setChoiceID:@(CHOICESET_LIST + [[request choiceSet] count] + 1)];
        [choice setMenuName:[dateFormatShow stringFromDate:[forecast date]]];
        
        [choice setVrCommands:[NSMutableArray array]];
        [[choice vrCommands] addObject:[dateFormatSpeak stringFromDate:[forecast date]]];
        if (isHourlyForecast) {
            if ([[request choiceSet] count] == 0) {
                [[choice vrCommands] addObject:@"Now"];
            }
        } else {
            if ([[request choiceSet] count] == 0) {
                [[choice vrCommands] addObject:@"Today"];
            } else if ([[request choiceSet] count] == 1) {
                [[choice vrCommands] addObject:@"Tomorrow"];
            }
        }
        
        [[request choiceSet] addObject:choice];
    }
    
    NSMutableSet *filenames = [NSMutableSet set];
    
    for (Forecast *forecast in forecasts) {
        SDLChoice *choice = [[SDLChoice alloc] init];
        if ([self graphicsAvailable] && [forecast conditionIcon]) {
            NSString *filename = [forecast conditionIcon];
            SDLImage *image = [[SDLImage alloc] init];
            [image setImageType:[SDLImageType DYNAMIC]];
            [image setValue:filename];
            
            if ([[self currentFiles] containsObject:filename] == NO) {
                [filenames addObject:[forecast conditionIcon]];
            }
            
            [choice setImage:image];
        }
        [choice setChoiceID:@(CHOICESET_LIST + [[request choiceSet] count] + 1)];
        
        [[request choiceSet] addObject:choice];
    }
    
    NSMutableArray *requests = [NSMutableArray arrayWithCapacity:[filenames count] + 1];
    
    for (NSString *filename in filenames) {
        SDLPutFile *putfile = [self buildPutFile:filename ofType:[SDLFileType GRAPHIC_PNG] persistentFile:NO systemFile:NO];
        [requests addObject:putfile];
    }
    
    [requests addObject:request];
    
    [self setCurrentForecastChoices:[request choiceSet]];
    [self sendRequest:request];
}

- (void)deleteForecastChoiceSet {
    SDLDeleteInteractionChoiceSet *request = [[SDLDeleteInteractionChoiceSet alloc] init];
    [request setInteractionChoiceSetID:@(CHOICESET_LIST)];
    [self setCurrentForecastChoices:nil];
    [self sendRequest:request];
}

- (void)performForecastInteractionWithMode:(SDLInteractionMode *)mode {
    SDLPerformInteraction *request = [[SDLPerformInteraction alloc] init];
    
    if ([[self currentInfoType] isEqual:[InfoType DAILY_FORECAST]]) {
        [request setInitialText:@"Select day"];
        [request setInitialPrompt:[SDLTTSChunkFactory buildTTSChunksFromSimple:@"Please select a day of the forecast."]];
        [request setHelpPrompt:[SDLTTSChunkFactory buildTTSChunksFromSimple:@"a day of week, like monday, tuesday, or today, tomorrow"]];
        [request setTimeoutPrompt:[SDLTTSChunkFactory buildTTSChunksFromSimple:@"a day of week, today, tomorrow"]];
    } else if ([[self currentInfoType] isEqual:[InfoType HOURLY_FORECAST]]) {
        [request setInitialText:@"Select hour"];
        [request setInitialPrompt:[SDLTTSChunkFactory buildTTSChunksFromSimple:@"Please select an hour of the forecast."]];
        [request setHelpPrompt:[SDLTTSChunkFactory buildTTSChunksFromSimple:@"an hour, like 11 am, or now"]];
        [request setTimeoutPrompt:[SDLTTSChunkFactory buildTTSChunksFromSimple:@"an hour, now"]];
    }
    
    [request setInteractionChoiceSetIDList:[NSMutableArray arrayWithObject:@(CHOICESET_LIST)]];
    [request setInteractionMode:(mode ? mode : [SDLInteractionMode BOTH])];
    [request setTimeout:@(60000)];
    [self sendRequest:request];
}

- (void)sendAlertAtIndex:(NSUInteger)index fromList:(NSArray *)alerts withSpeak:(BOOL)withSpeak {
    
    //Alert
    Alert *alert = [alerts objectAtIndex:index];
    [[self currentKnownAlerts] addObject:alert];
    
    //Expo
    NSDateFormatter *dateTimeFormatShow = [[NSDateFormatter alloc] init];
    [dateTimeFormatShow setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    [dateTimeFormatShow setLocale:[[self localization] locale]];
    [dateTimeFormatShow setDateFormat:@"MM/d h a"];
    
    NSString *dateTimeStringShow = [dateTimeFormatShow stringFromDate:[alert dateExpires]];
    
    if ([self updateListVoiceCommandsWithNewIndex:index
                                        ofNewList:alerts
                                     withOldIndex:[self currentInfoTypeListIndex]
                                        ofOldList:[self currentInfoTypeList]]) {
        [self sendListGlobalProperties:[InfoType ALERTS]
                          withPrevious:(index != 0)
                              withNext:(index + 1 != [alerts count])];
    }
    
    SDLShow *showRequest = [[SDLShow alloc] init];
    [showRequest setSoftButtons:
     [self buildListSoftButtons:[InfoType ALERTS] withPrevious:(index != 0) withNext:(index + 1 != [alerts count])]];
    
    if ([self textFieldsAvailable] == 1) {
        [showRequest setMainField1:[alert alertTitle]];
        [showRequest setMainField2:@""];
    }
    else {
        [showRequest setMainField1:dateTimeStringShow];
        [showRequest setMainField2:[alert alertTitle]];
    }
    
    [showRequest setMainField3:@""];
    [showRequest setMainField4:@""];
    
    [self sendRequest:showRequest];
    
    if (withSpeak) {
        NSDateFormatter *dateTimeFormatSpeak = [[NSDateFormatter alloc] init];
        [dateTimeFormatSpeak setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
        [dateTimeFormatSpeak setLocale:[[self localization] locale]];
        [dateTimeFormatSpeak setDateFormat:@"d'. of' MMMM, h a"];
        
        NSString *dateTimeStringSpeak = [dateTimeFormatSpeak stringFromDate:[alert dateExpires]];
        
        SDLSpeak *speakRequest = [[SDLSpeak alloc] init];
        NSString *speakString = [NSString stringWithFormat:@"%@ until %@", [alert alertTitle], dateTimeStringSpeak];
        
        [speakRequest setTtsChunks:[SDLTTSChunkFactory buildTTSChunksFromSimple:speakString]];
        [self sendRequest:speakRequest];
    }
}

- (void)sendAlertMessageAtIndex:(NSUInteger)index {
    
    Alert *alert = [[self currentInfoTypeList] objectAtIndex:index];
    
    NSString *description = [alert alertDescription];
    
    if ([description length] > 500) {
        description = [[description substringToIndex:497] stringByAppendingString:@"..."];
    }
    
    SDLScrollableMessage *message = [[SDLScrollableMessage alloc] init];
    [message setScrollableMessageBody:description];
    [message setTimeout:@(60000)];
    
    [self sendRequest:message];
}

- (void)sendAlertList:(NSArray *)alerts withSpeak:(BOOL)withSpeak {
    if (alerts && [alerts count] > 0) {
        NSUInteger index = 0;
        
        if ([[InfoType ALERTS] isEqual:[self currentInfoType]]) {
            Alert *oldAlert = [[self currentInfoTypeList] objectAtIndex:[self currentInfoTypeListIndex]];
            
            for (NSUInteger newindex = 0; newindex < [alerts count]; newindex++) {
                Alert *newAlert = [alerts objectAtIndex:index];
                
                if ([newAlert isEqualToAlert:oldAlert]) {
                    index = newindex;
                    break;
                }
            }
        } else {
            [self deleteWeatherVoiceCommands];
            [self sendListVoiceCommands:[InfoType ALERTS]];
        }
        
        [self sendAlertAtIndex:index fromList:alerts withSpeak:withSpeak];
        
        [self setCurrentInfoType:[InfoType ALERTS]];
        [self setCurrentInfoTypeList:alerts];
        [self setCurrentInfoTypeListIndex:index];
    } else {
        SDLAlert *alertRequest = [[SDLAlert alloc] init];
        [alertRequest setAlertText1:@"No"];
        [alertRequest setAlertText2:@"Alerts"];
        [alertRequest setTtsChunks:
         [SDLTTSChunkFactory buildTTSChunksFromSimple:@"No weather alerts at this time."]];
        [self sendRequest:alertRequest];
    }
}

@end
