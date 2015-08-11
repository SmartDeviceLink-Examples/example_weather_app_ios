//
//  MainViewController.m
//  MobileWeather
//
//  Copyright (c) 2013-2015 Ford Motor Company. All rights reserved.
//

#import "MainViewController.h"
#import "ImageProcessor.h"
#import "WeatherService.h"
#import "WeatherDataManager.h"
#import "UnitConverter.h"

@interface MainViewController ()

@property (weak, nonatomic) IBOutlet UILabel *currentConditionsLabel;

@property (weak, nonatomic) IBOutlet UILabel *currentTempLabel;

@property (weak, nonatomic) IBOutlet UILabel *windSpeedLabel;

@property (weak, nonatomic) IBOutlet UILabel *humidityLabel;

@property (weak, nonatomic) IBOutlet UILabel *statusLabel;

@property (weak, nonatomic) IBOutlet UILabel *locationLabel;

@property (weak, nonatomic) IBOutlet UIImageView *conditionIcon;

@property (weak, nonatomic) IBOutlet UIImageView *serviceLogo;

@property (weak, nonatomic) IBOutlet UILabel *versionLabel;

@property (weak, nonatomic) IBOutlet UILabel *bundleLabel;

@end


@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    WeatherService *weatherService = [WeatherService sharedService];
    WeatherDataManager *manager = [WeatherDataManager sharedManager];
    
    if (weatherService) {
        UIImage *image = [weatherService serviceLogo];
        [self setServiceLogoFromImage:image];
    }
    
    if (manager) {
        WeatherLocation *location = [manager currentLocation];
        [self setLocationLabelFromWeatherLocation:location];
    }
    
    NSDictionary *bundle = [[NSBundle mainBundle] infoDictionary];
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    NSString *bundleAppVersion = [bundle objectForKey:@"CFBundleShortVersionString"];
    NSString *bundleBuildVersion = [bundle objectForKey:@"CFBundleVersion"];

    NSUInteger cputype = sizeof(void*) * 8;
    NSString *cputypestring = [NSString stringWithFormat:@"%lu bit", (unsigned long)cputype];
    
    [[self versionLabel] setText:[NSString stringWithFormat:@"%@: %@ (%@)", cputypestring, bundleAppVersion, bundleBuildVersion]];
    
    [[self bundleLabel] setText:bundleIdentifier];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleServiceLogo:) name:MobileWeatherServiceLoadedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleLocationUpdate:) name:MobileWeatherLocationUpdateNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleWeatherUpdate:) name:MobileWeatherDataUpdatedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleUnitUpdate:) name:MobileWeatherUnitChangedNotification object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (void)handleServiceLogo:(NSNotification *)notification {
    UIImage *image = [[notification userInfo] objectForKey:@"image"];
    [self setServiceLogoFromImage:image];
}

- (void)setServiceLogoFromImage:(UIImage *)image {
    [[self serviceLogo] setImage:image];
}

- (void)handleLocationUpdate:(NSNotification *)notification {
    WeatherLocation *location = [[notification userInfo] objectForKey:@"location"];
    [self setLocationLabelFromWeatherLocation:location];
}

- (void)handleUnitUpdate:(NSNotification *)notification {
    WeatherDataManager *data = [WeatherDataManager sharedManager];
    [self setWeatherConditions:[data weatherConditions] withLanguage:[data language]];
}

- (void)setLocationLabelFromWeatherLocation:(WeatherLocation *)location {
    NSString *locationText;
    
    if (location) {
        locationText = [NSString stringWithFormat:@"%@, %@", [location country], [location city]];
    }
    else {
        locationText = @"...";
    }
    
    [[self locationLabel] setText:locationText];
}

- (void)handleWeatherUpdate:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    WeatherConditions *conditions = [userInfo objectForKey:@"weatherConditions"];
    WeatherLanguage *language = [userInfo objectForKey:@"language"];
    [self setWeatherConditions:conditions withLanguage:language];
}

- (void)setWeatherConditions:(WeatherConditions *)conditions withLanguage:(WeatherLanguage *)langugae {
    NSDate *date = [conditions date];

    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    [formatter setLocale:[NSLocale localeWithLocaleIdentifier:[langugae value]]];
    [formatter setDateStyle:NSDateFormatterFullStyle];
    [formatter setTimeStyle:NSDateFormatterMediumStyle];
    
    NSString *status = [formatter stringFromDate:date];
    
    [[self statusLabel] setText:status];
    [[self currentConditionsLabel] setText:[conditions conditionTitle]];
    [[self conditionIcon] setImage:[[ImageProcessor sharedProcessor] imageFromConditionImage:[conditions conditionIcon]]];
    [[self humidityLabel] setText:[[conditions humidity] stringValueForUnit:UnitPercentageDefault shortened:YES]];
    
    if ([[WeatherDataManager sharedManager] unit] == UnitTypeImperial) {
        [[self currentTempLabel] setText:[[conditions temperature] stringValueForUnit:UnitTemperatureFahrenheit shortened:YES]];
        [[self windSpeedLabel] setText:[[conditions windSpeed] stringValueForUnit:UnitSpeedMileHour shortened:YES]];
    }
    else if ([[WeatherDataManager sharedManager] unit] == UnitTypeMetric) {
        [[self currentTempLabel] setText:[[conditions temperature] stringValueForUnit:UnitTemperatureCelsius shortened:YES]];
        [[self windSpeedLabel] setText:[[conditions windSpeed] stringValueForUnit:UnitSpeedKiloMeterHour shortened:YES]];
    }
    else {
        [[self currentTempLabel] setText:[[conditions temperature] stringValueForUnit:UnitTemperatureCelsius shortened:YES]];
        [[self windSpeedLabel] setText:[[conditions windSpeed] stringValueForUnit:UnitSpeedMeterSecond shortened:YES]];
    }
}

@end
