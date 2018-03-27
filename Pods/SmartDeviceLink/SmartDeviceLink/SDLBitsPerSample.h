//  SDLBitsPerSample.h
//


#import "SDLEnum.h"

/**
 * Describes different bit depth options for PerformAudioPassThru
 *
 * @since SDL 2.0
 */
typedef SDLEnum SDLBitsPerSample SDL_SWIFT_ENUM;

/**
 * @abstract 8 bits per sample
 */
extern SDLBitsPerSample const SDLBitsPerSample8Bit;

/**
 * @abstract 16 bits per sample
 */
extern SDLBitsPerSample const SDLBitsPerSample16Bit;
