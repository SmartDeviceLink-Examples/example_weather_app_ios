//
//  LocationService.m
//  MobileWeather
//
//  Copyright (c) 2013-2015 Ford Motor Company. All rights reserved.
//

#import "LocationService.h"
#import <CoreLocation/CoreLocation.h>

#define MIN_TIME_BETWEEN_LOCATION_UPDATES 120.0

@interface LocationService () <CLLocationManagerDelegate>

@property (strong) CLLocationManager *manager;

@property (strong) CLGeocoder *geocoder;

@property (strong) NSDate *lastLocationUpdate;

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
        [self setManager:[[CLLocationManager alloc] init]];
        [[self manager] setDelegate:self];
        // setup to be able to pause automatically when motion is not expected. Will safe battery.
        [[self manager] setPausesLocationUpdatesAutomatically:YES];
        // specify accuracy of 500 meters. Its enough for determining the city and will safe battery.
        [[self manager] setDesiredAccuracy:500.0];
        // Set the minimum distance that the device must move before we want an update
        [[self manager] setDistanceFilter:500.0];
        
        // request authorization to the user. We need to ask him. Only do so if we are building on iPhone SDK 8.0 or higher
#ifdef __IPHONE_8_0
        // check if the current iOS version on the phone supports this request method
        if ([[self manager] respondsToSelector:@selector(requestAlwaysAuthorization)]) {
            [[self manager] requestAlwaysAuthorization];
        }
#endif
        
        [self setGeocoder:[[CLGeocoder alloc] init]];
    }
    return self;
}

- (void)start {
    [self setLastLocationUpdate:[NSDate dateWithTimeIntervalSince1970:0]];
    [[self manager] startMonitoringSignificantLocationChanges];
}

- (void)stop {
    [[self manager] stopMonitoringSignificantLocationChanges];
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    NSString *statusString;
    
    // get a string based on the authorization status. Remember that they changed since iPhone SDK 8.0
    // If we are building on iPhone SDK 8.0 or higher then use the new offered authorization status types
    // otherwise use the old one
    
    switch (status) {
#ifdef __IPHONE_8_0
        case kCLAuthorizationStatusAuthorizedAlways:
            statusString = @"AuthorizedAlways";
            break;
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            statusString = @"AuthorizedWhenInUse";
            break;
#else
        case kCLAuthorizationStatusAuthorized:
            statusString = @"Authorized";
            break;
#endif
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
    NSLog(@"%s\n%@", __FUNCTION__, [error localizedFailureReason] ?: error);
}

- (void)locationManagerDidPauseLocationUpdates:(CLLocationManager *)manager {
}

- (void)locationManagerDidResumeLocationUpdates:(CLLocationManager *)manager {
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    NSLog(@"%s\n%@", __FUNCTION__, locations);
    
    NSDate *date = [NSDate date];
    
    if ([date timeIntervalSinceDate:[self lastLocationUpdate]] > MIN_TIME_BETWEEN_LOCATION_UPDATES) {
        [self setLastLocationUpdate:date];
        [[self geocoder] reverseGeocodeLocation:[locations lastObject] completionHandler:^(NSArray *placemarks, NSError *error) {
            if (placemarks != nil && [placemarks count] > 0) {
                CLPlacemark *placemark = [placemarks lastObject];
                
                WeatherLocation *location = [[WeatherLocation alloc] init];
                [location setCountry:[placemark country]];
                [location setState:[placemark administrativeArea]];
                [location setCity:[placemark locality]];
                [location setZipCode:[placemark postalCode]];
                
                [location setGpsLocation:[[GPSLocation alloc] init]];
                [[location gpsLocation] setLatitude:[NSString stringWithFormat:@"%f", placemark.location.coordinate.latitude]];
                [[location gpsLocation] setLongitude:[NSString stringWithFormat:@"%f", placemark.location.coordinate.longitude]];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:MobileWeatherLocationUpdateNotification object:self userInfo:@{ @"location": location }];
            }
        }];
    }
}

@end
