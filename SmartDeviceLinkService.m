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

    self.localization = [Localization defaultLocalization];
    
    // Change which config you need based on if you want to connect to a TDK (default) or a wifi based emulator (debug)
//    SDLLifecycleConfiguration *lifecycleConfig = [SDLLifecycleConfiguration defaultConfigurationWithAppName:@"MobileWeather" fullAppId:@"330533107"];
    SDLLifecycleConfiguration *lifecycleConfig = [SDLLifecycleConfiguration debugConfigurationWithAppName:@"MobileWeather" fullAppId:@"330533107" ipAddress:@"m.sdl.tools" port:11427];
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
            SDLSetDisplayLayout *request = [[SDLSetDisplayLayout alloc] initWithLayout:SDLPredefinedLayoutNonMedia];
            [self.manager sendRequest:request];
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

        SDLChoiceCell *cell = [[SDLChoiceCell alloc] initWithText:[dateFormatShow stringFromDate:forecast.date] artwork:[SDLArtwork artworkWithImage:[[[ImageProcessor sharedProcessor] imageFromConditionImage:forecast.conditionIcon] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] asImageFormat:SDLArtworkImageFormatPNG] voiceCommands:[vrCommands copy]];
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

- (void)sendWeatherConditions:(WeatherConditions *)conditions withSpeak:(BOOL)withSpeak {
    if (conditions == nil) {
        SDLAlert *alertRequest = [[SDLAlert alloc] initWithAlertText1:self.localization[@"alert.no-conditions.field1"] alertText2:self.localization[@"alert.no-conditions.field2"] alertText3:nil softButtons:nil playTone:NO ttsChunks:self.localization[@"alert.no-forecast.prompt"] duration:10000 progressIndicator:NO alertIcon:nil cancelID:0];
        [self.manager sendRequest:alertRequest];
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
        SDLAlert *alertRequest = [[SDLAlert alloc] initWithAlertText1:self.localization[@"alert.no-forecast.field1"] alertText2:self.localization[@"alert.no-forecast.field2"] alertText3:nil softButtons:nil playTone:NO ttsChunks:self.localization[@"alert.no-forecast.prompt"] duration:10000 progressIndicator:NO alertIcon:nil cancelID:0];
        [self.manager sendRequest:alertRequest];
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
        SDLAlert *alertRequest = [[SDLAlert alloc] initWithAlertText1:self.localization[@"alert.no-alerts.field1"] alertText2:self.localization[@"alert.no-alerts.field2"] alertText3:nil softButtons:nil playTone:NO ttsChunks:self.localization[@"alert.no-alerts.prompt"] duration:10000 progressIndicator:NO alertIcon:nil cancelID:0];
        [self.manager sendRequest:alertRequest];
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

- (void)closeListInfoType:(MWInfoType)infoType {
    self.currentInfoType = MWInfoTypeNone;
    [self setCurrentInfoTypeList:nil];
    self.currentInfoTypeListIndex = -1;
    
    [self sendWelcomeMessageWithSpeak:NO];
    [self sendDefaultGlobalProperties];

    self.manager.screenManager.menu = [self weatherMenuCells];
}

- (void)repeatWeatherInformation {
    MWInfoType infoType = self.currentInfoType;
    if ([MWInfoTypeWeatherConditions isEqualToString:infoType]) {
        [self sendWeatherConditions:[WeatherDataManager sharedManager].weatherConditions withSpeak:YES];
    } else if ([MWInfoTypeDailyForecast isEqualToString:infoType] || [MWInfoTypeHourlyForecast isEqualToString:infoType]) {
        [self showForecastAtIndex:self.currentInfoTypeListIndex fromList:self.currentInfoTypeList infoType:infoType withSpeak:YES];
    } else if ([MWInfoTypeAlerts isEqualToString:infoType]) {
        [self sendAlertAtIndex:self.currentInfoTypeListIndex fromList:self.currentInfoTypeList withSpeak:YES];
    }
}

#pragma mark - Soft Buttons

- (NSArray<SDLSoftButtonObject *> *)buildDefaultSoftButtons {
    __weak typeof(self) weakSelf = self;
    SDLSoftButtonState *currentWeatherState = [[SDLSoftButtonState alloc] initWithStateName:@"state" text:self.localization[@"sb.current"] image:[[UIImage imageNamed:@"clear-day"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    SDLSoftButtonObject *currentWeatherObject = [[SDLSoftButtonObject alloc] initWithName:@"CurrentWeather" state:currentWeatherState handler:^(SDLOnButtonPress * _Nullable buttonPress, SDLOnButtonEvent * _Nullable buttonEvent) {
        if (!buttonPress) {
            return;
        }

        [weakSelf sendWeatherConditions:[WeatherDataManager sharedManager].weatherConditions withSpeak:YES];
    }];

    SDLSoftButtonState *dailyForecastState = [[SDLSoftButtonState alloc] initWithStateName:@"state" text:self.localization[@"sb.daily"] image:[[UIImage imageNamed:@"menu-day"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    SDLSoftButtonObject *dailyForecastObject = [[SDLSoftButtonObject alloc] initWithName:@"DailyForecast" state:dailyForecastState handler:^(SDLOnButtonPress * _Nullable buttonPress, SDLOnButtonEvent * _Nullable buttonEvent) {
        if (!buttonPress) {
            return;
        }

        [weakSelf sendForecastList:[WeatherDataManager sharedManager].dailyForecast infoType:MWInfoTypeDailyForecast withSpeak:YES];
    }];

    SDLSoftButtonState *hourlyForecastState = [[SDLSoftButtonState alloc] initWithStateName:@"state" text:self.localization[@"sb.hourly"] image:[[UIImage imageNamed:@"menu-time"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    SDLSoftButtonObject *hourlyForecastObject = [[SDLSoftButtonObject alloc] initWithName:@"HourlyForecast" state:hourlyForecastState handler:^(SDLOnButtonPress * _Nullable buttonPress, SDLOnButtonEvent * _Nullable buttonEvent) {
        if (!buttonPress) {
            return;
        }

        [weakSelf sendForecastList:[WeatherDataManager sharedManager].hourlyForecast infoType:MWInfoTypeHourlyForecast withSpeak:YES];
    }];

    SDLSoftButtonState *alertsState = [[SDLSoftButtonState alloc] initWithStateName:@"state" text:self.localization[@"sb.alerts"] image:[[UIImage imageNamed:@"menu-alert"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
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

    SDLSoftButtonState *previousState = [[SDLSoftButtonState alloc] initWithStateName:@"state" text:@"<- Previous" image:nil];
    SDLSoftButtonState *previousUnavailableState = [[SDLSoftButtonState alloc] initWithStateName:@"blank" text:@"-" image:nil];

    NSString *initialPreviousState = ((index != 0) ? @"state" : @"blank");
    SDLSoftButtonObject *previousObject = [[SDLSoftButtonObject alloc] initWithName:@"Previous" states:@[previousState, previousUnavailableState] initialStateName:initialPreviousState handler:^(SDLOnButtonPress * _Nullable buttonPress, SDLOnButtonEvent * _Nullable buttonEvent) {
        if (!buttonPress) { return; }

        MWInfoType infoType = weakSelf.currentInfoType;
        if (weakSelf.currentInfoTypeListIndex > 0) {
            NSInteger index = weakSelf.currentInfoTypeListIndex - 1;
            if ([infoType isEqualToString:MWInfoTypeDailyForecast] || [infoType isEqualToString:MWInfoTypeHourlyForecast]) {
                [weakSelf showForecastAtIndex:index fromList:weakSelf.currentInfoTypeList infoType:infoType withSpeak:YES];
            }
            weakSelf.currentInfoTypeListIndex = index;
        }
    }];

    SDLSoftButtonState *nextState = [[SDLSoftButtonState alloc] initWithStateName:@"state" text:@"Next ->" image:nil];
    SDLSoftButtonState *nextUnavailableState = [[SDLSoftButtonState alloc] initWithStateName:@"blank" text:@"-" image:nil];

    NSString *initialNextState = ((index + 1 != count) ? @"state" : @"blank");
    SDLSoftButtonObject *nextObject = [[SDLSoftButtonObject alloc] initWithName:@"Next" states:@[nextState, nextUnavailableState] initialStateName:initialNextState handler:^(SDLOnButtonPress * _Nullable buttonPress, SDLOnButtonEvent * _Nullable buttonEvent) {
        if (!buttonPress) { return; }

        MWInfoType infoType = weakSelf.currentInfoType;
        if (weakSelf.currentInfoTypeListIndex + 1 < weakSelf.currentInfoTypeList.count) {
            NSInteger index = weakSelf.currentInfoTypeListIndex + 1;
            if ([infoType isEqualToString:MWInfoTypeDailyForecast] || [infoType isEqualToString:MWInfoTypeHourlyForecast]) {
                [weakSelf showForecastAtIndex:index fromList:weakSelf.currentInfoTypeList infoType:infoType withSpeak:YES];
            }
            weakSelf.currentInfoTypeListIndex = index;
        }
    }];

    SDLSoftButtonObject *showObject = nil;
    if ([MWInfoTypeDailyForecast isEqualToString:infoType] || [MWInfoTypeHourlyForecast isEqualToString:infoType]) {
        SDLSoftButtonState *showListState = [[SDLSoftButtonState alloc] initWithStateName:@"state" text:self.localization[@"sb.list"] image:nil];
        showObject = [[SDLSoftButtonObject alloc] initWithName:@"ShowList" state:showListState handler:^(SDLOnButtonPress * _Nullable buttonPress, SDLOnButtonEvent * _Nullable buttonEvent) {
            if (!buttonPress) { return; }

            [weakSelf presentForecastInteractionWithList:weakSelf.currentInfoTypeList ofType:infoType mode:SDLInteractionModeManualOnly];
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

#pragma mark - Menus

- (NSArray<SDLMenuCell *> *)weatherMenuCells {
    __weak typeof(self) weakSelf = self;
    SDLMenuCell *showWeatherConditions = [[SDLMenuCell alloc] initWithTitle:self.localization[@"cmd.current-conditions"] icon:[[SDLArtwork alloc] initWithImage:[[UIImage imageNamed:@"clear-day"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] persistent:YES asImageFormat:SDLArtworkImageFormatPNG] voiceCommands:@[self.localization[@"vr.current"],self.localization[@"vr.conditions"], self.localization[@"vr.current-conditions"], self.localization[@"vr.show-conditions"], self.localization[@"vr.show-current-conditions"]] handler:^(SDLTriggerSource _Nonnull triggerSource) {
        [weakSelf sendWeatherConditions:[WeatherDataManager sharedManager].weatherConditions withSpeak:YES];
    }];

    SDLMenuCell *showDailyForecast = [[SDLMenuCell alloc] initWithTitle:self.localization[@"cmd.daily-forecast"] icon:[[SDLArtwork alloc] initWithImage:[[UIImage imageNamed:@"menu-day"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] persistent:YES asImageFormat:SDLArtworkImageFormatPNG] voiceCommands:@[self.localization[@"vr.daily"], self.localization[@"vr.daily-forecast"], self.localization[@"vr.show-daily-forecast"]] handler:^(SDLTriggerSource _Nonnull triggerSource) {
        [weakSelf sendForecastList:[WeatherDataManager sharedManager].dailyForecast infoType:MWInfoTypeDailyForecast withSpeak:YES];
    }];

    SDLMenuCell *showHourlyForecast = [[SDLMenuCell alloc] initWithTitle:self.localization[@"cmd.hourly-forecast"] icon:[[SDLArtwork alloc] initWithImage:[[UIImage imageNamed:@"menu-time"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] persistent:YES asImageFormat:SDLArtworkImageFormatPNG] voiceCommands:@[self.localization[@"vr.hourly"], self.localization[@"vr.hourly-forecast"], self.localization[@"vr.show-hourly-forecast"]] handler:^(SDLTriggerSource _Nonnull triggerSource) {
        [weakSelf sendForecastList:[WeatherDataManager sharedManager].hourlyForecast infoType:MWInfoTypeHourlyForecast withSpeak:YES];
    }];

    SDLMenuCell *showAlerts = [[SDLMenuCell alloc] initWithTitle:self.localization[@"cmd.alerts"] icon:[[SDLArtwork alloc] initWithImage:[[UIImage imageNamed:@"menu-alert"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] persistent:YES asImageFormat:SDLArtworkImageFormatPNG] voiceCommands:@[self.localization[@"vr.alerts"], self.localization[@"vr.show-alerts"]] handler:^(SDLTriggerSource _Nonnull triggerSource) {
        [weakSelf sendAlertList:[WeatherDataManager sharedManager].alerts withSpeak:YES];
    }];

    SDLMenuCell *changeUnits = [[SDLMenuCell alloc] initWithTitle:self.localization[@"cmd.change-units"] icon:[[SDLArtwork alloc] initWithImage:[[UIImage imageNamed:@"menu-units"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] persistent:YES asImageFormat:SDLArtworkImageFormatPNG] voiceCommands:@[self.localization[@"vr.units"], self.localization[@"vr.change-units"]] handler:^(SDLTriggerSource _Nonnull triggerSource) {
        SDLInteractionMode mode = [triggerSource isEqualToEnum:SDLTriggerSourceMenu] ? SDLInteractionModeManualOnly : SDLInteractionModeBoth;
        [weakSelf presentChangeUnitsInteraction:mode];
    }];

    return @[showWeatherConditions, showDailyForecast, showHourlyForecast, showAlerts, changeUnits];
}

- (NSArray<SDLMenuCell *> *)listMenuCellsForType:(MWInfoType)infoType {
    __weak typeof(self) weakSelf = self;
    NSMutableArray<SDLMenuCell *> *menu = [NSMutableArray array];

    if ([infoType isEqualToString:MWInfoTypeDailyForecast] || [infoType isEqualToString:MWInfoTypeHourlyForecast]) {
         [menu addObject:[[SDLMenuCell alloc] initWithTitle:self.localization[@"cmd.show-list"] icon:nil voiceCommands:@[self.localization[@"vr.list"], self.localization[@"vr.show-list"]] handler:^(SDLTriggerSource  _Nonnull triggerSource) {
            SDLInteractionMode mode = [triggerSource isEqualToEnum:SDLTriggerSourceMenu] ? SDLInteractionModeManualOnly : SDLInteractionModeBoth;
             [weakSelf presentForecastInteractionWithList:weakSelf.currentInfoTypeList ofType:infoType mode:mode];
        }]];
    } else if ([MWInfoTypeAlerts isEqualToString:infoType]) {
        [menu addObject:[[SDLMenuCell alloc] initWithTitle:self.localization[@"cmd.show-message"] icon:nil voiceCommands:@[self.localization[@"vr.message"], self.localization[@"vr.show-message"]] handler:^(SDLTriggerSource  _Nonnull triggerSource) {
            SDLInteractionMode mode = [triggerSource isEqualToEnum:SDLTriggerSourceMenu] ? SDLInteractionModeManualOnly : SDLInteractionModeBoth;
            [weakSelf presentForecastInteractionWithList:weakSelf.currentInfoTypeList ofType:infoType mode:mode];
        }]];
    }

    [menu addObject:[[SDLMenuCell alloc] initWithTitle:self.localization[@"cmd.back"] icon:nil voiceCommands:@[self.localization[@"vr.back"]] handler:^(SDLTriggerSource  _Nonnull triggerSource) {
        [weakSelf closeListInfoType:weakSelf.currentInfoType];
    }]];

    return [menu copy];
}

- (NSArray<SDLVoiceCommand *> *)listVoiceCommandsForType:(MWInfoType)infoType {
    __weak typeof(self) weakSelf = self;
    NSArray<SDLVoiceCommand *> *voiceCommands = nil;
    if ([infoType isEqualToString:MWInfoTypeHourlyForecast]) {
        SDLVoiceCommand *hourlyNow = [[SDLVoiceCommand alloc] initWithVoiceCommands:@[self.localization[@"vr.now"]] handler:^{
            [weakSelf showForecastAtIndex:0 fromList:weakSelf.currentInfoTypeList infoType:weakSelf.currentInfoType withSpeak:YES];
            weakSelf.currentInfoTypeListIndex = 0;
        }];

        voiceCommands = @[hourlyNow];
    } else {
        SDLVoiceCommand *dailyToday = [[SDLVoiceCommand alloc] initWithVoiceCommands:@[self.localization[@"vr.today"]] handler:^{
            [weakSelf showForecastAtIndex:0 fromList:weakSelf.currentInfoTypeList infoType:weakSelf.currentInfoType withSpeak:YES];
            weakSelf.currentInfoTypeListIndex = 0;
        }];

        SDLVoiceCommand *dailyTomorrow = [[SDLVoiceCommand alloc] initWithVoiceCommands:@[self.localization[@"vr.tomorrow"]] handler:^{
            [weakSelf showForecastAtIndex:1 fromList:weakSelf.currentInfoTypeList infoType:weakSelf.currentInfoType withSpeak:YES];
            weakSelf.currentInfoTypeListIndex = 1;
        }];

        voiceCommands = @[dailyToday, dailyTomorrow];
    }

    return voiceCommands;
}

#pragma mark - Global Properties / Help Lists

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
    
    NSString *promptString = [prompts componentsJoinedByString:@","];

    SDLSetGlobalProperties *request = [[SDLSetGlobalProperties alloc] initWithHelpText:promptString timeoutText:promptString vrHelpTitle:self.localization[@"app.name"] vrHelp:[helpitems copy] menuTitle:nil menuIcon:nil keyboardProperties:nil menuLayout:nil];
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
    
    NSString *promptString = [prompts componentsJoinedByString:@","];

    SDLSetGlobalProperties *request = [[SDLSetGlobalProperties alloc] initWithHelpText:promptString timeoutText:promptString vrHelpTitle:self.localization[@"app.name"] vrHelp:[items copy] menuTitle:nil menuIcon:nil keyboardProperties:nil menuLayout:nil];
    [self.manager sendRequest:request]; 
}

#pragma mark - SDLChoiceSetDelegate

- (void)choiceSet:(SDLChoiceSet *)choiceSet didSelectChoice:(SDLChoiceCell *)choice withSource:(SDLTriggerSource)source atRowIndex:(NSUInteger)rowIndex {
    if ([choiceSet.title isEqualToString:self.localization[@"pi.units.text"]]) {
        [self mw_changeUnitsDidSelectChoice:choice atIndex:rowIndex];
    } else {
        [self mw_forecastDidSelectChoice:choice atIndex:rowIndex];
    }
}

- (void)mw_changeUnitsDidSelectChoice:(SDLChoiceCell *)cell atIndex:(NSUInteger)rowIndex {
    UnitType unit = (rowIndex == 0) ? UnitTypeMetric : UnitTypeImperial;
    [WeatherDataManager sharedManager].unit = unit;
}

- (void)mw_forecastDidSelectChoice:(SDLChoiceCell *)cell atIndex:(NSUInteger)rowIndex {
    [self showForecastAtIndex:rowIndex fromList:self.currentInfoTypeList infoType:self.currentInfoType withSpeak:YES];
    self.currentInfoTypeListIndex = rowIndex;
}

- (void)choiceSet:(SDLChoiceSet *)choiceSet didReceiveError:(NSError *)error {
    SDLLogE(@"Choice Set did error: %@", error);
}

@end

NS_ASSUME_NONNULL_END
