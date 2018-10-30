//
//  SDLCheckChoiceVROptionalOperation.m
//  SmartDeviceLink
//
//  Created by Joel Fischer on 5/24/18.
//  Copyright © 2018 smartdevicelink. All rights reserved.
//

#import "SDLCheckChoiceVROptionalOperation.h"

#import "SDLChoice.h"
#import "SDLCreateInteractionChoiceSet.h"
#import "SDLConnectionManagerType.h"
#import "SDLLogMacros.h"

NS_ASSUME_NONNULL_BEGIN

@interface SDLCheckChoiceVROptionalOperation()

@property (weak, nonatomic) id<SDLConnectionManagerType> connectionManager;
@property (copy, nonatomic, nullable) NSError *internalError;

@end

@implementation SDLCheckChoiceVROptionalOperation

- (instancetype)initWithConnectionManager:(id<SDLConnectionManagerType>)connectionManager {
    self = [super init];
    if (!self) { return nil; }

    _connectionManager = connectionManager;

    return self;
}

- (void)start {
    [super start];

    [self sdl_sendTestChoices];
}

- (void)sdl_sendTestChoices {
    __weak typeof(self) weakself = self;
    [self.connectionManager sendConnectionManagerRequest:[self.class sdl_testCellWithVR:NO] withResponseHandler:^(__kindof SDLRPCRequest * _Nullable request, __kindof SDLRPCResponse * _Nullable response, NSError * _Nullable error) {
        if (error == nil) {
            SDLLogD(@"Connected head unit supports choice cells without voice commands. Cells without voice will be sent without voice from now on (no placeholder voice).");

            weakself.vrOptional = YES;
            weakself.internalError = nil;
            [weakself finishOperation];
            return;
        }

        // Check for choice sets with VR
        [self.connectionManager sendConnectionManagerRequest:[self.class sdl_testCellWithVR:YES] withResponseHandler:^(__kindof SDLRPCRequest * _Nullable request, __kindof SDLRPCResponse * _Nullable response, NSError * _Nullable error) {
            if (error == nil) {
                SDLLogW(@"Connected head unit does not support choice cells without voice commands. Cells without voice will be sent with placeholder voices from now on.");

                weakself.vrOptional = NO;
                weakself.internalError = nil;
                [weakself finishOperation];
                return;
            }

            SDLLogE(@"Connected head unit has rejected all choice cells, choice manager disabled. Error: %@, Response: %@", error, response);
            weakself.vrOptional = NO;
            weakself.internalError = error;
            [weakself finishOperation];
        }];
    }];
}

+ (SDLCreateInteractionChoiceSet *)sdl_testCellWithVR:(BOOL)hasVR {
    SDLChoice *choice = [[SDLChoice alloc] init];
    choice.choiceID = @0;
    choice.menuName = @"Test Cell";
    choice.vrCommands = hasVR ? @[@"Test VR"] : nil;

    SDLCreateInteractionChoiceSet *choiceSet = [[SDLCreateInteractionChoiceSet alloc] initWithId:0 choiceSet:@[choice]];

    return choiceSet;
}

#pragma mark - Property Overrides

- (nullable NSString *)name {
    return @"com.sdl.choicesetmanager.checkVROptional";
}

- (NSOperationQueuePriority)queuePriority {
    return NSOperationQueuePriorityVeryHigh;
}

- (nullable NSError *)error {
    return self.internalError;
}

@end

NS_ASSUME_NONNULL_END
