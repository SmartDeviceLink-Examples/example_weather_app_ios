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


MWInfoType const MWInfoTypeNone = @"NONE";
MWInfoType const MWInfoTypeWeatherConditions = @"WEATHER_CONDITIONS";
MWInfoType const MWInfoTypeDailyForecast = @"DAILY_FORECAST";
MWInfoType const MWInfoTypeHourlyForecast = @"HOURLY_FORECAST";
MWInfoType const MWInfoTypeAlerts = @"ALERTS";


NS_ASSUME_NONNULL_BEGIN

@interface SmartDeviceLinkService () <SDLManagerDelegate, SDLChoiceSetDelegate>

@property SDLManager *manager;

@property (nonatomic, strong, nullable) NSArray *templatesAvailable;
@property (nonatomic, strong, nullable) SDLLanguage language;
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
    self.firstHMIFullOccurred = NO;
    self.currentKnownAlerts = [NSMutableSet set];
    self.currentInfoType = nil;
    self.currentInfoTypeList = nil;
    self.currentInfoTypeListIndex = -1;
    self.currentForecastChoices = nil;
}

- (void)start {
    [self resetProperties];

    self.localization = [Localization defaultLocalization];
    
    // Change which config you need based on if you want to connect to a TDK (default) or a wifi based emulator (debug)
    SDLLifecycleConfiguration *lifecycleConfig = [SDLLifecycleConfiguration defaultConfigurationWithAppName:@"SDL Weather" fullAppId:@"330533107"];
//    SDLLifecycleConfiguration *lifecycleConfig = [SDLLifecycleConfiguration debugConfigurationWithAppName:@"SDL Weather" fullAppId:@"330533107" ipAddress:@"192.168.45.2" port:12345];
    lifecycleConfig.ttsName = [SDLTTSChunk textChunksFromString:NSLocalizedString(@"app.tts-name", nil)];
    lifecycleConfig.voiceRecognitionCommandNames = @[NSLocalizedString(@"app.vr-synonym", nil)];
    lifecycleConfig.appIcon = [SDLArtwork persistentArtworkWithImage:[UIImage imageNamed:@"sdl-appicon"] name:@"AppIcon" asImageFormat:SDLArtworkImageFormatPNG];
    lifecycleConfig.language = SDLLanguageEnUs;
    lifecycleConfig.languagesSupported = @[SDLLanguageEnUs, SDLLanguageEnGb, SDLLanguageEnAu, SDLLanguageDeDe, SDLLanguageEsEs, SDLLanguageEsMx, SDLLanguagePtPt, SDLLanguagePtBr, SDLLanguageFrFr, SDLLanguageFrCa];

    // inform the app about language change to get new weather data
    NSString *languageString = [SDLLanguageEnUs substringWithRange:NSMakeRange(0, 2)].uppercaseString;
    WeatherLanguage *wlanguage = [WeatherLanguage elementWithValue:languageString];
    [[NSNotificationCenter defaultCenter] postNotificationName:MobileWeatherLanguageUpdateNotification object:self userInfo:@{ @"language" : wlanguage }];
    
    SDLConfiguration *config = [[SDLConfiguration alloc] initWithLifecycle:lifecycleConfig lockScreen:[SDLLockScreenConfiguration enabledConfiguration] logging:self.mw_logConfig fileManager:[SDLFileManagerConfiguration defaultConfiguration] encryption:[SDLEncryptionConfiguration defaultConfiguration]];
    
    self.manager = [[SDLManager alloc] initWithConfiguration:config delegate:self];
    
    // Create a proxy object by simply using the factory class.
    [self.manager startWithReadyHandler:^(BOOL success, NSError * _Nullable error) {
        self.graphicsAvailable = self.manager.systemCapabilityManager.defaultMainWindowCapability.imageFields.count > 0;
        self.templatesAvailable = self.manager.systemCapabilityManager.defaultMainWindowCapability.templatesAvailable;
        
        // set the app display layout to the non-media template
        if ([self.templatesAvailable containsObject:SDLPredefinedLayoutNonMedia]) {
            SDLTemplateConfiguration *template = [[SDLTemplateConfiguration alloc] initWithPredefinedLayout:SDLPredefinedLayoutNonMedia];
            [self.manager.screenManager changeLayout:template withCompletionHandler:nil];
        } else {
            // This head unit isn't supported
            SDLLogE(@"The non-media template isn't supported. This app may not work properly");
        }
    }];
}

