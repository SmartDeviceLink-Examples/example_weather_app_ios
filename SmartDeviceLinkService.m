//
//  SmartDeviceLinkService.m
//  MobileWeather
//
//  Copyright (c) 2013-2015 Ford. All rights reserved.
//

@import SmartDeviceLink;

#import "SmartDeviceLinkService.h"

#import "Alert.h"
#import "Forecast.h"
#import "Localization.h"
#import "WeatherConditions.h"
#import "TemperatureNumber.h"
#import "WeatherLanguage.h"
#import "WeatherDataManager.h"
#import "ImageProcessor.h"
#import "Notifications.h"
#import "PercentageNumber.h"
#import "SpeedNumber.h"

typedef NS_ENUM(UInt32, MWChoiceSetId) {
    MWChoiceSetIdChangeUnits = 300,
    MWChoiceSetIdList = 400
};

typedef NS_ENUM(UInt16, MWChoiceSetChangeUnitChoiceId) {
    MWChoiceSetChangeUnitChoiceIdMetric = 301,
    MWChoiceSetChangeUnitChoiceIdImperial = 302
};

typedef NS_ENUM(UInt16, MWMenuCommandIdShow) {
    MWMenuCommandIdShowWeatherConditions = 101,
    MWMenuCommandIdShowDailyForecast = 102,
    MWMenuCommandIdShowHourlyForecast = 103,
    MWMenuCommandIdShowAlerts = 104,
    MWMenuCommandIdShowChangeUnits = 105
};

typedef NS_ENUM(NSUInteger, MWMenuCommandIdList) {
    MWMenuCommandIdListNext = 111,
    MWMenuCommandIdListPrevious = 112,
    MWMenuCommandIdListShowList = 113,
    MWMenuCommandIdListBack = 114,
    MWMenuCommandIdListHourlyNow = 115,
    MWMenuCommandIdListDailyToday = 116,
    MWMenuCommandIdListDailyTomorrow = 117,
    MWMenuCommandIdListShowMessage = 118
};

MWInfoType const MWInfoTypeNone = @"NONE";
MWInfoType const MWInfoTypeWeatherConditions = @"WEATHER_CONDITIONS";
MWInfoType const MWInfoTypeDailyForecast = @"DAILY_FORECAST";
MWInfoType const MWInfoTypeHourlyForecast = @"HOURLY_FORECAST";
MWInfoType const MWInfoTypeAlerts = @"ALERTS";


NS_ASSUME_NONNULL_BEGIN

@interface SmartDeviceLinkService () <SDLManagerDelegate>

@property SDLManager *manager;

@property (nonatomic, assign) BOOL graphicsAvailable;
@property (nonatomic, assign) NSUInteger textFieldsAvailable;
@property (nonatomic, assign) NSUInteger softButtonsAvailable;
@property (nonatomic, strong, nullable) NSArray *templatesAvailable;
@property (nonatomic, strong, nullable) SDLLanguage language;
@property (nonatomic, strong, nullable) Localization *localization;
@property (nonatomic, assign, getter=hasFirstHMIFullOccurred) BOOL firstHMIFullOccurred;


@property (nonatomic, strong, nullable) MWInfoType currentInfoType;
@property (nonatomic, strong, nullable) NSArray  *currentInfoTypeList;
@property (nonatomic, assign) NSInteger currentInfoTypeListIndex;
@property (nonatomic, strong, nullable) NSMutableSet *currentKnownAlerts;
@property (nonatomic, strong, nullable) NSArray *currentForecastChoices;

@end

@implementation SmartDeviceLinkService

+ (SmartDeviceLinkService*)sharedService {
    static id shared = nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{ shared = [[self alloc] init]; });
    return shared;
}

- (void)resetProperties {
    self.graphicsAvailable = NO;
    self.templatesAvailable = nil;
    self.language = nil;
    self.localization = nil;
    self.firstHMIFullOccurred = NO;
    self.currentKnownAlerts = [NSMutableSet set];
    self.currentInfoType = nil;
    self.currentInfoTypeList = nil;
    self.currentInfoTypeListIndex = -1;
    self.currentForecastChoices = nil;
}

- (void)start {
    [self resetProperties];
    
    // Change which config you need based on if you want to connect to a TDK (default) or a wifi based emulator (debug)
    SDLLifecycleConfiguration *lifecycleConfig = [SDLLifecycleConfiguration defaultConfigurationWithAppName:@"MobileWeather" appId:@"330533107"];
//    SDLLifecycleConfiguration *lifecycleConfig = [SDLLifecycleConfiguration debugConfigurationWithAppName:@"MobileWeather" appId:@"330533107" ipAddress:@"192.168.1.61" port:2776];
    lifecycleConfig.ttsName = [SDLTTSChunk textChunksFromString:NSLocalizedString(@"app.tts-name", nil)];
    lifecycleConfig.voiceRecognitionCommandNames = @[NSLocalizedString(@"app.vr-synonym", nil)];
    lifecycleConfig.appIcon = [SDLArtwork persistentArtworkWithImage:[UIImage imageNamed:@"sdl-appicon"] name:@"AppIcon" asImageFormat:SDLArtworkImageFormatPNG];
    lifecycleConfig.language = SDLLanguageEnUs;
    lifecycleConfig.languagesSupported = @[SDLLanguageEnUs, SDLLanguageEnGb, SDLLanguageEnAu, SDLLanguageDeDe, SDLLanguageEsEs, SDLLanguageEsMx, SDLLanguagePtPt, SDLLanguagePtBr, SDLLanguageFrFr, SDLLanguageFrCa];

    // inform the app about language change to get new weather data
    NSString *languageString = [SDLLanguageEnUs substringWithRange:NSMakeRange(0, 2)].uppercaseString;
    WeatherLanguage *wlanguage = [WeatherLanguage elementWithValue:languageString];
    [[NSNotificationCenter defaultCenter] postNotificationName:MobileWeatherLanguageUpdateNotification object:self userInfo:@{ @"language" : wlanguage }];
    
    SDLConfiguration *config = [SDLConfiguration configurationWithLifecycle:lifecycleConfig lockScreen:[SDLLockScreenConfiguration enabledConfiguration] logging:[SDLLogConfiguration debugConfiguration]];
    
    self.manager = [[SDLManager alloc] initWithConfiguration:config delegate:self];
    
    // Create a proxy object by simply using the factory class.
    [self.manager startWithReadyHandler:^(BOOL success, NSError * _Nullable error) {
        // are graphics supported?
        self.graphicsAvailable = (self.manager.registerResponse.displayCapabilities.graphicSupported).boolValue;
        
        // get the available templates
        self.templatesAvailable = self.manager.registerResponse.displayCapabilities.templatesAvailable;
        
        // set the app display layout to the non-media template
        [self registerDisplayLayout:SDLPredefinedLayoutNonMedia];
        
        // print out the app name for the language
        SDLLogD(@"%@", self.localization[@"app.name"]);
    }];
}

- (void)stop {
    [self.manager stop];
}


#pragma mark - SDLManagerDelegate

- (void)managerDidDisconnect {
    [self resetProperties];
}

- (void)hmiLevel:(SDLHMILevel)oldLevel didChangeToLevel:(SDLHMILevel)newLevel {
    // check current HMI level of the app
    if ([SDLHMILevelFull isEqualToEnum:newLevel] && !self.hasFirstHMIFullOccurred) {
        self.firstHMIFullOccurred = YES;
        // the app is just started by the user. Send everything needed to be done once
        [self sendWelcomeMessageWithSpeak:YES];
        [self sendWeatherVoiceCommands];
        [self sendChangeUnitsVoiceCommand];
        [self subscribeRepeatButton];
        [self sendDefaultGlobalProperties];
        [self createChangeUnitsInteractionChoiceSet];
    }
}

