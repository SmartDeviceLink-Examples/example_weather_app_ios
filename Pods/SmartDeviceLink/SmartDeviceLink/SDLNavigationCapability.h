//
//  SDLNavigationCapability.h
//  SmartDeviceLink-iOS
//
//  Created by Joel Fischer on 7/11/17.
//  Copyright © 2017 smartdevicelink. All rights reserved.
//

#import "SDLRPCStruct.h"

NS_ASSUME_NONNULL_BEGIN

@interface SDLNavigationCapability : SDLRPCStruct

- (instancetype)initWithSendLocation:(BOOL)sendLocationEnabled waypoints:(BOOL)waypointsEnabled;

/**
 Whether or not the SendLocation RPC is enabled.
 Boolean, optional
 */
@property (nullable, copy, nonatomic) NSNumber *sendLocationEnabled;

/**
 Whether or not Waypoint related RPCs are enabled.
 Boolean, optional
 */
@property (nullable, copy, nonatomic) NSNumber *getWayPointsEnabled;

@end

NS_ASSUME_NONNULL_END
