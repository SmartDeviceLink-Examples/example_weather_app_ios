//
//  LocationService.m
//  MobileWeather
//
//  Copyright (c) 2013-2015 Ford Motor Company. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

#import "Notifications.h"
#import "LocationService.h"
#import "WeatherLocation.h"

NSTimeInterval const MinimumTimeBetweenLocationUpdates = 120;

@interface LocationService () <CLLocationManagerDelegate>

@property (strong, nonatomic) CLLocationManager *manager;
@property (strong, nonatomic) CLGeocoder *geocoder;
@property (strong, nonatomic) NSDate *lastLocationUpdate;

@end

@implementation LocationService

+ (instancetype)sharedService {
    static LocationService *shared = nil;
    static dispatch_once_t token;
    
    dispatch_once(&token, ^{
        shared = [[LocationService alloc] init];
    });
    
    return shared;
}

- (instancetype)init {
    if (self = [super init]) {
        _manager = [[CLLocationManager alloc] init];
        _manager.delegate = self;
        _manager.pausesLocationUpdatesAutomatically = YES;
        // specify accuracy of 500 meters. Its enough for determining the city and will safe battery.
        _manager.desiredAccuracy = 500.0;
        // Set the minimum distance that the device must move before we want an update
        _manager.distanceFilter = 500.0;

        [_manager requestWhenInUseAuthorization];
        
        _geocoder = [[CLGeocoder alloc] init];
    }
    return self;
}

- (void)start {
    self.lastLocationUpdate = [NSDate dateWithTimeIntervalSince1970:0];
    [self.manager startMonitoringSignificantLocationChanges];
}

- (void)stop {
    [self.manager stopMonitoringSignificantLocationChanges];
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    NSString *statusString;

    switch (status) {
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            statusString = @"AuthorizedWhenInUse";
            [self.manager startUpdatingLocation];
            break;
        case kCLAuthorizationStatusDenied:
            statusString = @"Denied";
            break;
        case kCLAuthorizationStatusNotDetermined:
            statusString = @"NotDetermined";
            break;
        case kCLAuthorizationStatusRestricted:
            statusString = @"Restricted";
            break;
        default:
            statusString = @"Unknown";
            break;
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"%s\n%@", __FUNCTION__, error.localizedFailureReason ?: error);
}

- (void)locationManagerDidPauseLocationUpdates:(CLLocationManager *)manager {
    NSLog(@"Location Manager did pause location updates");
}

- (void)locationManagerDidResumeLocationUpdates:(CLLocationManager *)manager {
    NSLog(@"Location Manager did resume location updates");
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    NSLog(@"%s\n%@", __FUNCTION__, locations);

    NSDate *date = [NSDate date];
    if ([date timeIntervalSinceDate:self.lastLocationUpdate] <= MinimumTimeBetweenLocationUpdates) {
        return;
    }

    self.lastLocationUpdate = date;
    [self.geocoder reverseGeocodeLocation:locations.lastObject completionHandler:^(NSArray *placemarks, NSError *error) {
        if (placemarks.count == 0) { return; }

        CLPlacemark *placemark = placemarks.lastObject;
        WeatherLocation *location = [[WeatherLocation alloc] initWithCity:placemark.locality state:placemark.administrativeArea zipCode:placemark.postalCode country:placemark.country gpsLocation:placemark.location];

        [[NSNotificationCenter defaultCenter] postNotificationName:MobileWeatherLocationUpdateNotification object:self userInfo:@{ @"location": location }];
    }];
}

@end
