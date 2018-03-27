//
//  SDLTouch.m
//  SmartDeviceLink-iOS
//
//  Created by Muller, Alexander (A.) on 6/14/16.
//  Copyright © 2016 smartdevicelink. All rights reserved.
//

#import "SDLTouch.h"

#import "SDLTouchCoord.h"
#import "SDLTouchEvent.h"

NS_ASSUME_NONNULL_BEGIN

@implementation SDLTouch

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }

    _identifier = -1;
    _location = CGPointZero;
    _timeStamp = 0;

    return self;
}

- (instancetype)initWithTouchEvent:(SDLTouchEvent *)touchEvent {
    self = [self init];
    if (self) {
        _identifier = touchEvent.touchEventId.integerValue;

        id firstTimeStamp = touchEvent.timeStamp.firstObject;
        // In the event we receive a null timestamp, we will supply a device timestamp.
        if ([firstTimeStamp isKindOfClass:[NSNull class]] && [firstTimeStamp isEqual:[NSNull null]]) {
            _timeStamp = (NSUInteger)([[NSDate date] timeIntervalSince1970] * 1000);
        } else {
            NSNumber *timeStampNumber = (NSNumber *)firstTimeStamp;
            _timeStamp = timeStampNumber.unsignedIntegerValue;
        }

        SDLTouchCoord *coord = touchEvent.coord.firstObject;
        _location = CGPointMake(coord.x.floatValue,
                                coord.y.floatValue);
    }
    return self;
}

#pragma mark - Getters
- (BOOL)isFirstFinger {
    return self.identifier == SDLTouchIdentifierFirstFinger;
}

- (BOOL)isSecondFinger {
    return self.identifier == SDLTouchIdentifierSecondFinger;
}

@end

NS_ASSUME_NONNULL_END
