//  SDLLocationDetails.h
//

#import "SDLRPCStruct.h"

@class SDLLocationCoordinate;
@class SDLImage;
@class SDLOasisAddress;

NS_ASSUME_NONNULL_BEGIN

@interface SDLLocationDetails : SDLRPCStruct

/**
 * @abstract Latitude/Longitude of the location
 *
 * @see SDLLocationCoordinate
 *
 * Optional
 */
@property (nullable, strong, nonatomic) SDLLocationCoordinate *coordinate;

/**
 * @abstract Name of location.
 *
 * Optional, Max length 500 chars
 */
@property (nullable, copy, nonatomic) NSString *locationName;

/**
 * @abstract Location address for display purposes only.
 *
 * Optional, Array of Strings, Array length 0 - 4, Max String length 500
 */
@property (nullable, copy, nonatomic) NSArray<NSString *> *addressLines;

/**
 * @abstract Description intended location / establishment.
 *
 * Optional, Max length 500 chars
 */
@property (nullable, copy, nonatomic) NSString *locationDescription;

/**
 * @abstract Phone number of location / establishment.
 *
 * Optional, Max length 500 chars
 */
@property (nullable, copy, nonatomic) NSString *phoneNumber;

/**
 * @abstract Image / icon of intended location.
 *
 * @see SDLImage
 *
 * Optional
 */
@property (nullable, strong, nonatomic) SDLImage *locationImage;

/**
 * @abstract Address to be used by navigation engines for search.
 *
 * @see SDLOASISAddress
 *
 * Optional
 */
@property (nullable, strong, nonatomic) SDLOasisAddress *searchAddress;


@end

NS_ASSUME_NONNULL_END
