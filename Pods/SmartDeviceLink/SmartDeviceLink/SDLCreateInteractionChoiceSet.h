//  SDLCreateInteractionChoiceSet.h
//


#import "SDLRPCRequest.h"

@class SDLChoice;

/**
 * Creates a Choice Set which can be used in subsequent *SDLPerformInteraction* Operations.
 *
 * HMILevel needs to be FULL, LIMITED or BACKGROUND
 *
 * Before a perform interaction is sent you MUST wait for the success from the CreateInteractionChoiceSet RPC.
 *
 * If you do not wait the system may not recognize the first utterance from the user.
 *
 * @since SDL 1.0
 *
 * @see SDLDeleteInteractionChoiceSet SDLPerformInteraction
 */
NS_ASSUME_NONNULL_BEGIN

@interface SDLCreateInteractionChoiceSet : SDLRPCRequest

/// Convenience init for creating a choice set RPC
///
/// @param choiceId A unique ID that identifies the Choice Set
/// @param choiceSet Array of choices, which the user can select by menu or voice recognition
/// @return An SDLCreateInteractionChoiceSet object
- (instancetype)initWithId:(UInt32)choiceId choiceSet:(NSArray<SDLChoice *> *)choiceSet;

/**
 * A unique ID that identifies the Choice Set
 *
 * Required, Integer, 0 - 2,000,000,000
 */
@property (strong, nonatomic) NSNumber<SDLInt> *interactionChoiceSetID;

/**
 * Array of choices, which the user can select by menu or voice recognition
 *
 * Required, SDLChoice, Array size 1 - 100
 */
@property (strong, nonatomic) NSArray<SDLChoice *> *choiceSet;

@end

NS_ASSUME_NONNULL_END
