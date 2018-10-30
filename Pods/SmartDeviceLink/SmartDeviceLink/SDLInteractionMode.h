//  SDLInteractionMode.h
//


#import "SDLEnum.h"

/**
 For application-initiated interactions (SDLPerformInteraction), this specifies the mode by which the user is prompted and by which the user's selection is indicated. Used in PerformInteraction.

 @since SDL 1.0
 */
typedef SDLEnum SDLInteractionMode SDL_SWIFT_ENUM;

/**
 Interaction Mode : Manual Only

 This mode causes the interaction to occur only on the display, meaning the choices are presented and selected only via the display. Selections are viewed with the SEEKRIGHT, SEEKLEFT, TUNEUP, TUNEDOWN buttons. User's selection is indicated with the OK button
 */
extern SDLInteractionMode const SDLInteractionModeManualOnly;

/**
 Interaction Mode : VR Only

 This mode causes the interaction to occur only through TTS and VR. The user is prompted via TTS to select a choice by saying one of the choice's synonyms
 */
extern SDLInteractionMode const SDLInteractionModeVoiceRecognitionOnly;

/**
 Interaction Mode : Manual & VR

 @discussion This mode is a combination of MANUAL_ONLY and VR_ONLY, meaning the user is prompted both visually and audibly. The user can make a selection either using the mode described in MANUAL_ONLY or using the mode described in VR_ONLY.

 If the user views selections as described in MANUAL_ONLY mode, the interaction becomes strictly, and irreversibly, a MANUAL_ONLY interaction (i.e. the VR session is cancelled, although the interaction itself is still in progress). If the user interacts with the VR session in any way (e.g. speaks a phrase, even if it is not a recognized choice), the interaction becomes strictly, and irreversibly, a VR_ONLY interaction (i.e. the MANUAL_ONLY mode forms of interaction will no longer be honored)

 The TriggerSource parameter of the *PerformInteraction* response will indicate which interaction mode the user finally chose to attempt the selection (even if the interaction did not end with a selection being made)
 */
extern SDLInteractionMode const SDLInteractionModeBoth;