- (void)stop {
    [self.manager stop];
}

- (SDLLogConfiguration *)mw_logConfig {
    SDLLogConfiguration *config = [SDLLogConfiguration debugConfiguration];
    config.disableAssertions = YES;

    SDLLogFileModule *sdlModule = [[SDLLogFileModule alloc] initWithName:@"MobileWeather/SDL" files:[NSSet setWithObject:@"SmartDeviceLinkService"]];
    SDLLogFileModule *weatherModule = [[SDLLogFileModule alloc] initWithName:@"MobileWeather/Weather" files:[NSSet setWithObjects:@"DarkSkyProcessor", @"DarkSkyService", nil]];
    [config.modules setByAddingObjectsFromSet:[NSSet setWithArray:@[sdlModule, weatherModule]]];

    return config;
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
        [self sendDefaultGlobalProperties];
        [self preloadChangeUnitsChoices];

        self.manager.screenManager.menuConfiguration = [[SDLMenuConfiguration alloc] initWithMainMenuLayout:SDLMenuLayoutTiles defaultSubmenuLayout:SDLMenuLayoutTiles];
        self.manager.screenManager.menu = [self weatherMenuCells];
    }
}

- (nullable SDLLifecycleConfigurationUpdate *)managerShouldUpdateLifecycleToLanguage:(SDLLanguage)language hmiLanguage:(SDLLanguage)hmiLanguage {
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
        SDLAlert *request = [[SDLAlert alloc] initWithAlertText1:alert.title alertText2:[formatterShow stringFromDate:alert.dateExpires] alertText3:nil softButtons:nil playTone:NO ttsChunks:chunks duration:10000 progressIndicator:NO alertIcon:nil cancelID:0];
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

#pragma mark - Choice Sets

- (NSArray<SDLChoiceCell *> *)changeUnitsChoiceCells {
    SDLChoiceCell *metric = [[SDLChoiceCell alloc] initWithText:self.localization[@"choice.units.metric"] artwork:nil voiceCommands:@[self.localization[@"vr.metric"]]];
    SDLChoiceCell *imperial = [[SDLChoiceCell alloc] initWithText:self.localization[@"choice.units.imperial"] artwork:nil voiceCommands:@[self.localization[@"vr.imperial"]]];

    return @[metric, imperial];
}

- (void)preloadChangeUnitsChoices {
    [self.manager.screenManager preloadChoices:[self changeUnitsChoiceCells] withCompletionHandler:nil];
}

- (void)presentChangeUnitsInteraction:(SDLInteractionMode)mode {
    SDLChoiceSet *changeUnits = [[SDLChoiceSet alloc] initWithTitle:self.localization[@"pi.units.text"] delegate:self layout:SDLChoiceSetLayoutList timeout:30 initialPromptString:self.localization[@"pi.units.initial-prompt"] timeoutPromptString:self.localization[@"pi.units.timeout-prompt"] helpPromptString:nil vrHelpList:nil choices:[self changeUnitsChoiceCells]];

    [self.manager.screenManager presentChoiceSet:changeUnits mode:mode];
}

- (void)presentForecastInteractionWithList:(NSArray *)forecasts ofType:(MWInfoType)infoType mode:(SDLInteractionMode)mode {
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

    NSMutableArray<SDLChoiceCell *> *choices = [NSMutableArray array];
    for (Forecast *forecast in forecasts) {
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

        NSString *precipitationChanceString = [NSString stringWithFormat:@"Precipitation chance: %@", [forecast.precipitationChance stringValueForUnit:UnitPercentageDefault shortened:YES localization:self.localization]];
        SDLChoiceCell *cell = [[SDLChoiceCell alloc] initWithText:[dateFormatShow stringFromDate:forecast.date] secondaryText:precipitationChanceString tertiaryText:nil voiceCommands:[vrCommands copy] artwork:[SDLArtwork artworkWithImage:[[[ImageProcessor sharedProcessor] imageFromConditionImage:forecast.conditionIcon] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] asImageFormat:SDLArtworkImageFormatPNG] secondaryArtwork:nil];
        [choices addObject:cell];
    }

    SDLChoiceSet *choiceSet = nil;
    if ([self.currentInfoType isEqualToString:MWInfoTypeDailyForecast]) {
        choiceSet = [[SDLChoiceSet alloc] initWithTitle:self.localization[@"pi.daily-forecast.text"] delegate:self layout:SDLChoiceSetLayoutTiles timeout:60 initialPromptString:self.localization[@"pi.daily-forecast.initial-prompt"] timeoutPromptString:self.localization[@"pi.daily-forecast.timeout-prompt"] helpPromptString:self.localization[@"pi.daily-forecast.help-prompt"] vrHelpList:nil choices:choices];
    } else if ([self.currentInfoType isEqualToString:MWInfoTypeHourlyForecast]) {
        choiceSet = [[SDLChoiceSet alloc] initWithTitle:self.localization[@"pi.hourly-forecast.text"] delegate:self layout:SDLChoiceSetLayoutTiles timeout:60 initialPromptString:self.localization[@"pi.hourly-forecast.initial-prompt"] timeoutPromptString:self.localization[@"pi.hourly-forecast.timeout-prompt"] helpPromptString:self.localization[@"pi.hourly-forecast.help-prompt"] vrHelpList:nil choices:choices];
    }

    [self.manager.screenManager presentChoiceSet:choiceSet mode:mode];
}


#pragma mark - Template updates

- (void)sendWeatherConditions:(WeatherConditions *)conditions withSpeak:(BOOL)withSpeak {
    if (conditions == nil) {
        SDLAlertView *alertRequest = [[SDLAlertView alloc] initWithText:self.localization[@"alert.no-conditions.field1"] secondaryText:self.localization[@"alert.no-conditions.field2"] tertiaryText:nil timeout:@(10) showWaitIndicator:nil audioIndication:[[SDLAlertAudioData alloc] initWithSpeechSynthesizerString:self.localization[@"alert.no-forecast.prompt"]] buttons:nil icon:nil];
        [self.manager.screenManager presentAlert:alertRequest withCompletionHandler:nil];
    }

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

    self.manager.screenManager.primaryGraphic = [SDLArtwork artworkWithImage:[[[ImageProcessor sharedProcessor] imageFromConditionImage:conditions.conditionIcon] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] name:conditions.conditionIcon asImageFormat:SDLArtworkImageFormatPNG];

    [self.manager.screenManager endUpdatesWithCompletionHandler:nil];

    if (withSpeak) {
        SDLSpeak *speakRequest = [[SDLSpeak alloc] initWithTTS:[self.localization stringForKey:@"conditions.speak", conditions.conditionTitle, [conditions.temperature stringValueForUnit:temperatureType shortened:NO localization:self.localization], [conditions.humidity stringValueForUnit:percentageType shortened:NO localization:self.localization], [conditions.windSpeed stringValueForUnit:speedType shortened:NO localization:self.localization]]];
        [self.manager sendRequest:speakRequest];
    }
}

- (void)sendForecastList:(NSArray *)forecasts infoType:(MWInfoType)infoType withSpeak:(BOOL)withSpeak {
    if (forecasts == nil || forecasts.count == 0) {
        SDLAlertView *alertRequest = [[SDLAlertView alloc] initWithText:self.localization[@"alert.no-forecast.field1"] secondaryText:self.localization[@"alert.no-forecast.field2"] tertiaryText:nil timeout:@(10) showWaitIndicator:nil audioIndication:[[SDLAlertAudioData alloc] initWithSpeechSynthesizerString:self.localization[@"alert.no-forecast.prompt"]] buttons:nil icon:nil];
        [self.manager.screenManager presentAlert:alertRequest withCompletionHandler:nil];
    }

    if ([infoType isEqualToString:MWInfoTypeDailyForecast]) {
        forecasts = [forecasts subarrayWithRange:NSMakeRange(0, MIN(forecasts.count, 7))];
    } else if ([infoType isEqualToString:MWInfoTypeHourlyForecast]) {
        forecasts = [forecasts subarrayWithRange:NSMakeRange(0, MIN(forecasts.count, 24))];
    }
    NSUInteger index = 0;
    if ([infoType isEqualToString:self.currentInfoType]) {
        Forecast *oldForecast = (self.currentInfoTypeList)[self.currentInfoTypeListIndex];

        for (NSUInteger newindex = 0; newindex < forecasts.count; newindex++) {
            Forecast *newForecast = forecasts[index];

            if ([newForecast.date isEqualToDate:oldForecast.date]) {
                index = newindex;
                break;
            }
        }
    } else {
        self.manager.screenManager.menu = [self listMenuCellsForType:infoType];
        self.manager.screenManager.voiceCommands = [self listVoiceCommandsForType:infoType];
    }

    [self showForecastAtIndex:index fromList:forecasts infoType:infoType withSpeak:withSpeak];

    self.currentInfoType = infoType;
    self.currentInfoTypeList = forecasts;
    self.currentInfoTypeListIndex = index;
}

- (void)showForecastAtIndex:(NSUInteger)index fromList:(NSArray<Forecast *> *)forecasts infoType:(MWInfoType)infoType withSpeak:(BOOL)withSpeak {
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

    [self.manager.screenManager beginUpdates];
    self.manager.screenManager.softButtonObjects = [self buildListSoftButtons:infoType withIndex:index maxCount:forecasts.count];

    self.manager.screenManager.primaryGraphic = [SDLArtwork artworkWithImage:[[[ImageProcessor sharedProcessor] imageFromConditionImage:forecast.conditionIcon] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] asImageFormat:SDLArtworkImageFormatPNG];
    
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

#pragma mark - Alerts

- (void)sendAlertList:(NSArray *)alerts withSpeak:(BOOL)withSpeak {
    if (alerts.count == 0) {
        SDLAlertView *alertRequest = [[SDLAlertView alloc] initWithText:self.localization[@"alert.no-alerts.field1"] secondaryText:self.localization[@"alert.no-alerts.field2"] tertiaryText:nil timeout:@(4) showWaitIndicator:nil audioIndication:[[SDLAlertAudioData alloc] initWithSpeechSynthesizerString:self.localization[@"alert.no-alerts.prompt"]] buttons:nil icon:nil];

        [self.manager.screenManager presentAlert:alertRequest withCompletionHandler:nil];

        return;
    }

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
        self.manager.screenManager.menu = [self listMenuCellsForType:MWInfoTypeAlerts];
        self.manager.screenManager.voiceCommands = [self listVoiceCommandsForType:MWInfoTypeAlerts];
    }

    [self sendAlertAtIndex:index fromList:alerts withSpeak:withSpeak];

    self.currentInfoType = MWInfoTypeAlerts;
    self.currentInfoTypeList = alerts;
    self.currentInfoTypeListIndex = index;
}

- (void)sendAlertAtIndex:(NSUInteger)index fromList:(NSArray<Alert *> *)alerts withSpeak:(BOOL)withSpeak {
    Alert *alert = alerts[index];
    [self.currentKnownAlerts addObject:alert];

    NSDateFormatter *dateTimeFormatShow = [[NSDateFormatter alloc] init];
    dateTimeFormatShow.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    dateTimeFormatShow.locale = (self.localization).locale;
    dateTimeFormatShow.dateFormat = self.localization[@"weather-alerts.format.date-time.show"];
    
    NSString *dateTimeStringShow = [dateTimeFormatShow stringFromDate:alert.dateExpires];

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

    SDLScrollableMessage *message = [[SDLScrollableMessage alloc] initWithMessage:description timeout:60000 softButtons:nil cancelID:0];
    [self.manager sendRequest:message];
}

@end

NS_ASSUME_NONNULL_END
