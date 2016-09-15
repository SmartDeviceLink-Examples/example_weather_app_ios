//
//  SmartDeviceLinkService.m
//  MobileWeather
//
//  Copyright (c) 2013-2015 Ford. All rights reserved.
//

#import "SmartDeviceLink.h"

#import "SmartDeviceLinkService.h"

#import "Alert.h"
#import "Forecast.h"
#import "Localization.h"
#import "WeatherConditions.h"
#import "TemperatureNumber.h"
#import "WeatherLanguage.h"
#import "WeatherDataManager.h"
#import "InfoType.h"
#import "ImageProcessor.h"
#import "Notifications.h"
#import "PercentageNumber.h"
#import "SpeedNumber.h"


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


NS_ASSUME_NONNULL_BEGIN

@interface SmartDeviceLinkService () <SDLManagerDelegate>

@property SDLManager *manager;

@property (nonatomic, assign) BOOL graphicsAvailable;
@property (nonatomic, assign) NSUInteger textFieldsAvailable;
@property (nonatomic, assign) NSUInteger softButtonsAvailable;
@property (nonatomic, strong, nullable) NSArray *templatesAvailable;
@property (nonatomic, strong, nullable) SDLLanguage *language;
@property (nonatomic, strong, nullable) Localization *localization;
@property (nonatomic, assign, getter=hasFirstHMIFullOccurred) BOOL firstHMIFullOccurred;
@property (nonatomic, strong, nullable) NSMutableDictionary *pendingSequentialRequests;


@property (nonatomic, strong, nullable) InfoType *currentInfoType;
@property (nonatomic, strong, nullable) NSArray  *currentInfoTypeList;
@property (nonatomic, assign) NSInteger currentInfoTypeListIndex;
@property (nonatomic, strong, nullable) NSMutableSet *currentKnownAlerts;
@property (nonatomic, strong, nullable) NSArray *currentForecastChoices;

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
    [self setFirstHMIFullOccurred:NO];
    [self setCurrentKnownAlerts:[NSMutableSet set]];
    [self setCurrentInfoType:nil];
    [self setCurrentInfoTypeList:nil];
    [self setCurrentInfoTypeListIndex:-1];
    [self setCurrentForecastChoices:nil];
    [self setPendingSequentialRequests:[NSMutableDictionary dictionary]];
}

- (void)start {
    [self resetProperties];
    
    // Change which config you need based on if you want to connect to a TDK (default) or a wifi based emulator (debug)
//    SDLLifecycleConfiguration *lifecycleConfig = [SDLLifecycleConfiguration defaultConfigurationWithAppName:@"MobileWeather" appId:@"330533107"];
    SDLLifecycleConfiguration *lifecycleConfig = [SDLLifecycleConfiguration debugConfigurationWithAppName:@"MobileWeather" appId:@"330533107" ipAddress:@"192.168.1.249" port:2776];
    lifecycleConfig.ttsName = [SDLTTSChunkFactory buildTTSChunksFromSimple:NSLocalizedString(@"app.tts-name", nil)];
    lifecycleConfig.voiceRecognitionCommandNames = @[NSLocalizedString(@"app.vr-synonym", nil)];
    lifecycleConfig.appIcon = [SDLArtwork persistentArtworkWithImage:[UIImage imageNamed:@"AppIcon60x60@2x"] name:@"AppIcon" asImageFormat:SDLArtworkImageFormatPNG];
    lifecycleConfig.logFlags = SDLLogOutputConsole;
    
    SDLConfiguration *config = [SDLConfiguration configurationWithLifecycle:lifecycleConfig lockScreen:[SDLLockScreenConfiguration enabledConfiguration]];
    
    self.manager = [[SDLManager alloc] initWithConfiguration:config delegate:self];
    
    // Create a proxy object by simply using the factory class.
    [self.manager startWithReadyHandler:^(BOOL success, NSError * _Nullable error) {
        // are graphics supported?
        [self setGraphicsAvailable:[self.manager.registerResponse.displayCapabilities.graphicSupported boolValue]];
        
        // get the display type
        SDLDisplayType *display = self.manager.registerResponse.displayCapabilities.displayType;
        
        if ([[SDLDisplayType MFD3] isEqualToEnum:display] ||
            [[SDLDisplayType MFD4] isEqualToEnum:display] ||
            [[SDLDisplayType MFD5] isEqualToEnum:display]) {
            // MFDs can show 2 lines of text and 3 soft buttons
            [self setTextFieldsAvailable:2];
            [self setSoftButtonsAvailable:3];
        } else if ([[SDLDisplayType GEN3_8_INCH] isEqualToEnum:display]) {
            // SYNC3 can show 3 lines of text and 6 soft buttons
            [self setTextFieldsAvailable:3];
            [self setSoftButtonsAvailable:6];
        } else if ([[SDLDisplayType CID] isEqualToEnum:display]) {
            // CID can show 2 lines of text but no soft buttons
            [self setTextFieldsAvailable:2];
            [self setSoftButtonsAvailable:0];
        } else {
            // All other can show at minimum 1 line of text
            [self setTextFieldsAvailable:1];
            [self setSoftButtonsAvailable:0];
        }
        
        // get the available templates
        NSMutableArray *templates = self.manager.registerResponse.displayCapabilities.templatesAvailable;
        if ([templates isKindOfClass:[NSMutableArray class]]) {
            [self setTemplatesAvailable:templates];
        } else {
            [self setTemplatesAvailable:[NSMutableArray array]];
        }
        
        // set the app display layout to the non-media template
        [self registerDisplayLayout:@"NON-MEDIA"];
        
        SDLLanguage *language = self.manager.registerResponse.language;
        [self setLanguage:language];
        
        NSString *languageString = [language.value substringToIndex:2];
        NSString *regionString = [language.value substringFromIndex:3];
        [self setLocalization:[Localization localizationForLanguage:languageString forRegion:regionString]];
        
        // inform the app about language change to get new weather data
        WeatherLanguage *wlanguage = [WeatherLanguage elementWithValue:[languageString uppercaseString]];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:MobileWeatherLanguageUpdateNotification object:self userInfo:@{ @"language" : wlanguage }];
        
        // send a change registration
        [self changeRegistration];
        
        // print out the app name for the language
        NSLog(@"%@", [[self localization] stringForKey:@"app.name"]);
    }];
}

- (void)stop {
    [self.manager stop];
}


#pragma mark - SDLManagerDelegate

- (void)managerDidDisconnect {
    [self resetProperties];
}

- (void)hmiLevel:(SDLHMILevel *)oldLevel didChangeToLevel:(SDLHMILevel *)newLevel {
    // check current HMI level of the app
    if ([[SDLHMILevel FULL] isEqualToEnum:newLevel] && !self.hasFirstHMIFullOccurred) {
        [self setFirstHMIFullOccurred:YES];
        // the app is just started by the user. Send everything needed to be done once
        [self sendWelcomeMessageWithSpeak:YES];
        [self sendWeatherVoiceCommands];
        [self sendChangeUnitsVoiceCommand];
        [self subscribeRepeatButton];
        [self sendDefaultGlobalProperties];
        [self createChangeUnitsInteractionChoiceSet];
    }
}


