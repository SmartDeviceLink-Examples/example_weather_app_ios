//
//  SDLBinaryAudioManager.h
//  SmartDeviceLink-Example
//
//  Created by Joel Fischer on 10/24/17.
//  Copyright © 2017 smartdevicelink. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SDLAudioFile;
@class SDLManager;
@class SDLStreamingMediaLifecycleManager;
@protocol SDLStreamingAudioManagerType;
@protocol SDLAudioStreamManagerDelegate;

NS_ASSUME_NONNULL_BEGIN

extern NSString *const SDLErrorDomainAudioStreamManager;

typedef NS_ENUM(NSInteger, SDLAudioStreamManagerError) {
    SDLAudioStreamManagerErrorNotConnected = -1,
    SDLAudioStreamManagerErrorNoQueuedAudio = -2
};

@interface SDLAudioStreamManager : NSObject

/**
 The delegate describing when files are done playing or any errors that occur
 */
@property (weak, nonatomic) id<SDLAudioStreamManagerDelegate> delegate;

/**
 Whether or not we are currently playing audio
 */
@property (assign, nonatomic, readonly, getter=isPlaying) BOOL playing;

/**
 The queue of audio files that will be played in sequence
 */
@property (copy, nonatomic, readonly) NSArray<SDLAudioFile *> *queue;

/**
 Init should only occur with dependencies. use `initWithManager:`

 @return A failure
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 Create an audio stream manager with a reference to the parent stream manager.

 @warning For internal use

 @param streamManager The parent stream manager
 @return The audio stream manager
 */
- (instancetype)initWithManager:(id<SDLStreamingAudioManagerType>)streamManager NS_DESIGNATED_INITIALIZER;

/**
 Push a new file URL onto the queue after converting it into the correct PCM format for streaming binary data. Call `playNextWhenReady` to start playing the next completed pushed file.

 @note This happens on a serial background thread and will provide an error callback using the delegate if the conversion fails.

 @param fileURL File URL to convert
 */
- (void)pushWithFileURL:(NSURL *)fileURL;

/**
 Play the next item in the queue. If an item is currently playing, it will continue playing and this item will begin playing after it is completed.

 When complete, this will callback on the delegate.
 */
- (void)playNextWhenReady;

/**
 Stop playing the queue after the current item completes and clear the queue. If nothing is playing, the queue will be cleared.
 */
- (void)stop;

@end

NS_ASSUME_NONNULL_END
