//
//  SDLOnLockScreenStatus.h
//  SmartDeviceLink
//

#import "SDLRPCNotification.h"

#import "SDLHMILevel.h"
#import "SDLLockScreenStatus.h"


/**
 * 	To help prevent driver distraction, any SmartDeviceLink application is required to implement a lockscreen that must be enforced while the application is active on the system while the vehicle is in motion.
 *
 *	This lockscreen must perform the following:
 *	Limit all application control usability from the mobile device with a full-screen static image overlay or separate view.
 *	For simplicity, the OnLockScreenStatus RPC will be provided via the onOnLockScreenNotification call back. The call back will include the LockScreenStatus enum which indicates if the lockscreen is required, optional or not required.
 *	The call back also includes details regarding the current HMI_Status level, driver distraction status and user selection status of the application.
 */

NS_ASSUME_NONNULL_BEGIN

@interface SDLOnLockScreenStatus : SDLRPCNotification

/**
 * <p>Get the current driver distraction status(i.e. whether driver distraction rules are in effect, or not)</p>
 * @return String
 */
@property (strong, nonatomic) NSNumber<SDLBool> *driverDistractionStatus;
/**
 * <p>Get user selection status for the application (has the app been selected via hmi or voice command)</p>
 * @return Boolean the current user selection status
 */

@property (strong, nonatomic) NSNumber<SDLBool> *userSelected;
/**
 * <p>Get the {@linkplain LockScreenStatus} enumeration, indicating if the lockscreen should be required, optional or off </p>
 * @return {@linkplain LockScreenStatus}
 */
@property (strong, nonatomic) SDLLockScreenStatus lockScreenStatus;
/**
 * <p>Get HMILevel in effect for the application</p>
 * @return {@linkplain HMILevel} the current HMI Level in effect for the application
 */
@property (strong, nonatomic) SDLHMILevel hmiLevel;

@end

NS_ASSUME_NONNULL_END