- (nullable SDLLifecycleConfigurationUpdate *)managerShouldUpdateLifecycleToLanguage:(SDLLanguage)language {
    self.language = language;

    NSString *languageString = [self.language substringToIndex:2];
    NSString *regionString = [self.language substringFromIndex:3];
    self.localization = [Localization localizationForLanguage:languageString forRegion:regionString];

    WeatherLanguage *wlanguage = [WeatherLanguage elementWithValue:languageString.uppercaseString];
    [[NSNotificationCenter defaultCenter] postNotificationName:MobileWeatherLanguageUpdateNotification object:self userInfo:@{ @"language" : wlanguage }];

    SDLLifecycleConfigurationUpdate *update = [[SDLLifecycleConfigurationUpdate alloc] initWithAppName:self.localization[@"app.name"] shortAppName:self.localization[@"app.name"] ttsName:[SDLTTSChunk textChunksFromString:self.localization[@"app.tts-name"]] voiceRecognitionCommandNames:@[self.localization[@"app.vr-synonym"]]];

    return update;
}


#pragma mark - Handle Weather Updates

- (void)handleWeatherDataUpdate:(NSNotification *)notification {
    if ([SDLHMILevelNone isEqualToEnum:self.manager.hmiLevel]) {
        return;
    }
    
    // get alerts and move forward if the array is not empty
    NSArray *alerts = notification.userInfo[@"alerts"];
    if (alerts == nil && alerts.count == 0) {
        return;
    }
    
    // get copies of mutable sets for known and unknown weather alerts
    NSMutableSet *known = [NSMutableSet setWithSet:self.currentKnownAlerts];
    NSMutableSet *unknown = [NSMutableSet setWithArray:alerts];
    // remove all alerts already known
    [unknown minusSet:known];
    // move forward only if we have unknown weather alerts
    if (unknown.count == 0) {
        return;
    }
    
    NSDateFormatter *formatterShow = [[NSDateFormatter alloc] init];
    formatterShow.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    formatterShow.locale = self.localization.locale;
    formatterShow.dateFormat = self.localization[@"weather-alerts.format.date-time.show"];
    
    NSDateFormatter *formatterSpeak = [[NSDateFormatter alloc] init];
    formatterSpeak.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    formatterSpeak.locale = self.localization.locale;
    formatterSpeak.dateFormat = self.localization[@"weather-alerts.format.date-time.speak"];
    
    NSSortDescriptor *sorter = [NSSortDescriptor sortDescriptorWithKey:@"dateExpires" ascending:NO];
    NSArray *unknownSorted = [unknown sortedArrayUsingDescriptors:@[sorter]];
    NSMutableArray *requests = [NSMutableArray arrayWithCapacity:unknownSorted.count];
    
    for (Alert *alert in unknownSorted) {
        NSString *chunk = [self.localization stringForKey:@"weather-alerts.speak", alert.title, [formatterSpeak stringFromDate:alert.dateExpires]];
        NSArray *chunks = [SDLTTSChunk textChunksFromString:chunk];
        
        // create an alert request
        SDLAlert *request = [[SDLAlert alloc] initWithAlertText1:alert.title alertText2:[formatterShow stringFromDate:alert.dateExpires] duration:10000];
        request.ttsChunks = chunks;
        [requests addObject:request];
    }

    [self.manager sendSequentialRequests:requests progressHandler:nil completionHandler:nil];
    [self.currentKnownAlerts unionSet:unknown];
    
    MWInfoType infoType = self.currentInfoType;
    if ([MWInfoTypeWeatherConditions isEqualToString:infoType]) {
        WeatherConditions *conditions = notification.userInfo[@"weatherConditions"];
        [self sendWeatherConditions:conditions withSpeak:NO];
    } else if ([MWInfoTypeDailyForecast isEqualToString:infoType]) {
        NSArray *forecast = notification.userInfo[@"dailyForecast"];
        [self sendForecastList:forecast infoType:infoType withSpeak:NO];
    } else if ([MWInfoTypeHourlyForecast isEqualToString:infoType]) {
        NSArray *forecast = notification.userInfo[@"hourlyForecast"];
        [self sendForecastList:forecast infoType:infoType withSpeak:NO];
    } else if ([MWInfoTypeAlerts isEqualToString:infoType]) {
        NSArray *alerts = notification.userInfo[@"alerts"];
        [self sendAlertList:alerts withSpeak:NO];
    }
}


#pragma mark - RPC Requests

- (void)registerDisplayLayout:(NSString *)layout {
    SDLSetDisplayLayout *request = [[SDLSetDisplayLayout alloc] initWithLayout:layout];
    [self.manager sendRequest:request];
}

- (void)createChangeUnitsInteractionChoiceSet {
    SDLChoice *metricChoice = [[SDLChoice alloc] initWithId:MWChoiceSetChangeUnitChoiceIdMetric menuName:self.localization[@"choice.units.metric"] vrCommands:@[self.localization[@"vr.metric"]]];
    SDLChoice *imperialChoice = [[SDLChoice alloc] initWithId:MWChoiceSetChangeUnitChoiceIdImperial menuName:self.localization[@"choice.units.imperial"] vrCommands:@[self.localization[@"vr.imperial"]]];

    SDLCreateInteractionChoiceSet *request = [[SDLCreateInteractionChoiceSet alloc] initWithId:MWChoiceSetIdChangeUnits choiceSet:@[metricChoice, imperialChoice]];
    [self.manager sendRequest:request];
}

- (void)performChangeUnitsInteractionWithMode:(SDLInteractionMode)mode {
    SDLPerformInteraction *request = [[SDLPerformInteraction alloc] initWithInitialPrompt:self.localization[@"pi.units.initial-prompt"] initialText:self.localization[@"pi.units.text"] interactionChoiceSetIDList:@[@(MWChoiceSetIdChangeUnits)] helpPrompt:nil timeoutPrompt:self.localization[@"pi.units.timeout-prompt"] interactionMode:(mode ?: SDLInteractionModeBoth) timeout:60000];
    
    [self.manager sendRequest:request withResponseHandler:^(SDLPerformInteraction * _Nullable request, SDLPerformInteractionResponse * _Nullable response, NSError * _Nullable error) {
        if (!response.success.boolValue) {
            return;
        }
        
        NSUInteger choiceID = response.choiceID.unsignedIntegerValue;
        if (choiceID != MWChoiceSetChangeUnitChoiceIdImperial && choiceID != MWChoiceSetChangeUnitChoiceIdMetric) {
            return;
        }

        UnitType unit = (choiceID == MWChoiceSetChangeUnitChoiceIdImperial) ? UnitTypeImperial : UnitTypeMetric;
        [WeatherDataManager sharedManager].unit = unit;
    }];
}

- (void)createForecastChoiceSetWithList:(NSArray *)forecasts ofType:(MWInfoType)infoType {
    BOOL isHourlyForecast = [infoType isEqualToString:MWInfoTypeHourlyForecast];
    
    NSDateFormatter *dateFormatShow = [[NSDateFormatter alloc] init];
    dateFormatShow.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    dateFormatShow.locale = self.localization.locale;
    
    NSDateFormatter *dateFormatSpeak = [[NSDateFormatter alloc] init];
    dateFormatSpeak.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    dateFormatSpeak.locale = self.localization.locale;
    
    if (isHourlyForecast) {
        dateFormatShow.dateFormat = self.localization[@"forecast.hourly.choice.show"];
        dateFormatSpeak.dateFormat = self.localization[@"forecast.hourly.choice.speak"];
    } else {
        dateFormatShow.dateFormat = self.localization[@"forecast.daily.choice.show"];
        dateFormatSpeak.dateFormat = self.localization[@"forecast.daily.choice.speak"];
    }
    
    SDLCreateInteractionChoiceSet *createChoiceSetRequest = [[SDLCreateInteractionChoiceSet alloc] init];
    createChoiceSetRequest.interactionChoiceSetID = @(MWChoiceSetIdList);

    NSMutableSet *filenames = [NSMutableSet set];
    NSMutableArray *choices = [NSMutableArray array];
    for (Forecast *forecast in forecasts) {
        SDLChoice *choice = [[SDLChoice alloc] init];
        if (self.graphicsAvailable && forecast.conditionIcon != nil) {
            NSString *filename = forecast.conditionIcon;
            SDLImage *image = [[SDLImage alloc] initWithName:filename];
            
            if ([self.manager.fileManager.remoteFileNames containsObject:filename] == NO) {
                [filenames addObject:forecast.conditionIcon];
            }

            choice.image = image;
        }

        choice.choiceID = @(MWChoiceSetIdList + choices.count + 1);
        choice.menuName = [dateFormatShow stringFromDate:forecast.date];

        NSMutableArray *vrCommands = [NSMutableArray array];
        [vrCommands addObject:[dateFormatSpeak stringFromDate:forecast.date]];
       
        if (isHourlyForecast && choices.count == 0) {
            [vrCommands addObject:self.localization[@"vr.now"]];
        } else {
            if (choices.count == 0) {
                [vrCommands addObject:self.localization[@"vr.today"]];
            } else if (choices.count == 1) {
                [vrCommands addObject:self.localization[@"vr.tomorrow"]];
            }
        }

        choice.vrCommands = [vrCommands copy];
        [choices addObject:choice];
    }

    createChoiceSetRequest.choiceSet = [choices copy];

    NSMutableArray *artworks = [NSMutableArray array];
    for (NSString *filename in filenames) {
        [artworks addObject:[SDLArtwork artworkWithImage:[[ImageProcessor sharedProcessor] imageFromConditionImage:filename] name:filename asImageFormat:SDLArtworkImageFormatPNG]];
    }

    if (artworks.count > 0) {
        __weak typeof(self) weakSelf = self;
        [self.manager.fileManager uploadArtworks:artworks progressHandler:nil completionHandler:^(NSArray<NSString *> * _Nonnull artworkNames, NSError * _Nullable error) {
            weakSelf.currentForecastChoices = createChoiceSetRequest.choiceSet;
            [weakSelf.manager sendRequest:createChoiceSetRequest];
        }];
    }
}

