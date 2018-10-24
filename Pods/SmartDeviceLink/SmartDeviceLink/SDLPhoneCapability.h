//
//  SDLPhoneCapability.h
//  SmartDeviceLink-iOS
//
//  Created by Joel Fischer on 7/11/17.
//  Copyright © 2017 smartdevicelink. All rights reserved.
//

#import "SDLRPCStruct.h"

NS_ASSUME_NONNULL_BEGIN

/**
 Extended capabilities of the module's phone feature
 */
@interface SDLPhoneCapability : SDLRPCStruct

- (instancetype)initWithDialNumber:(BOOL)dialNumberEnabled;

/**
 Whether or not the DialNumber RPC is enabled.
 
 Boolean, optional
 */
@property (nullable, strong, nonatomic) NSNumber *dialNumberEnabled;

@end

NS_ASSUME_NONNULL_END
