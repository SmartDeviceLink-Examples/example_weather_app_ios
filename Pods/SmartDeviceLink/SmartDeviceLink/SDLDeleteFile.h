//  SDLDeleteFile.h
//


#import "SDLRPCRequest.h"

/**
 * Used to delete a file resident on the SDL module in the app's local cache.
 * Not supported on first generation SDL vehicles
 * <p>
 *
 * Since <b>SmartDeviceLink 2.0</b><br>
 * see SDLPutFile SDLListFiles
 */

NS_ASSUME_NONNULL_BEGIN

@interface SDLDeleteFile : SDLRPCRequest

- (instancetype)initWithFileName:(NSString *)fileName;

/**
 * @abstract a file reference name
 * @discussion a String value representing a file reference name
 */
@property (strong, nonatomic) NSString *syncFileName;

@end

NS_ASSUME_NONNULL_END
