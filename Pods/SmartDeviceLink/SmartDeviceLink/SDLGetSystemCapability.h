//
//  SDLGetSystemCapability.h
//  SmartDeviceLink-iOS
//
//  Created by Joel Fischer on 7/11/17.
//  Copyright © 2017 smartdevicelink. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SDLRPCRequest.h"
#import "SDLSystemCapabilityType.h"

NS_ASSUME_NONNULL_BEGIN

@interface SDLGetSystemCapability : SDLRPCRequest

- (instancetype)initWithType:(SDLSystemCapabilityType)type;

/**
 They type of capability you'd like to receive in the response.

 Mandatory
 */
@property (strong, nonatomic) SDLSystemCapabilityType systemCapabilityType;

@end

NS_ASSUME_NONNULL_END