#pragma mark - Sequential Requests

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
            
            // use this correlation ID to send the next one
            [[self pendingSequentialRequests] setObject:next forKey:[request correlationID]];
        }
        
        [self.manager sendRequest:[requests objectAtIndex:0]];
    } else {
        for (SDLRPCRequest *request in requests) {
            [self.manager sendRequest:request];
        }
    }
}

- (void)handleSequentialRequestsForResponse:(SDLRPCResponse *)response {
    if (response) {
        NSNumber *correlationID = [response correlationID];
        SDLRPCRequest *request = [[self pendingSequentialRequests] objectForKey:correlationID];
        if (request) {
            [self.manager sendRequest:request];
        }
    }
}


#pragma mark - Handle Weather Updates

- (void)handleWeatherDataUpdate:(NSNotification *)notification {
    if ([[SDLHMILevel NONE] isEqualToEnum:self.manager.hmiLevel]) {
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
        NSString *chunk = [[self localization] stringForKey:@"weather-alerts.speak", [alert alertTitle], [formatterSpeak stringFromDate:[alert dateExpires]]];
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


#pragma mark - RPC Requests

- (void)registerDisplayLayout:(NSString *)layout {
    if ([[self templatesAvailable] containsObject:layout]) {
        SDLSetDisplayLayout *request = [[SDLSetDisplayLayout alloc] init];
        [request setDisplayLayout:layout];
        [self.manager sendRequest:request];
    }
}

- (void)changeRegistration {
    if ([self language] != nil && [self localization] != nil) {
        SDLChangeRegistration *request = [[SDLChangeRegistration alloc] init];
        [request setLanguage:[self language]];
        [request setHmiDisplayLanguage:[self language]];
        
        [self.manager sendRequest:request];
    }
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
    
    [self.manager sendRequest:request];
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
    
    [self.manager sendRequest:request withResponseHandler:^(SDLPerformInteraction * _Nullable request, SDLPerformInteractionResponse * _Nullable response, NSError * _Nullable error) {
        if (![[response success] boolValue]) {
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
        }
    }];
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
        [dateFormatShow setDateFormat:[[self localization] stringForKey:@"forecast.hourly.choice.show"]];
        [dateFormatSpeak setDateFormat:[[self localization] stringForKey:@"forecast.hourly.choice.speak"]];
    } else {
        [dateFormatShow setDateFormat:[[self localization] stringForKey:@"forecast.daily.choice.show"]];
        [dateFormatSpeak setDateFormat:[[self localization] stringForKey:@"forecast.daily.choice.speak"]];
    }
    
    SDLCreateInteractionChoiceSet *createChoiceSetRequest = [[SDLCreateInteractionChoiceSet alloc] init];
    [createChoiceSetRequest setChoiceSet:[NSMutableArray arrayWithCapacity:[forecasts count]]];
    [createChoiceSetRequest setInteractionChoiceSetID:@(CHOICESET_LIST)];
    
    
    
    NSMutableSet *filenames = [NSMutableSet set];
    
    for (Forecast *forecast in forecasts) {
        SDLChoice *choice = [[SDLChoice alloc] init];
        if ([self graphicsAvailable] && [forecast conditionIcon]) {
            NSString *filename = [forecast conditionIcon];
            SDLImage *image = [[SDLImage alloc] init];
            [image setImageType:[SDLImageType DYNAMIC]];
            [image setValue:filename];
            
            if ([self.manager.fileManager.remoteFileNames containsObject:filename] == NO) {
                [filenames addObject:[forecast conditionIcon]];
            }
            
            [choice setImage:image];
        }

        [choice setChoiceID:@(CHOICESET_LIST + [[createChoiceSetRequest choiceSet] count] + 1)];
        [choice setMenuName:[dateFormatShow stringFromDate:[forecast date]]];
        
        [choice setVrCommands:[NSMutableArray array]];
        [[choice vrCommands] addObject:[dateFormatSpeak stringFromDate:[forecast date]]];
       
        if (isHourlyForecast) {
            if ([[createChoiceSetRequest choiceSet] count] == 0) {
                [[choice vrCommands] addObject:[[self localization] stringForKey:@"vr.now"]];
            }
        } else {
            if ([[createChoiceSetRequest choiceSet] count] == 0) {
                [[choice vrCommands] addObject:[[self localization] stringForKey:@"vr.today"]];
            } else if ([[createChoiceSetRequest choiceSet] count] == 1) {
                [[choice vrCommands] addObject:[[self localization] stringForKey:@"vr.tomorrow"]];
            }
        }
        
        [[createChoiceSetRequest choiceSet] addObject:choice];
    }
    
    dispatch_group_t imageUploadGroup = dispatch_group_create();
    dispatch_group_notify(imageUploadGroup, dispatch_get_main_queue(), ^{
        [self setCurrentForecastChoices:[createChoiceSetRequest choiceSet]];
        [self.manager sendRequest:createChoiceSetRequest];
    });
    
    dispatch_group_enter(imageUploadGroup);
    
    for (NSString *filename in filenames) {
        dispatch_group_enter(imageUploadGroup);
        SDLArtwork *image = [SDLArtwork artworkWithImage:[[ImageProcessor sharedProcessor] imageFromConditionImage:filename] name:filename asImageFormat:SDLArtworkImageFormatPNG];
        [self.manager.fileManager uploadFile:image completionHandler:^(BOOL success, NSUInteger bytesAvailable, NSError * _Nullable error) {
            dispatch_group_leave(imageUploadGroup);
        }];
    }
    
    dispatch_group_leave(imageUploadGroup);
}

- (void)deleteForecastChoiceSet {
    SDLDeleteInteractionChoiceSet *request = [[SDLDeleteInteractionChoiceSet alloc] init];
    [request setInteractionChoiceSetID:@(CHOICESET_LIST)];
    [self setCurrentForecastChoices:nil];
    [self.manager sendRequest:request];
}

- (void)performForecastInteractionWithMode:(SDLInteractionMode *)mode {
    SDLPerformInteraction *request = [[SDLPerformInteraction alloc] init];
    
    if ([[self currentInfoType] isEqual:[InfoType DAILY_FORECAST]]) {
        [request setInitialText:[[self localization] stringForKey:@"pi.daily-forecast.text"]];
        [request setInitialPrompt:[SDLTTSChunkFactory buildTTSChunksFromSimple:[[self localization] stringForKey:@"pi.daily-forecast.initial-prompt"]]];
        [request setHelpPrompt:[SDLTTSChunkFactory buildTTSChunksFromSimple:[[self localization] stringForKey:@"pi.daily-forecast.help-prompt"]]];
        [request setTimeoutPrompt:[SDLTTSChunkFactory buildTTSChunksFromSimple:[[self localization] stringForKey:@"pi.daily-forecast.timeout-prompt"]]];
    } else if ([[self currentInfoType] isEqual:[InfoType HOURLY_FORECAST]]) {
        [request setInitialText:[[self localization] stringForKey:@"pi.hourly-forecast.text"]];
        [request setInitialPrompt:[SDLTTSChunkFactory buildTTSChunksFromSimple:[[self localization] stringForKey:@"pi.hourly-forecast.initial-prompt"]]];
        [request setHelpPrompt:[SDLTTSChunkFactory buildTTSChunksFromSimple:[[self localization] stringForKey:@"pi.hourly-forecast.help-prompt"]]];
        [request setTimeoutPrompt:[SDLTTSChunkFactory buildTTSChunksFromSimple:[[self localization] stringForKey:@"pi.hourly-forecast.timeout-prompt"]]];
    }
    
    [request setInteractionChoiceSetIDList:[NSMutableArray arrayWithObject:@(CHOICESET_LIST)]];
    [request setInteractionMode:(mode ? mode : [SDLInteractionMode BOTH])];
    [request setTimeout:@(60000)];
    
    [self.manager sendRequest:request withResponseHandler:^(SDLPerformInteraction * _Nullable request, SDLPerformInteractionResponse * _Nullable response, NSError * _Nullable error) {
        NSUInteger choiceID = [[response choiceID] unsignedIntegerValue];
        if (![self currentForecastChoices]) {
            return;
        }
        
        for (SDLChoice *choice in [self currentForecastChoices]) {
            NSUInteger listChoiceID = [[choice choiceID] unsignedIntegerValue];
            if (listChoiceID == choiceID) {
                NSUInteger index = listChoiceID - CHOICESET_LIST - 1;
                [self sendForecastAtIndex:index fromList:[self currentInfoTypeList] infoType:[self currentInfoType] withSpeak:YES];
                [self setCurrentInfoTypeListIndex:index];
                break;
            }
        }
    }];
}

- (void)sendWelcomeMessageWithSpeak:(BOOL)withSpeak {
    [self setCurrentInfoType:[InfoType NONE]];
    SDLShow *show = [[SDLShow alloc] init];
    [show setSoftButtons:[self buildDefaultSoftButtons]];
    [show setMainField1:[[self localization] stringForKey:@"show.welcome.field1"]];
    [show setMainField2:[[self localization] stringForKey:@"show.welcome.field2"]];
    [show setMainField3:[[self localization] stringForKey:@"show.welcome.field3"]];
    [show setMainField4:[[self localization] stringForKey:@"show.welcome.field4"]];
    [show setAlignment:[SDLTextAlignment CENTERED]];
    [self.manager sendRequest:show];
    
    if (withSpeak) {
        SDLSpeak *speak = [[SDLSpeak alloc] init];
        [speak setTtsChunks:[SDLTTSChunkFactory buildTTSChunksFromSimple:[[self localization] stringForKey:@"speak.welcome"]]];
        [self.manager sendRequest:speak];
    }
}

- (void)sendShowRequest:(SDLShow *)showRequest withImageNamed:(NSString *)filename {
    // If graphics are available we need to add in the image graphic to the SHOW
    if ([self graphicsAvailable]) {
        SDLImage *image = [[SDLImage alloc] init];
        [image setImageType:[SDLImageType DYNAMIC]];
        [image setValue:filename];
        
        // Check if the file is already on the remote system
        if ([self.manager.fileManager.remoteFileNames containsObject:filename]) {
            [showRequest setGraphic:image];
            [self.manager sendRequest:showRequest];
        } else {
            [self.manager sendRequest:showRequest];
            
            SDLArtwork *artwork = [SDLArtwork artworkWithImage:[[ImageProcessor sharedProcessor] imageFromConditionImage:filename] name:filename asImageFormat:SDLArtworkImageFormatPNG];
            [self.manager.fileManager uploadFile:artwork completionHandler:^(BOOL success, NSUInteger bytesAvailable, NSError * _Nullable error) {
                SDLShow *showImage = [[SDLShow alloc] init];
                [showImage setGraphic:image];
                [self.manager sendRequest:showImage];
            }];
        }
    } else {
        [self.manager sendRequest:showRequest];
    }
}

- (void)sendWeatherConditions:(WeatherConditions *)conditions withSpeak:(BOOL)withSpeak {
    if (conditions != nil) {
        [self setCurrentInfoType:[InfoType WEATHER_CONDITIONS]];
        
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
        
        [self sendShowRequest:showRequest withImageNamed:[conditions conditionIcon]];
        
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
            [self.manager sendRequest:speakRequest];
        }
    }
    else {
        SDLAlert *alertRequest = [[SDLAlert alloc] init];
        [alertRequest setAlertText1:[[self localization] stringForKey:@"alert.no-conditions.field1"]];
        [alertRequest setAlertText2:[[self localization] stringForKey:@"alert.no-conditions.field2"]];
        [alertRequest setTtsChunks:[SDLTTSChunkFactory buildTTSChunksFromSimple:[[self localization] stringForKey:@"alert.no-conditions.prompt"]]];
        [self.manager sendRequest:alertRequest];
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
            [self deleteWeatherVoiceCommands];
            [self sendListVoiceCommands:infoType];
        }

        [self createForecastChoiceSetWithList:forecasts ofType:infoType];
        [self sendForecastAtIndex:index fromList:forecasts infoType:infoType withSpeak:withSpeak];
        
        [self setCurrentInfoType:infoType];
        [self setCurrentInfoTypeList:forecasts];
        [self setCurrentInfoTypeListIndex:index];
    } else {
        SDLAlert *alertRequest = [[SDLAlert alloc] init];
        [alertRequest setAlertText1:[[self localization] stringForKey:@"alert.no-forecast.field1"]];
        [alertRequest setAlertText2:[[self localization] stringForKey:@"alert.no-forecast.field2"]];
        [alertRequest setTtsChunks:[SDLTTSChunkFactory buildTTSChunksFromSimple:[[self localization] stringForKey:@"alert.no-forecast.prompt"]]];
        [self.manager sendRequest:alertRequest];
    }
}