- (void)deleteForecastChoiceSet {
    SDLDeleteInteractionChoiceSet *request = [[SDLDeleteInteractionChoiceSet alloc] initWithId:MWChoiceSetIdList];
    self.currentForecastChoices = nil;
    [self.manager sendRequest:request];
}

- (void)performForecastInteractionWithMode:(SDLInteractionMode)mode {
    SDLPerformInteraction *request = nil;
    
    if ([self.currentInfoType isEqualToString:MWInfoTypeDailyForecast]) {
        request = [[SDLPerformInteraction alloc] initWithInitialPrompt:self.localization[@"pi.daily-forecast.initial-prompt"] initialText:self.localization[@"pi.daily-forecast.text"] interactionChoiceSetIDList:@[@(MWChoiceSetIdList)] helpPrompt:self.localization[@"pi.daily-forecast.help-prompt"] timeoutPrompt:self.localization[@"pi.daily-forecast.timeout-prompt"] interactionMode:(mode ?: SDLInteractionModeBoth) timeout:60000];
    } else if ([self.currentInfoType isEqualToString:MWInfoTypeHourlyForecast]) {
        request = [[SDLPerformInteraction alloc] initWithInitialPrompt:self.localization[@"pi.hourly-forecast.initial-prompt"] initialText:self.localization[@"pi.hourly-forecast.text"] interactionChoiceSetIDList:@[@(MWChoiceSetIdList)] helpPrompt:self.localization[@"pi.hourly-forecast.help-prompt"] timeoutPrompt:self.localization[@"pi.hourly-forecast.timeout-prompt"] interactionMode:(mode ?: SDLInteractionModeBoth) timeout:60000];
    }
    
    [self.manager sendRequest:request withResponseHandler:^(SDLPerformInteraction * _Nullable request, SDLPerformInteractionResponse * _Nullable response, NSError * _Nullable error) {
        NSUInteger choiceID = response.choiceID.unsignedIntegerValue;
        if (self.currentForecastChoices == nil) { return; }
        
        for (SDLChoice *choice in self.currentForecastChoices) {
            NSUInteger listChoiceID = choice.choiceID.unsignedIntegerValue;
            if (listChoiceID == choiceID) {
                NSUInteger index = listChoiceID - MWChoiceSetIdList - 1;
                [self sendForecastAtIndex:index fromList:self.currentInfoTypeList infoType:self.currentInfoType withSpeak:YES];
                self.currentInfoTypeListIndex = index;
                break;
            }
        }
    }];
}

- (void)sendWelcomeMessageWithSpeak:(BOOL)withSpeak {
    self.currentInfoType = MWInfoTypeNone;
    [self.manager.screenManager beginUpdates];
    self.manager.screenManager.textField1 = self.localization[@"show.welcome.field1"];
    self.manager.screenManager.textField2 = self.localization[@"show.welcome.field2"];
    self.manager.screenManager.textField3 = self.localization[@"show.welcome.field3"];
    self.manager.screenManager.textField4 = self.localization[@"show.welcome.field4"];
    self.manager.screenManager.textAlignment = SDLTextAlignmentCenter;
    self.manager.screenManager.softButtonObjects = [self buildDefaultSoftButtons];
    [self.manager.screenManager endUpdatesWithCompletionHandler:nil];
    
    if (withSpeak) {
        SDLSpeak *speak = [[SDLSpeak alloc] initWithTTS:self.localization[@"speak.welcome"]];
        [self.manager sendRequest:speak];
    }
}

- (void)sendShowRequest:(SDLShow *)showRequest withImageNamed:(NSString *)filename {
    // If graphics are available we need to add in the image graphic to the SHOW
    if (self.graphicsAvailable) {
        SDLImage *image = [[SDLImage alloc] init];
        image.imageType = SDLImageTypeDynamic;
        image.value = filename;
        
        // Check if the file is already on the remote system
        if ([self.manager.fileManager.remoteFileNames containsObject:filename]) {
            showRequest.graphic = image;
            [self.manager sendRequest:showRequest];
        } else {
            [self.manager sendRequest:showRequest];
            
            SDLArtwork *artwork = [SDLArtwork artworkWithImage:[[ImageProcessor sharedProcessor] imageFromConditionImage:filename] name:filename asImageFormat:SDLArtworkImageFormatPNG];
            [self.manager.fileManager uploadFile:artwork completionHandler:^(BOOL success, NSUInteger bytesAvailable, NSError * _Nullable error) {
                SDLShow *showImage = [[SDLShow alloc] init];
                showImage.graphic = image;
                [self.manager sendRequest:showImage];
            }];
        }
    } else {
        [self.manager sendRequest:showRequest];
    }
}

- (void)sendWeatherConditions:(WeatherConditions *)conditions withSpeak:(BOOL)withSpeak {
    if (conditions != nil) {
        self.currentInfoType = MWInfoTypeWeatherConditions;
        
        // use these types for unit conversion
        UnitPercentageType percentageType = UnitPercentageDefault;
        UnitTemperatureType temperatureType = UnitTemperatureCelsius;
        UnitSpeedType speedType = UnitSpeedMeterSecond;
        
        if ([WeatherDataManager sharedManager].unit == UnitTypeMetric) {
            temperatureType = UnitTemperatureCelsius;
            speedType = UnitSpeedKiloMeterHour;
        } else if ([WeatherDataManager sharedManager].unit == UnitTypeImperial) {
            temperatureType = UnitTemperatureFahrenheit;
            speedType = UnitSpeedMileHour;
        }

        [self.manager.screenManager beginUpdates];
        self.manager.screenManager.softButtonObjects = [self buildDefaultSoftButtons];
        self.manager.screenManager.textField1 = conditions.conditionTitle;
        self.manager.screenManager.textField1Type = SDLMetadataTypeWeatherTerm;

        self.manager.screenManager.textField2 = [conditions.temperature stringValueForUnit:temperatureType shortened:YES localization:self.localization];
        self.manager.screenManager.textField2Type = SDLMetadataTypeCurrentTemperature;

        self.manager.screenManager.textField3 = [conditions.precipitation stringValueForUnit:percentageType shortened:YES localization:self.localization];
        self.manager.screenManager.textField4 = [conditions.windSpeed stringValueForUnit:speedType shortened:YES localization:self.localization];

        self.manager.screenManager.primaryGraphic = [SDLArtwork artworkWithImage:[[ImageProcessor sharedProcessor] imageFromConditionImage:conditions.conditionIcon] name:conditions.conditionIcon asImageFormat:SDLArtworkImageFormatPNG];

        [self.manager.screenManager endUpdatesWithCompletionHandler:nil];

        if (withSpeak) {
            SDLSpeak *speakRequest = [[SDLSpeak alloc] initWithTTS:[self.localization stringForKey:@"conditions.speak", conditions.conditionTitle, [conditions.temperature stringValueForUnit:temperatureType shortened:NO localization:self.localization], [conditions.humidity stringValueForUnit:percentageType shortened:NO localization:self.localization], [conditions.windSpeed stringValueForUnit:speedType shortened:NO localization:self.localization]]];
            [self.manager sendRequest:speakRequest];
        }
    }
    else {
        SDLAlert *alertRequest = [[SDLAlert alloc] initWithTTS:self.localization[@"alert.no-conditions.prompt"] alertText1:self.localization[@"alert.no-conditions.field1"] alertText2:self.localization[@"alert.no-conditions.field2"] playTone:NO duration:10000];
        [self.manager sendRequest:alertRequest];
    }
}

