//
//  LocationService.m
//  MobileWeather
//
//  Copyright (c) 2013-2015 Ford Motor Company. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

#import "GPSLocation.h"
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
        self.manager = [[CLLocationManager alloc] init];
        self.manager.delegate = self;
        self.manager.pausesLocationUpdatesAutomatically = YES;
        // setup to be able to pause automatically when motion is not expected. Will safe battery.
        [self.manager setPausesLocationUpdatesAutomatically:YES];
        // specify accuracy of 500 meters. Its enough for determining the city and will safe battery.
        self.manager.desiredAccuracy = 500.0;
        // Set the minimum distance that the device must move before we want an update
        self.manager.distanceFilter = 500.0;

        [self.manager requestWhenInUseAuthorization];
        
        self.geocoder = [[CLGeocoder alloc] init];
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

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    NSString *statusString;
    
    // get a string based on the authorization status. Remember that they changed since iPhone SDK 8.0
    // If we are building on iPhone SDK 8.0 or higher then use the new offered authorization status types
    // otherwise use the old one
    
    switch (status) {
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            statusString = @"AuthorizedWhenInUse";
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
}

- (void)locationManagerDidResumeLocationUpdates:(CLLocationManager *)manager {
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    NSLog(@"%s\n%@", __FUNCTION__, locations);
    
    NSDate *date = [NSDate date];
    
    if ([date timeIntervalSinceDate:self.lastLocationUpdate] > MinimumTimeBetweenLocationUpdates) {
        self.lastLocationUpdate = date;
        [self.geocoder reverseGeocodeLocation:locations.lastObject completionHandler:^(NSArray *placemarks, NSError *error) {
            if (placemarks != nil && placemarks.count > 0) {
                CLPlacemark *placemark = placemarks.lastObject;
                
                WeatherLocation *location = [[WeatherLocation alloc] init];
                location.country = placemark.country;
                location.state = placemark.administrativeArea;
                location.city = placemark.locality;
                location.zipCode = placemark.postalCode;
                
                location.gpsLocation = [[GPSLocation alloc] init];
                location.gpsLocation.latitude = [NSString stringWithFormat:@"%f", placemark.location.coordinate.latitude];
                location.gpsLocation.longitude = [NSString stringWithFormat:@"%f", placemark.location.coordinate.longitude];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:MobileWeatherLocationUpdateNotification object:self userInfo:@{ @"location": location }];
            }
        }];
    }
}

@end
