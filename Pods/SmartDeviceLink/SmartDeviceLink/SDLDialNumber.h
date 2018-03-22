//
//  SDLDialNumber.h
//  SmartDeviceLink-iOS

#import "SDLRPCRequest.h"

/**
 This RPC is used to tell the head unit to use bluetooth to dial a phone number using the phone.
 
 @since SDL 4.0
 */

NS_ASSUME_NONNULL_BEGIN

@interface SDLDialNumber : SDLRPCRequest

- (instancetype)initWithNumber:(NSString *)number;

/**
 *  Up to 40 character string representing the phone number. All characters stripped except for '0'-'9', '*', '#', ',', ';', and '+'
 */
@property (strong, nonatomic) NSString *number;

@end

NS_ASSUME_NONNULL_END