- (void)sendForecastList:(NSArray *)forecasts infoType:(MWInfoType)infoType withSpeak:(BOOL)withSpeak {
    if (forecasts && forecasts.count > 0) {
        if ([infoType isEqualToString:MWInfoTypeDailyForecast]) {
            forecasts = [forecasts subarrayWithRange:NSMakeRange(0, MIN(forecasts.count, 7))];
        } else if ([infoType isEqualToString:MWInfoTypeHourlyForecast]) {
            forecasts = [forecasts subarrayWithRange:NSMakeRange(0, MIN(forecasts.count, 24))];
        }
        NSUInteger index = 0;
        if ([infoType isEqualToString:self.currentInfoType]) {
            [self deleteForecastChoiceSet];
            Forecast *oldForecast = (self.currentInfoTypeList)[self.currentInfoTypeListIndex];
            
            for (NSUInteger newindex = 0; newindex < forecasts.count; newindex++) {
                Forecast *newForecast = forecasts[index];
                
                if ([newForecast.date isEqualToDate:oldForecast.date]) {
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
        
        self.currentInfoType = infoType;
        self.currentInfoTypeList = forecasts;
        self.currentInfoTypeListIndex = index;
    } else {
        SDLAlert *alertRequest = [[SDLAlert alloc] initWithTTS:self.localization[@"alert.no-forecast.prompt"] alertText1:self.localization[@"alert.no-forecast.field1"] alertText2:self.localization[@"alert.no-forecast.field2"] playTone:NO duration:10000];
        [self.manager sendRequest:alertRequest];
    }
}

- (void)sendForecastAtIndex:(NSUInteger)index fromList:(NSArray *)forecasts infoType:(MWInfoType)infoType withSpeak:(BOOL)withSpeak {
    BOOL isHourlyForecast = [infoType isEqualToString:MWInfoTypeHourlyForecast];
    Forecast *forecast = forecasts[index];
    
    NSDateFormatter *dateTimeFormatShow = [[NSDateFormatter alloc] init];
    dateTimeFormatShow.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    dateTimeFormatShow.locale = self.localization.locale;
    
    NSDateFormatter *weekDayFormatShow = [[NSDateFormatter alloc] init];
    weekDayFormatShow.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    weekDayFormatShow.locale = self.localization.locale;
    
    if (isHourlyForecast) {
        dateTimeFormatShow.dateFormat = self.localization[@"forecast.hourly.format.date-time.show"];
        weekDayFormatShow.dateFormat = self.localization[@"forecast.hourly.format.week-day.show"];
    } else {
        dateTimeFormatShow.dateFormat = self.localization[@"forecast.daily.format.date-time.show"];
        weekDayFormatShow.dateFormat = self.localization[@"forecast.daily.format.week-day.show"];
    }
    
    NSString *conditionTitleShow = forecast.conditionTitle;
    NSString *dateTimeStringShow = [dateTimeFormatShow stringFromDate:forecast.date];
    NSString *weekDayStringShow = [weekDayFormatShow stringFromDate:forecast.date];
    
    // get the range for a shortened title.
    NSRange conditionTitleShowShortRange =
    [conditionTitleShow rangeOfString:self.localization[@"conditions.title.short"]
                              options:NSRegularExpressionSearch|NSCaseInsensitiveSearch];
    
    // have we found a shortened title?
    if (conditionTitleShowShortRange.location != NSNotFound) {
        conditionTitleShow = [conditionTitleShow substringWithRange:conditionTitleShowShortRange];
    }
    
    UnitPercentageType percentageType = UnitPercentageDefault;
    UnitTemperatureType temperatureType = UnitTemperatureCelsius;
    UnitSpeedType speedType = UnitSpeedKiloMeterHour;
    
    if ([WeatherDataManager sharedManager].unit == UnitTypeImperial) {
        temperatureType = UnitTemperatureFahrenheit;
        speedType = UnitSpeedMileHour;
    }
    if ([self updateListVoiceCommandsWithNewIndex:index
                                        ofNewList:forecasts
                                     withOldIndex:self.currentInfoTypeListIndex
                                        ofOldList:self.currentInfoTypeList]) {
        [self sendListGlobalProperties:infoType
                          withPrevious:(index != 0)
                              withNext:(index + 1 != forecasts.count)];
    }

    [self.manager.screenManager beginUpdates];
    self.manager.screenManager.softButtonObjects = [self buildListSoftButtons:infoType withIndex:index maxCount:forecasts.count];

    self.manager.screenManager.primaryGraphic = [SDLArtwork artworkWithImage:[[ImageProcessor sharedProcessor] imageFromConditionImage:forecast.conditionIcon] asImageFormat:SDLArtworkImageFormatPNG];
    
    if (isHourlyForecast) {
        self.manager.screenManager.textField1 = [self.localization stringForKey:@"forecast.hourly.show.field1", dateTimeStringShow, conditionTitleShow];
        self.manager.screenManager.textField1Type = SDLMetadataTypeWeatherTerm;

        self.manager.screenManager.textField2 = [forecast.temperature stringValueForUnit:temperatureType shortened:YES localization:self.localization];;
        self.manager.screenManager.textField2Type = SDLMetadataTypeCurrentTemperature;

        self.manager.screenManager.textField3 = [forecast.precipitation stringValueForUnit:percentageType shortened:YES localization:self.localization];
        self.manager.screenManager.textField4 = [forecast.windSpeed stringValueForUnit:speedType shortened:YES localization:self.localization];
    } else {
        self.manager.screenManager.textField1 = [self.localization stringForKey:@"forecast.daily.show.field1", weekDayStringShow, conditionTitleShow];
        self.manager.screenManager.textField1Type = SDLMetadataTypeWeatherTerm;

        self.manager.screenManager.textField2 = [forecast.highTemperature stringValueForUnit:temperatureType shortened:YES localization:self.localization];
        self.manager.screenManager.textField2Type = SDLMetadataTypeMinimumTemperature;

        self.manager.screenManager.textField3 = [forecast.lowTemperature stringValueForUnit:temperatureType shortened:YES localization:self.localization];
        self.manager.screenManager.textField3Type = SDLMetadataTypeMaximumTemperature
        ;
        self.manager.screenManager.textField4 = [forecast.precipitationChance stringValueForUnit:percentageType shortened:YES localization:self.localization];
    }

    [self.manager.screenManager endUpdatesWithCompletionHandler:nil];
    
    if (withSpeak) {
        NSDateFormatter *dateTimeFormatSpeak = [[NSDateFormatter alloc] init];
        dateTimeFormatSpeak.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
        dateTimeFormatSpeak.locale = (self.localization).locale;
        
        NSDateFormatter *weekDayFormatSpeak = [[NSDateFormatter alloc] init];
        weekDayFormatSpeak.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
        weekDayFormatSpeak.locale = (self.localization).locale;
        
        if (isHourlyForecast) {
            dateTimeFormatSpeak.dateFormat = self.localization[@"forecast.hourly.format.date-time.speak"];
            weekDayFormatSpeak.dateFormat = self.localization[@"forecast.hourly.format.week-day.speak"];
        } else {
            dateTimeFormatSpeak.dateFormat = self.localization[@"forecast.daily.format.date-time.speak"];
            weekDayFormatSpeak.dateFormat = self.localization[@"forecast.daily.format.week-day.speak"];
        }
        
        NSString *dateTimeStringSpeak = [dateTimeFormatSpeak stringFromDate:forecast.date];
        NSString *weekDayStringSpeak = [weekDayFormatSpeak stringFromDate:forecast.date];
        NSString *speakString;
        
        if (isHourlyForecast) {
            speakString = [self.localization stringForKey:@"forecast.hourly.speak",
                           dateTimeStringSpeak,
                           forecast.conditionTitle,
                           [forecast.temperature stringValueForUnit:temperatureType shortened:NO localization:self.localization],
                           [forecast.humidity stringValueForUnit:percentageType shortened:NO localization:self.localization],
                           [forecast.precipitationChance stringValueForUnit:percentageType shortened:NO localization:self.localization]];
        } else {
            speakString = [self.localization stringForKey:@"forecast.daily.speak",
                           weekDayStringSpeak,
                           forecast.conditionTitle,
                           [forecast.lowTemperature doubleValueForUnit:temperatureType],
                           [forecast.highTemperature doubleValueForUnit:temperatureType],
                           [forecast.highTemperature nameForUnit:temperatureType shortened:NO localization:self.localization],
                           [forecast.humidity stringValueForUnit:percentageType shortened:NO localization:self.localization],
                           [forecast.precipitationChance stringValueForUnit:percentageType shortened:NO localization:self.localization]];
        }
        
        SDLSpeak *speakRequest = [[SDLSpeak alloc] initWithTTS:speakString];
        [self.manager sendRequest:speakRequest];
    }
}

- (void)sendAlertList:(NSArray *)alerts withSpeak:(BOOL)withSpeak {
    if (alerts.count > 0) {
        NSUInteger index = 0;
        if ([MWInfoTypeAlerts isEqualToString:self.currentInfoType]) {
            Alert *oldAlert = self.currentInfoTypeList[self.currentInfoTypeListIndex];
            
            for (NSUInteger newindex = 0; newindex < alerts.count; newindex++) {
                Alert *newAlert = alerts[index];
                
                if ([newAlert isEqualToAlert:oldAlert]) {
                    index = newindex;
                    break;
                }
            }
        } else {
            [self deleteWeatherVoiceCommands];
            [self sendListVoiceCommands:MWInfoTypeAlerts];
        }
        
        [self sendAlertAtIndex:index fromList:alerts withSpeak:withSpeak];
        
        self.currentInfoType = MWInfoTypeAlerts;
        self.currentInfoTypeList = alerts;
        self.currentInfoTypeListIndex = index;
    } else {
        SDLAlert *alertRequest = [[SDLAlert alloc] initWithTTS:self.localization[@"alert.no-alerts.prompt"] alertText1:self.localization[@"alert.no-alerts.field1"] alertText2:self.localization[@"alert.no-alerts.field2"] playTone:NO duration:10000];
        [self.manager sendRequest:alertRequest];
    }
}

- (void)sendAlertAtIndex:(NSUInteger)index fromList:(NSArray<Alert *> *)alerts withSpeak:(BOOL)withSpeak {
    Alert *alert = alerts[index];
    [self.currentKnownAlerts addObject:alert];

    NSDateFormatter *dateTimeFormatShow = [[NSDateFormatter alloc] init];
    dateTimeFormatShow.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    dateTimeFormatShow.locale = (self.localization).locale;
    dateTimeFormatShow.dateFormat = self.localization[@"weather-alerts.format.date-time.show"];
    
    NSString *dateTimeStringShow = [dateTimeFormatShow stringFromDate:alert.dateExpires];

    if ([self updateListVoiceCommandsWithNewIndex:index ofNewList:alerts withOldIndex:self.currentInfoTypeListIndex ofOldList:self.currentInfoTypeList]) {
        [self sendListGlobalProperties:MWInfoTypeAlerts withPrevious:(index != 0) withNext:(index + 1 != alerts.count)];
    }

    [self.manager.screenManager beginUpdates];
    self.manager.screenManager.textField1 = dateTimeStringShow;
    self.manager.screenManager.textField2 = alert.title;
    self.manager.screenManager.textField3 = nil;
    self.manager.screenManager.textField4 = nil;
    self.manager.screenManager.softButtonObjects = [self buildListSoftButtons:MWInfoTypeAlerts withIndex:index maxCount:alerts.count];
    [self.manager.screenManager endUpdatesWithCompletionHandler:nil];
    
    if (withSpeak) {
        NSDateFormatter *dateTimeFormatSpeak = [[NSDateFormatter alloc] init];
        dateTimeFormatSpeak.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
        dateTimeFormatSpeak.locale = self.localization.locale;
        dateTimeFormatSpeak.dateFormat = self.localization[@"weather-alerts.format.date-time.speak"];
        
        NSString *dateTimeStringSpeak = [dateTimeFormatSpeak stringFromDate:alert.dateExpires];
        
        SDLSpeak *speakRequest = [[SDLSpeak alloc] initWithTTS:[self.localization stringForKey:@"weather-alerts.speak", alert.title, dateTimeStringSpeak]];
        [self.manager sendRequest:speakRequest];
    }
}

- (void)sendAlertMessageAtIndex:(NSUInteger)index {
    Alert *alert = self.currentInfoTypeList[index];
    NSString *description = alert.text;
    
    if (description.length > 500) {
        description = [[description substringToIndex:497] stringByAppendingString:@"..."];
    }
    
    SDLScrollableMessage *message = [[SDLScrollableMessage alloc] initWithMessage:description timeout:60000 softButtons:nil];
    [self.manager sendRequest:message];
}

- (void)closeListInfoType:(MWInfoType)infoType {
    if ([MWInfoTypeHourlyForecast isEqualToString:infoType] || [MWInfoTypeDailyForecast isEqualToString:infoType]) {
        [self deleteForecastChoiceSet];
    }

    [self deleteListVoiceCommands:infoType];
    [self deleteListNextVoiceCommand];
    [self deleteListPreviousVoiceCommand];
    
    self.currentInfoType = MWInfoTypeNone;
    [self setCurrentInfoTypeList:nil];
    self.currentInfoTypeListIndex = -1;
    
    [self sendWelcomeMessageWithSpeak:NO];
    [self sendWeatherVoiceCommands];
    [self sendDefaultGlobalProperties];
}

- (void)repeatWeatherInformation {
    MWInfoType infoType = self.currentInfoType;
    if ([MWInfoTypeWeatherConditions isEqualToString:infoType]) {
        [self sendWeatherConditions:[WeatherDataManager sharedManager].weatherConditions withSpeak:YES];
    } else if ([MWInfoTypeDailyForecast isEqualToString:infoType] || [MWInfoTypeHourlyForecast isEqualToString:infoType]) {
        [self sendForecastAtIndex:self.currentInfoTypeListIndex fromList:self.currentInfoTypeList infoType:infoType withSpeak:YES];
    } else if ([MWInfoTypeAlerts isEqualToString:infoType]) {
        [self sendAlertAtIndex:self.currentInfoTypeListIndex fromList:self.currentInfoTypeList withSpeak:YES];
    }
}

- (void)subscribeRepeatButton {
    __weak typeof(self) weakSelf = self;
    SDLSubscribeButton *request = [[SDLSubscribeButton alloc] initWithButtonName:SDLButtonNamePreset1 handler:^(SDLOnButtonPress * _Nullable buttonPress, SDLOnButtonEvent * _Nullable buttonEvent) {
        if (!buttonPress) { return; }

        [weakSelf repeatWeatherInformation];
    }];
    
    [self.manager sendRequest:request];
}

- (NSArray<SDLSoftButtonObject *> *)buildDefaultSoftButtons {
    __weak typeof(self) weakSelf = self;
    SDLSoftButtonState *currentWeatherState = [[SDLSoftButtonState alloc] initWithStateName:@"state" text:self.localization[@"sb.current"] image:nil];
    SDLSoftButtonObject *currentWeatherObject = [[SDLSoftButtonObject alloc] initWithName:@"CurrentWeather" state:currentWeatherState handler:^(SDLOnButtonPress * _Nullable buttonPress, SDLOnButtonEvent * _Nullable buttonEvent) {
        if (!buttonPress) {
            return;
        }

        [weakSelf sendWeatherConditions:[WeatherDataManager sharedManager].weatherConditions withSpeak:YES];
    }];

    SDLSoftButtonState *dailyForecastState = [[SDLSoftButtonState alloc] initWithStateName:@"state" text:self.localization[@"sb.daily"] image:nil];
    SDLSoftButtonObject *dailyForecastObject = [[SDLSoftButtonObject alloc] initWithName:@"DailyForecast" state:dailyForecastState handler:^(SDLOnButtonPress * _Nullable buttonPress, SDLOnButtonEvent * _Nullable buttonEvent) {
        if (!buttonPress) {
            return;
        }

        [weakSelf sendForecastList:[WeatherDataManager sharedManager].dailyForecast infoType:MWInfoTypeDailyForecast withSpeak:YES];
    }];

    SDLSoftButtonState *hourlyForecastState = [[SDLSoftButtonState alloc] initWithStateName:@"state" text:self.localization[@"sb.hourly"] image:nil];
    SDLSoftButtonObject *hourlyForecastObject = [[SDLSoftButtonObject alloc] initWithName:@"HourlyForecast" state:hourlyForecastState handler:^(SDLOnButtonPress * _Nullable buttonPress, SDLOnButtonEvent * _Nullable buttonEvent) {
        if (!buttonPress) {
            return;
        }

        [weakSelf sendForecastList:[WeatherDataManager sharedManager].hourlyForecast infoType:MWInfoTypeHourlyForecast withSpeak:YES];
    }];

    SDLSoftButtonState *alertsState = [[SDLSoftButtonState alloc] initWithStateName:@"state" text:self.localization[@"sb.alerts"] image:nil];
    SDLSoftButtonObject *alertsObject = [[SDLSoftButtonObject alloc] initWithName:@"Alerts" state:alertsState handler:^(SDLOnButtonPress * _Nullable buttonPress, SDLOnButtonEvent * _Nullable buttonEvent) {
        if (!buttonPress) {
            return;
        }

        [weakSelf sendAlertList:[WeatherDataManager sharedManager].alerts withSpeak:YES];
    }];
    
    return @[currentWeatherObject, dailyForecastObject, hourlyForecastObject, alertsObject];
}

- (NSArray<SDLSoftButtonObject *> *)buildListSoftButtons:(MWInfoType)infoType withIndex:(NSUInteger)index maxCount:(NSUInteger)count {
    __weak typeof(self) weakSelf = self;

    SDLSoftButtonState *previousState = [[SDLSoftButtonState alloc] initWithStateName:@"state" text:@"<" image:nil];
    SDLSoftButtonState *previousUnavailableState = [[SDLSoftButtonState alloc] initWithStateName:@"blank" text:@"-" image:nil];

    NSString *initialPreviousState = ((index != 0) ? @"state" : @"blank");
    SDLSoftButtonObject *previousObject = [[SDLSoftButtonObject alloc] initWithName:@"Previous" states:@[previousState, previousUnavailableState] initialStateName:initialPreviousState handler:^(SDLOnButtonPress * _Nullable buttonPress, SDLOnButtonEvent * _Nullable buttonEvent) {
        if (!buttonPress) { return; }

        MWInfoType infoType = weakSelf.currentInfoType;
        if (weakSelf.currentInfoTypeListIndex > 0) {
            NSInteger index = weakSelf.currentInfoTypeListIndex - 1;
            if ([infoType isEqualToString:MWInfoTypeDailyForecast] || [infoType isEqualToString:MWInfoTypeHourlyForecast]) {
                [weakSelf sendForecastAtIndex:index fromList:weakSelf.currentInfoTypeList infoType:infoType withSpeak:YES];
            }
            weakSelf.currentInfoTypeListIndex = index;
        }
    }];

    SDLSoftButtonState *nextState = [[SDLSoftButtonState alloc] initWithStateName:@"state" text:@">" image:nil];
    SDLSoftButtonState *nextUnavailableState = [[SDLSoftButtonState alloc] initWithStateName:@"blank" text:@"-" image:nil];

    NSString *initialNextState = ((index + 1 != count) ? @"state" : @"blank");
    SDLSoftButtonObject *nextObject = [[SDLSoftButtonObject alloc] initWithName:@"Next" states:@[nextState, nextUnavailableState] initialStateName:initialNextState handler:^(SDLOnButtonPress * _Nullable buttonPress, SDLOnButtonEvent * _Nullable buttonEvent) {
        if (!buttonPress) { return; }

        MWInfoType infoType = weakSelf.currentInfoType;
        if (weakSelf.currentInfoTypeListIndex + 1 < weakSelf.currentInfoTypeList.count) {
            NSInteger index = weakSelf.currentInfoTypeListIndex + 1;
            if ([infoType isEqualToString:MWInfoTypeDailyForecast] || [infoType isEqualToString:MWInfoTypeHourlyForecast]) {
                [weakSelf sendForecastAtIndex:index fromList:weakSelf.currentInfoTypeList infoType:infoType withSpeak:YES];
            }
            weakSelf.currentInfoTypeListIndex = index;
        }
    }];

    SDLSoftButtonObject *showObject = nil;
    if ([MWInfoTypeDailyForecast isEqualToString:infoType] || [MWInfoTypeHourlyForecast isEqualToString:infoType]) {
        SDLSoftButtonState *showListState = [[SDLSoftButtonState alloc] initWithStateName:@"state" text:self.localization[@"sb.list"] image:nil];
        showObject = [[SDLSoftButtonObject alloc] initWithName:@"ShowList" state:showListState handler:^(SDLOnButtonPress * _Nullable buttonPress, SDLOnButtonEvent * _Nullable buttonEvent) {
            if (!buttonPress) { return; }

            [weakSelf performForecastInteractionWithMode:SDLInteractionModeManualOnly];
        }];
    } else if ([MWInfoTypeAlerts isEqualToString:infoType]) {
        SDLSoftButtonState *showMessage = [[SDLSoftButtonState alloc] initWithStateName:@"state" text:self.localization[@"sb.message"] image:nil];
        showObject = [[SDLSoftButtonObject alloc] initWithName:@"ShowList" state:showMessage handler:^(SDLOnButtonPress * _Nullable buttonPress, SDLOnButtonEvent * _Nullable buttonEvent) {
            if (!buttonPress) { return; }

            [weakSelf sendAlertMessageAtIndex:weakSelf.currentInfoTypeListIndex];
        }];
    }

    SDLSoftButtonState *closeState = [[SDLSoftButtonState alloc] initWithStateName:@"state" text:self.localization[@"sb.back"] image:nil];
    SDLSoftButtonObject *closeObject = [[SDLSoftButtonObject alloc] initWithName:@"Close" state:closeState handler:^(SDLOnButtonPress * _Nullable buttonPress, SDLOnButtonEvent * _Nullable buttonEvent) {
        if (!buttonPress) { return; }

        [weakSelf closeListInfoType:weakSelf.currentInfoType];
    }];
    
    return @[previousObject, showObject, nextObject, closeObject];
}

- (void)sendWeatherVoiceCommands {
    SDLMenuParams *menuparams1 = [[SDLMenuParams alloc] initWithMenuName:self.localization[@"cmd.current-conditions"]];
    menuparams1.position = @1;
    SDLAddCommand *request1 = [[SDLAddCommand alloc] initWithId:MWMenuCommandIdShowWeatherConditions vrCommands:@[self.localization[@"vr.current"],self.localization[@"vr.conditions"], self.localization[@"vr.current-conditions"], self.localization[@"vr.show-conditions"], self.localization[@"vr.show-current-conditions"]] handler:^(SDLOnCommand * _Nonnull command) {
        [self sendWeatherConditions:[WeatherDataManager sharedManager].weatherConditions withSpeak:YES];
    }];
    request1.menuParams = menuparams1;

    SDLMenuParams *menuparams2 = [[SDLMenuParams alloc] initWithMenuName:self.localization[@"cmd.daily-forecast"]];
    menuparams2.position = @2;
    SDLAddCommand *request2 = [[SDLAddCommand alloc] initWithId:MWMenuCommandIdShowDailyForecast vrCommands:@[self.localization[@"vr.daily"], self.localization[@"vr.daily-forecast"], self.localization[@"vr.show-daily-forecast"]] handler:^(SDLOnCommand * _Nonnull command) {
        [self sendForecastList:[WeatherDataManager sharedManager].dailyForecast infoType:MWInfoTypeDailyForecast withSpeak:YES];
    }];
    request2.menuParams = menuparams2;

    SDLMenuParams *menuparams3 = [[SDLMenuParams alloc] initWithMenuName:self.localization[@"cmd.hourly-forecast"]];
    menuparams3.position = @3;
    SDLAddCommand *request3 = [[SDLAddCommand alloc] initWithId:MWMenuCommandIdShowHourlyForecast vrCommands:@[self.localization[@"vr.hourly"], self.localization[@"vr.hourly-forecast"], self.localization[@"vr.show-hourly-forecast"]] handler:^(SDLOnCommand * _Nonnull command) {
        [self sendForecastList:[WeatherDataManager sharedManager].hourlyForecast infoType:MWInfoTypeHourlyForecast withSpeak:YES];
    }];
    request3.menuParams = menuparams3;

    SDLMenuParams *menuparams4 = [[SDLMenuParams alloc] initWithMenuName:self.localization[@"cmd.alerts"]];
    menuparams4.position = @4;
    SDLAddCommand *request4 = [[SDLAddCommand alloc] initWithId:MWMenuCommandIdShowAlerts vrCommands:@[self.localization[@"vr.alerts"], self.localization[@"vr.show-alerts"]] handler:^(SDLOnCommand * _Nonnull command) {
        [self sendAlertList:[WeatherDataManager sharedManager].alerts withSpeak:YES];
    }];
    request4.menuParams = menuparams4;
    
    [self.manager sendRequests:@[request1, request2, request3, request4] progressHandler:nil completionHandler:nil];
}

- (void)deleteWeatherVoiceCommands {
    SDLDeleteCommand *delete1 = [[SDLDeleteCommand alloc] initWithId:MWMenuCommandIdShowWeatherConditions];
    SDLDeleteCommand *delete2 = [[SDLDeleteCommand alloc] initWithId:MWMenuCommandIdShowDailyForecast];
    SDLDeleteCommand *delete3 = [[SDLDeleteCommand alloc] initWithId:MWMenuCommandIdShowHourlyForecast];
    SDLDeleteCommand *delete4 = [[SDLDeleteCommand alloc] initWithId:MWMenuCommandIdShowAlerts];
    
    [self.manager sendRequests:@[delete1, delete2, delete3, delete4] progressHandler:nil completionHandler:nil];
}

- (void)sendChangeUnitsVoiceCommand {
    SDLAddCommand *request = nil;
    SDLMenuParams *menuparams = nil;
    
    menuparams = [[SDLMenuParams alloc] initWithMenuName:self.localization[@"cmd.change-units"]];
    menuparams.position = @5;

    __weak typeof(self) weakSelf = self;
    request = [[SDLAddCommand alloc] initWithId:MWMenuCommandIdShowChangeUnits vrCommands:@[self.localization[@"vr.units"], self.localization[@"vr.change-units"]] handler:^(SDLOnCommand * _Nonnull command) {
        // the user has performed the voice command to change the units
        SDLInteractionMode mode = nil;
        if ([command.triggerSource isEqualToEnum:SDLTriggerSourceMenu]) {
            mode = SDLInteractionModeManualOnly;
        } else {
            mode = SDLInteractionModeBoth;
        }

        [weakSelf performChangeUnitsInteractionWithMode:mode];
    }];
    request.menuParams = menuparams;
    [self.manager sendRequest:request];
}

- (void)sendListVoiceCommands:(MWInfoType)infoType {
    SDLAddCommand *request;
    SDLMenuParams *menuparams;
    __weak typeof(self) weakSelf = self;
    
    if ([MWInfoTypeDailyForecast isEqual:infoType] || [MWInfoTypeHourlyForecast isEqual:infoType]) {
        menuparams = [[SDLMenuParams alloc] initWithMenuName:self.localization[@"cmd.show-list"]];
        menuparams.position = @3;

        request = [[SDLAddCommand alloc] initWithId:MWMenuCommandIdListShowList vrCommands:@[self.localization[@"vr.list"], self.localization[@"vr.show-list"]] handler:^(SDLOnCommand * _Nonnull command) {
            SDLInteractionMode mode = nil;
            if ([SDLTriggerSourceMenu isEqualToEnum:command.triggerSource]) {
                mode = SDLInteractionModeManualOnly;
            } else {
                mode = SDLInteractionModeBoth;
            }
            [weakSelf performForecastInteractionWithMode:mode];
        }];
        request.menuParams = menuparams;
        [self.manager sendRequest:request];
    } else if ([MWInfoTypeAlerts isEqualToString:infoType]) {
        menuparams = [[SDLMenuParams alloc] initWithMenuName:self.localization[@"cmd.show-message"]];
        menuparams.position = @3;
        request = [[SDLAddCommand alloc] initWithId:MWMenuCommandIdListShowMessage vrCommands:@[self.localization[@"vr.message"], self.localization[@"vr.show-message"]] handler:^(SDLOnCommand * _Nonnull command) {
            [weakSelf sendAlertMessageAtIndex:weakSelf.currentInfoTypeListIndex];
        }];
        request.menuParams = menuparams;
        [self.manager sendRequest:request];
    }
    
    menuparams = [[SDLMenuParams alloc] initWithMenuName:self.localization[@"cmd.back"]];
    menuparams.position = @4;
    request = [[SDLAddCommand alloc] initWithId:MWMenuCommandIdListBack vrCommands:@[self.localization[@"vr.back"]] handler:^(SDLOnCommand * _Nonnull command) {
        [weakSelf closeListInfoType:weakSelf.currentInfoType];
    }];
    request.menuParams = menuparams;
    [self.manager sendRequest:request];
    
    if ([MWInfoTypeHourlyForecast isEqualToString:infoType]) {
        request = [[SDLAddCommand alloc] initWithId:MWMenuCommandIdListHourlyNow vrCommands:@[self.localization[@"vr.now"]] handler:^(SDLOnCommand * _Nonnull command) {
            [weakSelf sendForecastAtIndex:0 fromList:weakSelf.currentInfoTypeList infoType:weakSelf.currentInfoType withSpeak:YES];
            weakSelf.currentInfoTypeListIndex = 0;
        }];
        [self.manager sendRequest:request];
    } else {
        request = [[SDLAddCommand alloc] initWithId:MWMenuCommandIdListDailyToday vrCommands:@[self.localization[@"vr.today"]] handler:^(SDLOnCommand * _Nonnull command) {
            [weakSelf sendForecastAtIndex:0 fromList:weakSelf.currentInfoTypeList infoType:weakSelf.currentInfoType withSpeak:YES];
            weakSelf.currentInfoTypeListIndex = 0;
        }];
        [self.manager sendRequest:request];
        
        request = [[SDLAddCommand alloc] initWithId:MWMenuCommandIdListDailyTomorrow vrCommands:@[self.localization[@"vr.tomorrow"]] handler:^(SDLOnCommand * _Nonnull command) {
            [weakSelf sendForecastAtIndex:1 fromList:weakSelf.currentInfoTypeList infoType:weakSelf.currentInfoType withSpeak:YES];
            weakSelf.currentInfoTypeListIndex = 1;
        }];
        [self.manager sendRequest:request];
    }
}

- (void)deleteListVoiceCommands:(MWInfoType)infoType {
    SDLDeleteCommand *request;
    
    if ([MWInfoTypeDailyForecast isEqualToString:infoType] || [MWInfoTypeHourlyForecast isEqualToString:infoType]) {
        request = [[SDLDeleteCommand alloc] initWithId:MWMenuCommandIdListShowList];
        [self.manager sendRequest:request];
    } else if ([MWInfoTypeAlerts isEqualToString:infoType]) {
        request = [[SDLDeleteCommand alloc] initWithId:MWMenuCommandIdListShowMessage];
        [self.manager sendRequest:request];
    }
    
    request = [[SDLDeleteCommand alloc] initWithId:MWMenuCommandIdListBack];
    [self.manager sendRequest:request];
    
    if ([infoType isEqualToString:MWInfoTypeHourlyForecast]) {
        request = [[SDLDeleteCommand alloc] initWithId:MWMenuCommandIdListHourlyNow];
        [self.manager sendRequest:request];
    } else {
        request = [[SDLDeleteCommand alloc] initWithId:MWMenuCommandIdListDailyToday];
        [self.manager sendRequest:request];
        
        request = [[SDLDeleteCommand alloc] initWithId:MWMenuCommandIdListDailyTomorrow];
        [self.manager sendRequest:request];
    }
}

- (void)sendListNextVoiceCommand {
    SDLMenuParams *menuparams = [[SDLMenuParams alloc] initWithMenuName:self.localization[@"cmd.next"]];
    menuparams.position = @1;

    __weak typeof(self) weakSelf = self;
    SDLAddCommand *request = [[SDLAddCommand alloc] initWithId:MWMenuCommandIdListNext vrCommands:@[self.localization[@"vr.next"]] handler:^(SDLOnCommand * _Nonnull command) {
        typeof(weakSelf) strongSelf = weakSelf;
        MWInfoType infoType = strongSelf.currentInfoType;
        if (strongSelf.currentInfoTypeListIndex + 1 < strongSelf.currentInfoTypeList.count) {
            NSInteger index = strongSelf.currentInfoTypeListIndex + 1;
            if ([infoType isEqualToString:MWInfoTypeDailyForecast] || [infoType isEqualToString:MWInfoTypeHourlyForecast]) {
                [strongSelf sendForecastAtIndex:index fromList:strongSelf.currentInfoTypeList infoType:infoType withSpeak:YES];
            } else if ([infoType isEqualToString:MWInfoTypeAlerts]) {
                [strongSelf sendAlertAtIndex:index fromList:strongSelf.currentInfoTypeList withSpeak:YES];
            }
            strongSelf.currentInfoTypeListIndex = index;
        }
    }];
    request.menuParams = menuparams;
    
    [self.manager sendRequest:request];
}

- (void)deleteListNextVoiceCommand {
    SDLDeleteCommand *request = [[SDLDeleteCommand alloc] initWithId:MWMenuCommandIdListNext];
    [self.manager sendRequest:request];
}

- (void)sendListPreviousVoiceCommand {
    SDLMenuParams *menuparams = [[SDLMenuParams alloc] initWithMenuName:self.localization[@"cmd.previous"]];
    menuparams.position = @2;

    __weak typeof(self) weakSelf = self;
    SDLAddCommand *request = [[SDLAddCommand alloc] initWithId:MWMenuCommandIdListPrevious vrCommands:@[self.localization[@"vr.previous"]] handler:^(SDLOnCommand * _Nonnull command) {
        typeof(weakSelf) strongSelf = weakSelf;

        MWInfoType infoType = strongSelf.currentInfoType;
        if (strongSelf.currentInfoTypeListIndex <= 0) { return; }

        NSInteger index = strongSelf.currentInfoTypeListIndex - 1;
        if ([infoType isEqualToString:MWInfoTypeDailyForecast] || [infoType isEqualToString:MWInfoTypeHourlyForecast]) {
            [strongSelf sendForecastAtIndex:index fromList:strongSelf.currentInfoTypeList infoType:infoType withSpeak:YES];
        } else if ([infoType isEqualToString:MWInfoTypeAlerts]) {
            [strongSelf sendAlertAtIndex:index fromList:strongSelf.currentInfoTypeList withSpeak:YES];
        }
        strongSelf.currentInfoTypeListIndex = index;
    }];
    request.menuParams = menuparams;
    
    [self.manager sendRequest:request];
}

- (void)deleteListPreviousVoiceCommand {
    SDLDeleteCommand *request = [[SDLDeleteCommand alloc] initWithId:MWMenuCommandIdListPrevious];
    [self.manager sendRequest:request];
}

- (BOOL)updateListVoiceCommandsWithNewIndex:(NSInteger)newIndex ofNewList:(NSArray *)newList withOldIndex:(NSInteger)oldIndex ofOldList:(NSArray *)oldList {
    BOOL newIsFirst, newIsLast, oldIsFirst, oldIsLast, modified;
    
    modified = NO;
    newIsFirst = (newIndex == 0);
    newIsLast = (newIndex + 1 == newList.count);
    
    if (oldIndex == -1) {
        oldIsFirst = YES;
        oldIsLast = YES;
    } else {
        oldIsFirst = (oldIndex == 0);
        oldIsLast = (oldIndex + 1 == oldList.count);
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
    NSMutableArray *prompts = [NSMutableArray array];
    NSMutableArray *helpitems = [NSMutableArray array];
    SDLVRHelpItem *helpitem;
    NSUInteger position = 0;
    
    helpitem = [[SDLVRHelpItem alloc] initWithText:self.localization[@"cmd.current-conditions"] image:nil position:++position];
    [helpitems addObject:helpitem];
    [prompts addObject:self.localization[@"vr.show-current-conditions"]];
    
    helpitem = [[SDLVRHelpItem alloc] initWithText:self.localization[@"cmd.daily-forecast"] image:nil position:++position];
    [helpitems addObject:helpitem];
    [prompts addObject:self.localization[@"vr.daily-forecast"]];
    
    helpitem = [[SDLVRHelpItem alloc] initWithText:self.localization[@"cmd.hourly-forecast"] image:nil position:++position];
    [helpitems addObject:helpitem];
    [prompts addObject:self.localization[@"vr.hourly-forecast"]];
    
    helpitem = [[SDLVRHelpItem alloc] initWithText:self.localization[@"cmd.change-units"] image:nil position:++position];
    [helpitems addObject:helpitem];
    [prompts addObject:self.localization[@"vr.change-units"]];
    
    NSString *promptstring = [prompts componentsJoinedByString:@","];

    SDLSetGlobalProperties *request = [[SDLSetGlobalProperties alloc] initWithHelpText:promptstring timeoutText:promptstring vrHelpTitle:self.localization[@"app.name"] vrHelp:[helpitems copy]];
    
    [self.manager sendRequest:request];
}

- (void)sendListGlobalProperties:(MWInfoType)infoType withPrevious:(BOOL)withPrevious withNext:(BOOL)withNext {
    NSMutableArray *prompts = [NSMutableArray array];
    NSMutableArray *items = [NSMutableArray array];
    SDLVRHelpItem *helpitem;
    NSUInteger position = 0;
    
    if (withPrevious) {
        helpitem = [[SDLVRHelpItem alloc] initWithText:self.localization[@"cmd.previous"] image:nil position:++position];
        [items addObject:helpitem];
        [prompts addObject:self.localization[@"vr.previous"]];
    }
    
    if (withNext) {
        helpitem = [[SDLVRHelpItem alloc] initWithText:self.localization[@"cmd.next"] image:nil position:++position];
        [items addObject:helpitem];
        [prompts addObject:self.localization[@"vr.next"]];
    }
    
    helpitem = [[SDLVRHelpItem alloc] initWithText:self.localization[@"cmd.back"] image:nil position:++position];
    [items addObject:helpitem];
    [prompts addObject:self.localization[@"vr.back"]];
    
    if ([MWInfoTypeDailyForecast isEqual:infoType] || [MWInfoTypeHourlyForecast isEqual:infoType]) {
        helpitem = [[SDLVRHelpItem alloc] initWithText:self.localization[@"cmd.show-list"] image:nil position:++position];
        [items addObject:helpitem];
        [prompts addObject:self.localization[@"vr.show-list"]];
    } else if ([MWInfoTypeAlerts isEqualToString:infoType]) {
        helpitem = [[SDLVRHelpItem alloc] initWithText:self.localization[@"cmd.show-message"] image:nil position:++position];
        [items addObject:helpitem];
        [prompts addObject:self.localization[@"vr.show-message"]];
    }
    
    helpitem = [[SDLVRHelpItem alloc] initWithText:self.localization[@"cmd.change-units"] image:nil position:++position];
    [items addObject:helpitem];
    [prompts addObject:self.localization[@"vr.change-units"]];
    
    NSString *promptstring = [prompts componentsJoinedByString:@","];

    SDLSetGlobalProperties *request = [[SDLSetGlobalProperties alloc] initWithHelpText:promptstring timeoutText:promptstring vrHelpTitle:self.localization[@"app.name"] vrHelp:[items copy]];
    [self.manager sendRequest:request]; 
}

@end

NS_ASSUME_NONNULL_END
