//
//  Alert.m
//  MobileWeather
//
//  Copyright (c) 2013-2015 Ford Motor Company. All rights reserved.
//

#import "Alert.h"

#import "AlertType.h"

@implementation Alert

- (BOOL)isEqual:(id)object {
    if ([[object class] isSubclassOfClass:[Alert class]]) {
        return [self isEqualToAlert:object];
    } else {
        return [super isEqual:object];
    }
}

- (BOOL)isEqualToAlert:(Alert *)alert {
    // are we comparing one and the same object?
    // (object hash is identical, maybe poining to the same address)
    if ([super isEqual:alert]) return YES;
    
    // the objects have different hashes. Now comare the content.
    // is the alert type not the same?
    if (alert.type != self.type) return NO;
    
    // is the alert date issued not the same?
    if ([alert.dateIssued isEqualToDate:self.dateIssued] == NO) return NO;
    
    // is the alert date expires not the same?
    if ([alert.dateExpires isEqualToDate:self.dateExpires] == NO) return NO;
    
    // is the alert message not the same?
    if ([alert.alertTitle isEqualToString:self.alertTitle] == NO) return NO;
         
    // is the alert description not the same?
    if ([alert.alertDescription isEqualToString:self.alertDescription] == NO) return NO;
    
    return YES;
}

@end
