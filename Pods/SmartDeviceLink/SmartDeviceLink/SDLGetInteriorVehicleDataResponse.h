//
//  SDLGetInteriorVehicleDataResponse.h
//

#import "SDLRPCResponse.h"
@class SDLModuleData;

NS_ASSUME_NONNULL_BEGIN

@interface SDLGetInteriorVehicleDataResponse : SDLRPCResponse

@property (strong, nonatomic) SDLModuleData *moduleData;

/**
 * @abstract It is a conditional-mandatory parameter: must be returned in case "subscribe" parameter was present in the related request.
 * if "true" - the "moduleType" from request is successfully subscribed and the head unit will send onInteriorVehicleData notifications for the moduleType.
 * if "false" - the "moduleType" from request is either unsubscribed or failed to subscribe.
 *
 * Optional, Boolean
 */
@property (nullable, strong, nonatomic) NSNumber<SDLBool> *isSubscribed;

@end

NS_ASSUME_NONNULL_END
