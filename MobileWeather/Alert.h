//
//  Alert.h
//  MobileWeather
//
//  Copyright (c) 2013-2015 Ford Motor Company. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AlertType;


@interface Alert : NSObject

@property AlertType *type;

@property (strong) NSString *alertTitle;

@property (strong) NSString *alertDescription;

@property (strong) NSDate *dateIssued;

@property (strong) NSDate *dateExpires;

- (BOOL)isEqual:(id)object;

- (BOOL)isEqualToAlert:(Alert *)alert;

@end
