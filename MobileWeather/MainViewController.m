//
//  MainViewController.m
//  MobileWeather
//
//  Copyright (c) 2013-2015 Ford Motor Company. All rights reserved.
//

#import "MainViewController.h"

#import "Notifications.h"
#import "ImageProcessor.h"
#import "PercentageNumber.h"
#import "TemperatureNumber.h"
#import "SpeedNumber.h"
#import "WeatherService.h"
#import "WeatherDataManager.h"
#import "UnitConverter.h"
#import "WeatherConditions.h"
#import "WeatherLanguage.h"
#import "WeatherLocation.h"


@interface MainViewController ()

@property (weak, nonatomic) IBOutlet UILabel *currentConditionsLabel;
@property (weak, nonatomic) IBOutlet UILabel *currentTempLabel;
@property (weak, nonatomic) IBOutlet UILabel *windSpeedLabel;
@property (weak, nonatomic) IBOutlet UILabel *precipitationChanceLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;
@property (weak, nonatomic) IBOutlet UIImageView *conditionIcon;
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;

@end


@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    WeatherLocation *location = [WeatherDataManager sharedManager].currentLocation;
    [self setLocationLabelFromWeatherLocation:location];
    
    NSDictionary *bundle = [NSBundle mainBundle].infoDictionary;
    NSString *bundleAppVersion = bundle[@"CFBundleShortVersionString"];
    NSString *bundleBuildVersion = bundle[@"CFBundleVersion"];
    
    self.versionLabel.text = [NSString stringWithFormat:@"%@ (%@)", bundleAppVersion, bundleBuildVersion];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleLocationUpdate:) name:MobileWeatherLocationUpdateNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleWeatherUpdate:) name:MobileWeatherDataUpdatedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleUnitUpdate:) name:MobileWeatherUnitChangedNotification object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)handleLocationUpdate:(NSNotification *)notification {
    WeatherLocation *location = notification.userInfo[@"location"];
    [self setLocationLabelFromWeatherLocation:location];
}

- (void)handleUnitUpdate:(NSNotification *)notification {
    WeatherDataManager *data = [WeatherDataManager sharedManager];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self setWeatherConditions:data.weatherConditions withLanguage:data.language];
    });
}

- (void)setLocationLabelFromWeatherLocation:(WeatherLocation *)location {
    NSString *locationText;
    
    if (location) {
        locationText = [NSString stringWithFormat:@"%@, %@, %@", location.city, location.state, location.country];
    } else {
        locationText = @"...";
    }

    self.locationLabel.text = locationText;
}

- (void)handleWeatherUpdate:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    WeatherConditions *conditions = userInfo[@"weatherConditions"];
    WeatherLanguage *language = userInfo[@"language"];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self setWeatherConditions:conditions withLanguage:language];
    });
}

- (void)setWeatherConditions:(WeatherConditions *)conditions withLanguage:(WeatherLanguage *)language {
    NSDate *date = conditions.date;

    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    formatter.locale = [NSLocale localeWithLocaleIdentifier:language.value];
    formatter.dateStyle = NSDateFormatterFullStyle;
    formatter.timeStyle = NSDateFormatterMediumStyle;
    
    NSString *status = [formatter stringFromDate:date];

    self.statusLabel.text = status;
    self.currentConditionsLabel.text = conditions.conditionTitle;
    self.conditionIcon.image = [[ImageProcessor sharedProcessor] imageFromConditionImage:conditions.conditionIcon imageSize:ImageSizeLargeGraphic_256];
    self.precipitationChanceLabel.text = [conditions.precipitation stringValueForUnit:UnitPercentageDefault shortened:YES];
    
    if ([WeatherDataManager sharedManager].unit == UnitTypeImperial) {
        self.currentTempLabel.text = [conditions.temperature stringValueForUnit:UnitTemperatureFahrenheit shortened:YES];
        self.windSpeedLabel.text = [conditions.windSpeed stringValueForUnit:UnitSpeedMileHour shortened:YES];
    } else if ([WeatherDataManager sharedManager].unit == UnitTypeMetric) {
        self.currentTempLabel.text = [conditions.temperature stringValueForUnit:UnitTemperatureCelsius shortened:YES];
        self.windSpeedLabel.text = [conditions.windSpeed stringValueForUnit:UnitSpeedKiloMeterHour shortened:YES];
    } else {
        self.currentTempLabel.text = [conditions.temperature stringValueForUnit:UnitTemperatureCelsius shortened:YES];
        self.windSpeedLabel.text = [conditions.windSpeed stringValueForUnit:UnitSpeedMeterSecond shortened:YES];
    }
}

@end