- (void)sendForecastAtIndex:(NSUInteger)index fromList:(NSArray *)forecasts infoType:(InfoType *)infoType withSpeak:(BOOL)withSpeak {
    BOOL isHourlyForecast = [infoType isEqual:[InfoType HOURLY_FORECAST]];
    Forecast *forecast = [forecasts objectAtIndex:index];
    
    NSDateFormatter *dateTimeFormatShow = [[NSDateFormatter alloc] init];
    [dateTimeFormatShow setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    [dateTimeFormatShow setLocale:[[self localization] locale]];
    
    NSDateFormatter *weekDayFormatShow = [[NSDateFormatter alloc] init];
    [weekDayFormatShow setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    [weekDayFormatShow setLocale:[[self localization] locale]];
    
    if (isHourlyForecast) {
        [dateTimeFormatShow setDateFormat:[[self localization] stringForKey:@"forecast.hourly.format.date-time.show"]];
        [weekDayFormatShow setDateFormat:[[self localization] stringForKey:@"forecast.hourly.format.week-day.show"]];
    } else {
        [dateTimeFormatShow setDateFormat:[[self localization] stringForKey:@"forecast.daily.format.date-time.show"]];
        [weekDayFormatShow setDateFormat:[[self localization] stringForKey:@"forecast.daily.format.week-day.show"]];
    }
    
    NSString *conditionTitleShow = [forecast conditionTitle];
    NSString *dateTimeStringShow = [dateTimeFormatShow stringFromDate:[forecast date]];
    NSString *weekDayStringShow = [weekDayFormatShow stringFromDate:[forecast date]];
    
    // get the range for a shortened title.
    NSRange conditionTitleShowShortRange =
    [conditionTitleShow rangeOfString:[[self localization] stringForKey:@"conditions.title.short"]
                              options:NSRegularExpressionSearch|NSCaseInsensitiveSearch];
    
    // have we found a shortened title?
    if (conditionTitleShowShortRange.location != NSNotFound) {
        conditionTitleShow = [conditionTitleShow substringWithRange:conditionTitleShowShortRange];
    }
    
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
        [showRequest setMainField1:[[self localization] stringForKey:@"forecast.hourly.show.field1",
            dateTimeStringShow, conditionTitleShow]];
        
        if ([self textFieldsAvailable] >= 2) {
            [showRequest setMainField2:[[self localization] stringForKey:@"forecast.hourly.show.field2",
                [[forecast temperature] stringValueForUnit:temperatureType shortened:YES localization:[self localization]],
                [[forecast humidity] stringValueForUnit:percentageType shortened:YES localization:[self localization]],
                [[forecast precipitationChance] stringValueForUnit:percentageType shortened:YES localization:[self localization]]]];
        }
    } else {
        [showRequest setMainField1:[[self localization] stringForKey:@"forecast.daily.show.field1",
            weekDayStringShow, conditionTitleShow]];
        
        if ([self textFieldsAvailable] >= 2) {
            [showRequest setMainField2:[[self localization] stringForKey:@"forecast.daily.show.field2",
                [[forecast lowTemperature] doubleValueForUnit:temperatureType],
                [[forecast highTemperature] doubleValueForUnit:temperatureType],
                [[forecast highTemperature] nameForUnit:temperatureType shortened:YES localization:[self localization]],
                [[forecast humidity] stringValueForUnit:percentageType shortened:YES localization:[self localization]],
                [[forecast precipitationChance] stringValueForUnit:percentageType shortened:YES localization:[self localization]]]];
        }
    }

    [self sendShowRequest:showRequest withImageNamed:[forecast conditionIcon]];
    
    if (withSpeak) {
        NSDateFormatter *dateTimeFormatSpeak = [[NSDateFormatter alloc] init];
        [dateTimeFormatSpeak setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
        [dateTimeFormatSpeak setLocale:[[self localization] locale]];
        
        NSDateFormatter *weekDayFormatSpeak = [[NSDateFormatter alloc] init];
        [weekDayFormatSpeak setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
        [weekDayFormatSpeak setLocale:[[self localization] locale]];
        
        if (isHourlyForecast) {
            [dateTimeFormatSpeak setDateFormat:[[self localization] stringForKey:@"forecast.hourly.format.date-time.speak"]];
            [weekDayFormatSpeak setDateFormat:[[self localization] stringForKey:@"forecast.hourly.format.week-day.speak"]];
        } else {
            [dateTimeFormatSpeak setDateFormat:[[self localization] stringForKey:@"forecast.daily.format.date-time.speak"]];
            [weekDayFormatSpeak setDateFormat:[[self localization] stringForKey:@"forecast.daily.format.week-day.speak"]];
        }
        
        NSString *dateTimeStringSpeak = [dateTimeFormatSpeak stringFromDate:[forecast date]];
        NSString *weekDayStringSpeak = [weekDayFormatSpeak stringFromDate:[forecast date]];
        NSString *speakString;
        
        if (isHourlyForecast) {
            speakString = [[self localization] stringForKey:@"forecast.hourly.speak",
                dateTimeStringSpeak,
                [forecast conditionTitle],
                [[forecast temperature] stringValueForUnit:temperatureType shortened:NO localization:[self localization]],
                [[forecast humidity] stringValueForUnit:percentageType shortened:NO localization:[self localization]],
                [[forecast precipitationChance] stringValueForUnit:percentageType shortened:NO localization:[self localization]]];
        } else {
            speakString = [[self localization] stringForKey:@"forecast.daily.speak",
                weekDayStringSpeak,
                [forecast conditionTitle],
                [[forecast lowTemperature] doubleValueForUnit:temperatureType],
                [[forecast highTemperature] doubleValueForUnit:temperatureType],
                [[forecast highTemperature] nameForUnit:temperatureType shortened:NO localization:[self localization]],
                [[forecast humidity] stringValueForUnit:percentageType shortened:NO localization:[self localization]],
                [[forecast precipitationChance] stringValueForUnit:percentageType shortened:NO localization:[self localization]]];
        }
        
        SDLSpeak *speakRequest = [[SDLSpeak alloc] init];
        [speakRequest setTtsChunks:[SDLTTSChunkFactory buildTTSChunksFromSimple:speakString]];
        [self.manager sendRequest:speakRequest];
    }
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
        [alertRequest setAlertText1:[[self localization] stringForKey:@"alert.no-alerts.field1"]];
        [alertRequest setAlertText2:[[self localization] stringForKey:@"alert.no-alerts.field2"]];
        [alertRequest setTtsChunks:[SDLTTSChunkFactory buildTTSChunksFromSimple:[[self localization] stringForKey:@"alert.no-alerts.prompt"]]];
        [self.manager sendRequest:alertRequest];
    }
}

- (void)sendAlertAtIndex:(NSUInteger)index fromList:(NSArray<Alert *> *)alerts withSpeak:(BOOL)withSpeak {
    Alert *alert = alerts[index];
    [[self currentKnownAlerts] addObject:alert];

    NSDateFormatter *dateTimeFormatShow = [[NSDateFormatter alloc] init];
    [dateTimeFormatShow setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    [dateTimeFormatShow setLocale:[[self localization] locale]];
    [dateTimeFormatShow setDateFormat:[[self localization] stringForKey:@"weather-alerts.format.date-time.show"]];
    
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
    
    [self.manager sendRequest:showRequest];
    
    if (withSpeak) {
        NSDateFormatter *dateTimeFormatSpeak = [[NSDateFormatter alloc] init];
        [dateTimeFormatSpeak setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
        [dateTimeFormatSpeak setLocale:[[self localization] locale]];
        [dateTimeFormatSpeak setDateFormat:[[self localization] stringForKey:@"weather-alerts.format.date-time.speak"]];
        
        NSString *dateTimeStringSpeak = [dateTimeFormatSpeak stringFromDate:[alert dateExpires]];
        
        SDLSpeak *speakRequest = [[SDLSpeak alloc] init];
        NSString *speakString = [[self localization] stringForKey:@"weather-alerts.speak", [alert alertTitle], dateTimeStringSpeak];
        
        [speakRequest setTtsChunks:[SDLTTSChunkFactory buildTTSChunksFromSimple:speakString]];
        [self.manager sendRequest:speakRequest];
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
    
    [self.manager sendRequest:message];
}

- (void)closeListInfoType:(InfoType *)infoType {
    if ([[InfoType HOURLY_FORECAST] isEqual:infoType] || [[InfoType DAILY_FORECAST] isEqual:infoType]) {
        [self deleteForecastChoiceSet];
    }
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
    
    __weak typeof(self) weakSelf = self;
    request.handler = ^(SDLRPCNotification *notification) {
        if (![notification isMemberOfClass:[SDLOnButtonPress class]]) {
            return;
        }
        
        [weakSelf repeatWeatherInformation];
    };
    
    [self.manager sendRequest:request];
}

- (NSMutableArray<SDLSoftButton *> *)buildDefaultSoftButtons {
    NSMutableArray<SDLSoftButton *> *buttons = nil;
    __weak typeof(self) weakSelf = self;
    
    if ([self softButtonsAvailable] > 0) {
        buttons = [NSMutableArray array];
        
        SDLSoftButton * button = [[SDLSoftButton alloc] init];
        [button setSoftButtonID:@(BTNID_SHOW_WEATHER_CONDITIONS)];
        [button setText:[[self localization] stringForKey:@"sb.current"]];
        [button setType:[SDLSoftButtonType TEXT]];
        [button setSystemAction:[SDLSystemAction DEFAULT_ACTION]];
        button.handler = ^(SDLRPCNotification *notification) {
            if (![notification isMemberOfClass:[SDLOnButtonPress class]]) {
                return;
            }
            
            [weakSelf sendWeatherConditions:[WeatherDataManager sharedManager].weatherConditions withSpeak:YES];
        };
        
        [buttons addObject:button];
    }
    
    if ([self softButtonsAvailable] > 1) {
        SDLSoftButton *button = [[SDLSoftButton alloc] init];
        [button setSoftButtonID:@(BTNID_SHOW_DAILY_FORECAST)];
        [button setText:[[self localization] stringForKey:@"sb.daily"]];
        [button setType:[SDLSoftButtonType TEXT]];
        [button setSystemAction:[SDLSystemAction DEFAULT_ACTION]];
        button.handler = ^(SDLRPCNotification *notification) {
            if (![notification isMemberOfClass:[SDLOnButtonPress class]]) {
                return;
            }
            
            [weakSelf sendForecastList:[WeatherDataManager sharedManager].dailyForecast infoType:[InfoType DAILY_FORECAST] withSpeak:YES];
        };
        
        [buttons addObject:button];
    }
    
    if ([self softButtonsAvailable] > 2) {
        SDLSoftButton *button = [[SDLSoftButton alloc] init];
        [button setSoftButtonID:@(BTNID_SHOW_HOURLY_FORECAST)];
        [button setText:[[self localization] stringForKey:@"sb.hourly"]];
        [button setType:[SDLSoftButtonType TEXT]];
        [button setSystemAction:[SDLSystemAction DEFAULT_ACTION]];
        button.handler = ^(SDLRPCNotification *notification) {
            if (![notification isMemberOfClass:[SDLOnButtonPress class]]) {
                return;
            }
            
            [weakSelf sendForecastList:[WeatherDataManager sharedManager].hourlyForecast infoType:[InfoType HOURLY_FORECAST] withSpeak:YES];
        };
        
        [buttons addObject:button];
    }
    
    if ([self softButtonsAvailable] > 3) {
        SDLSoftButton *button = [[SDLSoftButton alloc] init];
        [button setSoftButtonID:@(BTNID_SHOW_ALERTS)];
        [button setText:[[self localization] stringForKey:@"sb.alerts"]];
        [button setType:[SDLSoftButtonType TEXT]];
        [button setSystemAction:[SDLSystemAction DEFAULT_ACTION]];
        button.handler = ^(SDLRPCNotification *notification) {
            if (![notification isMemberOfClass:[SDLOnButtonPress class]]) {
                return;
            }
            
            [weakSelf sendAlertList:[WeatherDataManager sharedManager].alerts withSpeak:YES];
        };
        
        [buttons addObject:button];
    }
    
    return buttons;
}

- (NSMutableArray<SDLSoftButton *> *)buildListSoftButtons:(InfoType *)infoType withPrevious:(BOOL)withPrevious withNext:(BOOL)withNext {
    NSMutableArray<SDLSoftButton *> *buttons = nil;
    __weak typeof(self) weakSelf = self;
    
    if ([self softButtonsAvailable] > 0) {
        buttons = [NSMutableArray arrayWithCapacity:4];
        
        SDLSoftButton *button = [[SDLSoftButton alloc] init];
        if (withPrevious) {
            [button setSoftButtonID:@(BTNID_LIST_PREVIOUS)];
            [button setText:@"<"];
            button.handler = ^(SDLRPCNotification *notification) {
                InfoType *infoType = [weakSelf currentInfoType];
                if ([weakSelf currentInfoTypeListIndex] > 0) {
                    NSInteger index = [weakSelf currentInfoTypeListIndex] - 1;
                    if ([infoType isEqual:[InfoType DAILY_FORECAST]] || [infoType isEqual:[InfoType HOURLY_FORECAST]]) {
                        [weakSelf sendForecastAtIndex:index fromList:[weakSelf currentInfoTypeList] infoType:infoType withSpeak:YES];
                    }
                    [weakSelf setCurrentInfoTypeListIndex:index];
                }
            };
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
            button.handler = ^(SDLRPCNotification *notification) {
                if (![notification isMemberOfClass:[SDLOnButtonPress class]]) {
                    return;
                }
                
                InfoType *infoType = [weakSelf currentInfoType];
                if ([weakSelf currentInfoTypeListIndex] + 1 < [[self currentInfoTypeList] count]) {
                    NSInteger index = [self currentInfoTypeListIndex] + 1;
                    if ([infoType isEqual:[InfoType DAILY_FORECAST]] || [infoType isEqual:[InfoType HOURLY_FORECAST]]) {
                        [weakSelf sendForecastAtIndex:index fromList:[weakSelf currentInfoTypeList] infoType:infoType withSpeak:YES];
                    }
                    [weakSelf setCurrentInfoTypeListIndex:index];
                }
            };
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
            [button setText:[[self localization] stringForKey:@"sb.list"]];
            button.handler = ^(SDLRPCNotification *notification) {
                if (![notification isMemberOfClass:[SDLOnButtonPress class]]) {
                    return;
                }
                
                [weakSelf performForecastInteractionWithMode:[SDLInteractionMode MANUAL_ONLY]];
            };
        } else if ([[InfoType ALERTS] isEqual:infoType]) {
            [button setSoftButtonID:@(BTNID_LIST_SHOW_MESSAGE)];
            [button setText:[[self localization] stringForKey:@"sb.message"]];
            button.handler = ^(SDLRPCNotification *notification) {
                if (![notification isMemberOfClass:[SDLOnButtonPress class]]) {
                    return;
                }
                
                [weakSelf sendAlertMessageAtIndex:[weakSelf currentInfoTypeListIndex]];
            };
        }

        [button setType:[SDLSoftButtonType TEXT]];
        [button setSystemAction:[SDLSystemAction DEFAULT_ACTION]];
        [buttons addObject:button];
    }
    
    if ([self softButtonsAvailable] > 3) {
        SDLSoftButton *button = [[SDLSoftButton alloc] init];
        [button setSoftButtonID:@(BTNID_LIST_BACK)];
        [button setText:[[self localization] stringForKey:@"sb.back"]];
        [button setType:[SDLSoftButtonType TEXT]]; 
        [button setSystemAction:[SDLSystemAction DEFAULT_ACTION]];
        button.handler = ^(SDLRPCNotification *notification) {
            if (![notification isMemberOfClass:[SDLOnButtonPress class]]) {
                return;
            }
            
            [weakSelf closeListInfoType:[weakSelf currentInfoType]];
        };
        
        [buttons addObject:button]; 
    }
    
    return buttons; 
}

- (void)sendWeatherVoiceCommands {
    SDLAddCommand *request1 = nil;
    SDLMenuParams *menuparams1 = nil;
    menuparams1 = [[SDLMenuParams alloc] init];
    [menuparams1 setMenuName:[[self localization] stringForKey:@"cmd.current-conditions"]];
    [menuparams1 setPosition:@(1)];
    request1 = [[SDLAddCommand alloc] init];
    [request1 setMenuParams:menuparams1];
    [request1 setCmdID:@(CMDID_SHOW_WEATHER_CONDITIONS)];
    [request1 setVrCommands:[NSMutableArray arrayWithObjects:
        [[self localization] stringForKey:@"vr.current"],
        [[self localization] stringForKey:@"vr.conditions"],
        [[self localization] stringForKey:@"vr.current-conditions"],
        [[self localization] stringForKey:@"vr.show-conditions"],
        [[self localization] stringForKey:@"vr.show-current-conditions"],
        nil]];
    request1.handler = ^(SDLOnCommand *commandNotification) {
        // the user has performed the voice command to see the current conditions.
        [self sendWeatherConditions:[WeatherDataManager sharedManager].weatherConditions withSpeak:YES];
    };
    [self.manager sendRequest:request1];
    
    SDLAddCommand *request2 = nil;
    SDLMenuParams *menuparams2 = nil;
    menuparams2 = [[SDLMenuParams alloc] init];
    [menuparams2 setMenuName:[[self localization] stringForKey:@"cmd.daily-forecast"]];
    [menuparams2 setPosition:@(2)];
    request2 = [[SDLAddCommand alloc] init];
    [request2 setMenuParams:menuparams2];
    [request2 setCmdID:@(CMDID_SHOW_DAILY_FORECAST)];
    [request2 setVrCommands:[NSMutableArray arrayWithObjects:
        [[self localization] stringForKey:@"vr.daily"],
        [[self localization] stringForKey:@"vr.daily-forecast"],
        [[self localization] stringForKey:@"vr.show-daily-forecast"],
        nil]];
    request2.handler = ^(SDLOnCommand *commandNotification) {
        [self sendForecastList:[WeatherDataManager sharedManager].dailyForecast infoType:[InfoType DAILY_FORECAST] withSpeak:YES];
    };
    [self.manager sendRequest:request2];
    
    SDLAddCommand *request3 = nil;
    SDLMenuParams *menuparams3 = nil;
    menuparams3 = [[SDLMenuParams alloc] init];
    [menuparams3 setMenuName:[[self localization] stringForKey:@"cmd.hourly-forecast"]];
    [menuparams3 setPosition:@(3)];
    request3 = [[SDLAddCommand alloc] init];
    [request3 setMenuParams:menuparams3];
    [request3 setCmdID:@(CMDID_SHOW_HOURLY_FORECAST)];
    [request3 setVrCommands:[NSMutableArray arrayWithObjects:
        [[self localization] stringForKey:@"vr.hourly"],
        [[self localization] stringForKey:@"vr.hourly-forecast"],
        [[self localization] stringForKey:@"vr.show-hourly-forecast"],
        nil]];
    request3.handler = ^(SDLOnCommand *commandNotification) {
        [self sendForecastList:[WeatherDataManager sharedManager].hourlyForecast infoType:[InfoType HOURLY_FORECAST] withSpeak:YES];
    };
    [self.manager sendRequest:request3];
    
    SDLAddCommand *request4 = nil;
    SDLMenuParams *menuparams4 = nil;
    menuparams4 = [[SDLMenuParams alloc] init];
    [menuparams4 setMenuName:[[self localization] stringForKey:@"cmd.alerts"]];
    [menuparams4 setPosition:@(4)];
    request4 = [[SDLAddCommand alloc] init];
    [request4 setMenuParams:menuparams4];
    [request4 setCmdID:@(CMDID_SHOW_ALERTS)];
    [request4 setVrCommands:[NSMutableArray arrayWithObjects:
                            [[self localization] stringForKey:@"vr.alerts"],
                            [[self localization] stringForKey:@"vr.show-alerts"],
                            nil]];
    request4.handler = ^(SDLOnCommand *commandNotification) {
        [self sendAlertList:[WeatherDataManager sharedManager].alerts withSpeak:YES];
    };
    [self.manager sendRequest:request4];
}

- (void)deleteWeatherVoiceCommands {
    SDLDeleteCommand *request = nil;
    
    request = [[SDLDeleteCommand alloc] init];
    [request setCmdID:@(CMDID_SHOW_WEATHER_CONDITIONS)];
    [self.manager sendRequest:request];
    
    request = [[SDLDeleteCommand alloc] init];
    [request setCmdID:@(CMDID_SHOW_DAILY_FORECAST)];
    [self.manager sendRequest:request];
    
    request = [[SDLDeleteCommand alloc] init];
    [request setCmdID:@(CMDID_SHOW_HOURLY_FORECAST)];
    [self.manager sendRequest:request];
    
    request = [[SDLDeleteCommand alloc] init];
    [request setCmdID:@(CMDID_SHOW_ALERTS)];
    [self.manager sendRequest:request];
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
    
    __weak typeof(self) weakSelf = self;
    request.handler = ^(SDLOnCommand *commandNotification) {
        // the user has performed the voice command to change the units
        SDLInteractionMode *mode = nil;
        if ([commandNotification.triggerSource isEqualToEnum:[SDLTriggerSource MENU]]) {
            mode = [SDLInteractionMode MANUAL_ONLY];
        } else {
            mode = [SDLInteractionMode BOTH];
        }
        
        [weakSelf performChangeUnitsInteractionWithMode:mode];
    };
    
    [self.manager sendRequest:request];
}

- (void)sendListVoiceCommands:(InfoType *)infoType {
    SDLAddCommand *request;
    SDLMenuParams *menuparams;
    __weak typeof(self) weakSelf = self;
    
    if ([[InfoType DAILY_FORECAST] isEqual:infoType] || [[InfoType HOURLY_FORECAST] isEqual:infoType]) {
        menuparams = [[SDLMenuParams alloc] init];
        [menuparams setMenuName:[[self localization] stringForKey:@"cmd.show-list"]];
        [menuparams setPosition:@(3)];
        request = [[SDLAddCommand alloc] init];
        [request setMenuParams:menuparams];
        [request setCmdID:@(CMDID_LIST_SHOW_LIST)];
        [request setVrCommands:[NSMutableArray arrayWithObjects:
                                [[self localization] stringForKey:@"vr.list"],
                                [[self localization] stringForKey:@"vr.show-list"],
                                nil]];
        request.handler = ^(SDLOnCommand *commandNotification) {
            SDLInteractionMode * mode = nil;
            if ([[SDLTriggerSource MENU] isEqualToEnum:[commandNotification triggerSource]]) {
                mode = [SDLInteractionMode MANUAL_ONLY];
            } else {
                mode = [SDLInteractionMode BOTH];
            }
            [weakSelf performForecastInteractionWithMode:mode];
        };
        
        [self.manager sendRequest:request];
    } else if ([[InfoType ALERTS] isEqual:infoType]) {
        menuparams = [[SDLMenuParams alloc] init];
        [menuparams setMenuName:[[self localization] stringForKey:@"cmd.show-message"]];
        [menuparams setPosition:@(3)];
        request = [[SDLAddCommand alloc] init];
        [request setMenuParams:menuparams];
        [request setCmdID:@(CMDID_LIST_SHOW_MESSAGE)];
        [request setVrCommands:[NSMutableArray arrayWithObjects:
                                [[self localization] stringForKey:@"vr.message"],
                                [[self localization] stringForKey:@"vr.show-message"],
                                nil]];
        request.handler = ^(SDLOnCommand *commandNotification) {
            [weakSelf sendAlertMessageAtIndex:[weakSelf currentInfoTypeListIndex]];
        };
        
        [self.manager sendRequest:request];
    }
    
    menuparams = [[SDLMenuParams alloc] init];
    [menuparams setMenuName:[[self localization] stringForKey:@"cmd.back"]];
    [menuparams setPosition:@(4)];
    request = [[SDLAddCommand alloc] init];
    [request setMenuParams:menuparams];
    [request setCmdID:@(CMDID_LIST_BACK)];
    [request setVrCommands:[NSMutableArray arrayWithObject:[[self localization] stringForKey:@"vr.back"]]];
    request.handler = ^(SDLOnCommand *commandNotification) {
        [weakSelf closeListInfoType:[weakSelf currentInfoType]];
    };
    
    [self.manager sendRequest:request];
    
    if ([[InfoType HOURLY_FORECAST] isEqual:infoType]) {
        request = [[SDLAddCommand alloc] init];
        [request setCmdID:@(CMDID_LIST_HOURLY_NOW)];
        [request setVrCommands:[NSMutableArray arrayWithObject:[[self localization] stringForKey:@"vr.now"]]];
        request.handler = ^(SDLOnCommand *commandNotification) {
            [weakSelf sendForecastAtIndex:0 fromList:[weakSelf currentInfoTypeList] infoType:[weakSelf currentInfoType] withSpeak:YES];
            [weakSelf setCurrentInfoTypeListIndex:0];
        };
        
        [self.manager sendRequest:request];
    } else {
        request = [[SDLAddCommand alloc] init];
        [request setCmdID:@(CMDID_LIST_DAILY_TODAY)];
        [request setVrCommands:[NSMutableArray arrayWithObject:[[self localization] stringForKey:@"vr.today"]]];
        request.handler = ^(SDLOnCommand *commandNotification) {
            [weakSelf sendForecastAtIndex:0 fromList:[weakSelf currentInfoTypeList] infoType:[weakSelf currentInfoType] withSpeak:YES];
            [weakSelf setCurrentInfoTypeListIndex:0];
        };
        [self.manager sendRequest:request];
        
        request = [[SDLAddCommand alloc] init];
        [request setCmdID:@(CMDID_LIST_DAILY_TOMORROW)];
        [request setVrCommands:[NSMutableArray arrayWithObject:[[self localization] stringForKey:@"vr.tomorrow"]]];
        request.handler = ^(SDLOnCommand *commandNotification) {
            [weakSelf sendForecastAtIndex:1 fromList:[weakSelf currentInfoTypeList] infoType:[weakSelf currentInfoType] withSpeak:YES];
            [weakSelf setCurrentInfoTypeListIndex:1];
        };
        [self.manager sendRequest:request];
    }
}

- (void)deleteListVoiceCommands:(InfoType *)infoType {
    SDLDeleteCommand *request;
    
    if ([[InfoType DAILY_FORECAST] isEqual:infoType] || [[InfoType HOURLY_FORECAST] isEqual:infoType]) {
        request = [[SDLDeleteCommand alloc] init];
        [request setCmdID:@(CMDID_LIST_SHOW_LIST)];
        [self.manager sendRequest:request];
    } else if ([[InfoType ALERTS] isEqual:infoType]) {
        request = [[SDLDeleteCommand alloc] init];
        [request setCmdID:@(CMDID_LIST_SHOW_MESSAGE)];
        [self.manager sendRequest:request];
    }
    
    request = [[SDLDeleteCommand alloc] init];
    [request setCmdID:@(CMDID_LIST_BACK)];
    [self.manager sendRequest:request];
    
    if ([infoType isEqual:[InfoType HOURLY_FORECAST]]) {
        request = [[SDLDeleteCommand alloc] init];
        [request setCmdID:@(CMDID_LIST_HOURLY_NOW)];
        [self.manager sendRequest:request];
    } else {
        request = [[SDLDeleteCommand alloc] init];
        [request setCmdID:@(CMDID_LIST_DAILY_TODAY)];
        [self.manager sendRequest:request];
        
        request = [[SDLDeleteCommand alloc] init];
        [request setCmdID:@(CMDID_LIST_DAILY_TOMORROW)];
        [self.manager sendRequest:request];
    }
}

- (void)sendListNextVoiceCommand {
    SDLMenuParams *menuparams = [[SDLMenuParams alloc] init];
    [menuparams setMenuName:[[self localization] stringForKey:@"cmd.next"]];
    [menuparams setPosition:@(1)];
    SDLAddCommand *request = [[SDLAddCommand alloc] init];
    [request setMenuParams:menuparams];
    [request setCmdID:@(CMDID_LIST_NEXT)];
    [request setVrCommands:[NSMutableArray arrayWithObject:[[self localization] stringForKey:@"vr.next"]]];
    
    __weak typeof(self) weakSelf = self;
    request.handler = ^(SDLOnCommand *commandNotification) {
        typeof(self) strongSelf = weakSelf;
        
        InfoType *infoType = [strongSelf currentInfoType];
        if ([strongSelf currentInfoTypeListIndex] + 1 < [[strongSelf currentInfoTypeList] count]) {
            NSInteger index = [self currentInfoTypeListIndex] + 1;
            if ([infoType isEqual:[InfoType DAILY_FORECAST]] || [infoType isEqual:[InfoType HOURLY_FORECAST]]) {
                [strongSelf sendForecastAtIndex:index fromList:[strongSelf currentInfoTypeList] infoType:infoType withSpeak:YES];
            } else if ([infoType isEqual:[InfoType ALERTS]]) {
                [strongSelf sendAlertAtIndex:index fromList:[strongSelf currentInfoTypeList] withSpeak:YES];
            }
            [strongSelf setCurrentInfoTypeListIndex:index];
        }
    };
    
    [self.manager sendRequest:request];
}

- (void)deleteListNextVoiceCommand {
    SDLDeleteCommand *request = [[SDLDeleteCommand alloc] init];
    [request setCmdID:@(CMDID_LIST_NEXT)];
    [self.manager sendRequest:request];
}

- (void)sendListPreviousVoiceCommand {
    SDLMenuParams *menuparams = [[SDLMenuParams alloc] init];
    [menuparams setMenuName:[[self localization] stringForKey:@"cmd.previous"]];
    [menuparams setPosition:@(2)];
    SDLAddCommand *request = [[SDLAddCommand alloc] init];
    [request setMenuParams:menuparams];
    [request setCmdID:@(CMDID_LIST_PREVIOUS)];
    [request setVrCommands:[NSMutableArray arrayWithObject:[[self localization] stringForKey:@"vr.previous"]]];
    
    __weak typeof(self) weakSelf = self;
    request.handler = ^(SDLOnCommand *commandNotification) {
        typeof(self) strongSelf = weakSelf;
        
        InfoType *infoType = [self currentInfoType];
        if ([strongSelf currentInfoTypeListIndex] > 0) {
            NSInteger index = [strongSelf currentInfoTypeListIndex] - 1;
            if ([infoType isEqual:[InfoType DAILY_FORECAST]] || [infoType isEqual:[InfoType HOURLY_FORECAST]]) {
                [strongSelf sendForecastAtIndex:index fromList:[strongSelf currentInfoTypeList] infoType:infoType withSpeak:YES];
            } else if ([infoType isEqual:[InfoType ALERTS]]) {
                [strongSelf sendAlertAtIndex:index fromList:[strongSelf currentInfoTypeList] withSpeak:YES];
            }
            [strongSelf setCurrentInfoTypeListIndex:index];
        }
    };
    
    [self.manager sendRequest:request];
}

- (void)deleteListPreviousVoiceCommand {
    SDLDeleteCommand *request = [[SDLDeleteCommand alloc] init];
    [request setCmdID:@(CMDID_LIST_PREVIOUS)];
    [self.manager sendRequest:request];
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
    [helpitem setText:[[self localization] stringForKey:@"cmd.daily-forecast"]];
    [helpitems addObject:helpitem];
    [prompts addObject:[[self localization] stringForKey:@"vr.daily-forecast"]];
    
    helpitem = [[SDLVRHelpItem alloc] init];
    [helpitem setPosition:@(3)];
    [helpitem setText:[[self localization] stringForKey:@"cmd.hourly-forecast"]];
    [helpitems addObject:helpitem];
    [prompts addObject:[[self localization] stringForKey:@"vr.hourly-forecast"]];
    
    helpitem = [[SDLVRHelpItem alloc] init];
    [helpitem setPosition:@(4)];
    [helpitem setText:[[self localization] stringForKey:@"cmd.change-units"]];
    [helpitems addObject:helpitem];
    [prompts addObject:[[self localization] stringForKey:@"vr.change-units"]];
    
    NSString *promptstring = [prompts componentsJoinedByString:@","];
    
    [request setHelpPrompt:[SDLTTSChunkFactory buildTTSChunksFromSimple:promptstring]];
    [request setTimeoutPrompt:[SDLTTSChunkFactory buildTTSChunksFromSimple:promptstring]];
    [request setVrHelpTitle:[[self localization] stringForKey:@"app.name"]];
    [request setVrHelp:helpitems];
    
    [self.manager sendRequest:request];
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
        [helpitem setText:[[self localization] stringForKey:@"cmd.previous"]];
        [items addObject:helpitem];
        [prompts addObject:[[self localization] stringForKey:@"vr.previous"]];
    }
    
    if (withNext) {
        helpitem = [[SDLVRHelpItem alloc] init];
        [helpitem setPosition:@(position++)];
        [helpitem setText:[[self localization] stringForKey:@"cmd.next"]];
        [items addObject:helpitem];
        [prompts addObject:[[self localization] stringForKey:@"vr.next"]];
    }
    
    helpitem = [[SDLVRHelpItem alloc] init];
    [helpitem setPosition:@(position++)];
    [helpitem setText:[[self localization] stringForKey:@"cmd.back"]];
    [items addObject:helpitem];
    [prompts addObject:[[self localization] stringForKey:@"vr.back"]];
    
    if ([[InfoType DAILY_FORECAST] isEqual:infoType] || [[InfoType HOURLY_FORECAST] isEqual:infoType]) {
        helpitem = [[SDLVRHelpItem alloc] init];
        [helpitem setPosition:@(position++)];
        [helpitem setText:[[self localization] stringForKey:@"cmd.show-list"]];
        [items addObject:helpitem];
        [prompts addObject:[[self localization] stringForKey:@"vr.show-list"]];
    } else if ([[InfoType ALERTS] isEqual:infoType]) {
        helpitem = [[SDLVRHelpItem alloc] init];
        [helpitem setPosition:@(position++)];
        [helpitem setText:[[self localization] stringForKey:@"cmd.show-message"]];
        [items addObject:helpitem];
        [prompts addObject:[[self localization] stringForKey:@"vr.show-message"]];
    }
    
    helpitem = [[SDLVRHelpItem alloc] init];
    [helpitem setPosition:@(position++)];
    [helpitem setText:[[self localization] stringForKey:@"cmd.change-units"]];
    [items addObject:helpitem];
    [prompts addObject:[[self localization] stringForKey:@"vr.change-units"]];
    
    NSString *promptstring = [prompts componentsJoinedByString:@","];
    
    [request setHelpPrompt:[SDLTTSChunkFactory buildTTSChunksFromSimple:promptstring]];
    [request setTimeoutPrompt:[SDLTTSChunkFactory buildTTSChunksFromSimple:promptstring]];
    [request setVrHelpTitle:[[self localization] stringForKey:@"app.name"]];
    [request setVrHelp:items];
    [self.manager sendRequest:request]; 
}

@end

NS_ASSUME_NONNULL_END
