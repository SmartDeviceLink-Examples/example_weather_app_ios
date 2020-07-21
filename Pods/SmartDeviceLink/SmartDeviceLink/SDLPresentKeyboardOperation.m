//
//  SDLPresentKeyboardOperation.m
//  SmartDeviceLink
//
//  Created by Joel Fischer on 5/24/18.
//  Copyright © 2018 smartdevicelink. All rights reserved.
//

#import "SDLPresentKeyboardOperation.h"

#import "SDLCancelInteraction.h"
#import "SDLConnectionManagerType.h"
#import "SDLGlobals.h"
#import "SDLKeyboardDelegate.h"
#import "SDLKeyboardProperties.h"
#import "SDLLogMacros.h"
#import "SDLNotificationConstants.h"
#import "SDLOnKeyboardInput.h"
#import "SDLPerformInteraction.h"
#import "SDLPerformInteractionResponse.h"
#import "SDLRPCNotificationNotification.h"
#import "SDLSetGlobalProperties.h"
#import "SDLVersion.h"

NS_ASSUME_NONNULL_BEGIN

@interface SDLPresentKeyboardOperation()

@property (strong, nonatomic) NSUUID *operationId;
@property (weak, nonatomic) id<SDLConnectionManagerType> connectionManager;
@property (weak, nonatomic) id<SDLKeyboardDelegate> keyboardDelegate;
@property (copy, nonatomic) NSString *initialText;
@property (strong, nonatomic) SDLKeyboardProperties *originalKeyboardProperties;
@property (strong, nonatomic) SDLKeyboardProperties *keyboardProperties;
@property (assign, nonatomic, readwrite) UInt16 cancelId;

@property (strong, nonatomic, readonly) SDLPerformInteraction *performInteraction;

@property (copy, nonatomic, nullable) NSError *internalError;

@end

@implementation SDLPresentKeyboardOperation

- (instancetype)initWithConnectionManager:(id<SDLConnectionManagerType>)connectionManager keyboardProperties:(SDLKeyboardProperties *)originalKeyboardProperties initialText:(NSString *)initialText keyboardDelegate:(id<SDLKeyboardDelegate>)keyboardDelegate cancelID:(UInt16)cancelID {
    self = [super init];
    if (!self) { return self; }

    _connectionManager = connectionManager;
    _initialText = initialText;
    _keyboardDelegate = keyboardDelegate;
    _originalKeyboardProperties = originalKeyboardProperties;
    _keyboardProperties = originalKeyboardProperties;
    _cancelId = cancelID;
    _operationId = [NSUUID UUID];

    return self;
}

- (void)start {
    [super start];
    if (self.isCancelled) { return; }

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sdl_keyboardInputNotification:) name:SDLDidReceiveKeyboardInputNotification object:nil];

    [self sdl_start];
}

- (void)sdl_start {
    if (self.keyboardDelegate != nil && [self.keyboardDelegate respondsToSelector:@selector(customKeyboardConfiguration)]) {
        SDLKeyboardProperties *customProperties = self.keyboardDelegate.customKeyboardConfiguration;
        if (customProperties != nil) {
            self.keyboardProperties = customProperties;
        }
    }

    [self sdl_updateKeyboardPropertiesWithCompletionHandler:^{
        if (self.isCancelled) {
            [self finishOperation];
            return;
        }

        [self sdl_presentKeyboard];
    }];
}

#pragma mark - Sending Requests

- (void)sdl_updateKeyboardPropertiesWithCompletionHandler:(nullable void(^)(void))completionHandler {
    SDLSetGlobalProperties *setProperties = [[SDLSetGlobalProperties alloc] init];
    setProperties.keyboardProperties = self.keyboardProperties;

    [self.connectionManager sendConnectionRequest:setProperties withResponseHandler:^(__kindof SDLRPCRequest * _Nullable request, __kindof SDLRPCResponse * _Nullable response, NSError * _Nullable error) {
        if (error != nil) {
            SDLLogE(@"Error setting keyboard properties to new value: %@, with error: %@", request, error);
        }

        if (completionHandler != nil) {
            completionHandler();
        }
    }];
}

- (void)sdl_presentKeyboard {
    [self.connectionManager sendConnectionRequest:self.performInteraction withResponseHandler:^(__kindof SDLRPCRequest * _Nullable request, __kindof SDLRPCResponse * _Nullable response, NSError * _Nullable error) {
        if (self.isCancelled) {
            [self finishOperation];
            return;
        }

        if (error != nil) {
            self.internalError = error;
        }

        [self finishOperation];
    }];
}

- (void)dismissKeyboard {
    if (self.isFinished) {
        SDLLogW(@"This operation has already finished so it can not be canceled.");
        return;
    } else if (self.isCancelled) {
        SDLLogW(@"This operation has already been canceled. It will be finished at some point during the operation.");
        return;
    } else if (self.isExecuting) {
        if ([SDLGlobals.sharedGlobals.rpcVersion isLessThanVersion:[[SDLVersion alloc] initWithMajor:6 minor:0 patch:0]]) {
            SDLLogE(@"Canceling a keyboard is not supported on this head unit");
            return;
        }

        SDLLogD(@"Canceling the presented keyboard");

        SDLCancelInteraction *cancelInteraction = [[SDLCancelInteraction alloc] initWithPerformInteractionCancelID:self.cancelId];

        __weak typeof(self) weakSelf = self;
        [self.connectionManager sendConnectionRequest:cancelInteraction withResponseHandler:^(__kindof SDLRPCRequest * _Nullable request, __kindof SDLRPCResponse * _Nullable response, NSError * _Nullable error) {
            if (error != nil) {
                weakSelf.internalError = error;
                SDLLogE(@"Error canceling the keyboard: %@, with error: %@", request, error);
                return;
            }
            SDLLogD(@"The presented keyboard was canceled successfully");
        }];
    } else {
        SDLLogD(@"Canceling a keyboard that has not yet been sent to Core");
        [self cancel];
    }
}

#pragma mark - Private Getters / Setters

- (SDLPerformInteraction *)performInteraction {
    SDLPerformInteraction *performInteraction = [[SDLPerformInteraction alloc] init];
    performInteraction.initialText = self.initialText;
    performInteraction.interactionMode = SDLInteractionModeManualOnly;
    performInteraction.interactionChoiceSetIDList = @[];
    performInteraction.interactionLayout = SDLLayoutModeKeyboard;
    performInteraction.cancelID = @(self.cancelId);

    return performInteraction;
}

#pragma mark - Notification Observers

- (void)sdl_keyboardInputNotification:(SDLRPCNotificationNotification *)notification {
    if (self.isCancelled) {
        [self finishOperation];
        return;
    }
    
    if (self.keyboardDelegate == nil) { return; }
    SDLOnKeyboardInput *onKeyboard = notification.notification;

    if ([self.keyboardDelegate respondsToSelector:@selector(keyboardDidSendEvent:text:)]) {
        [self.keyboardDelegate keyboardDidSendEvent:onKeyboard.event text:onKeyboard.data];
    }

    __weak typeof(self) weakself = self;
    if ([onKeyboard.event isEqualToEnum:SDLKeyboardEventVoice] || [onKeyboard.event isEqualToEnum:SDLKeyboardEventSubmitted]) {
        // Submit voice or text
        [self.keyboardDelegate userDidSubmitInput:onKeyboard.data withEvent:onKeyboard.event];
    } else if ([onKeyboard.event isEqualToEnum:SDLKeyboardEventKeypress]) {
        // Notify of keypress
        if ([self.keyboardDelegate respondsToSelector:@selector(updateAutocompleteWithInput:autoCompleteResultsHandler:)]) {
            [self.keyboardDelegate updateAutocompleteWithInput:onKeyboard.data autoCompleteResultsHandler:^(NSArray<NSString *> * _Nullable updatedAutoCompleteList) {
                NSArray<NSString *> *newList = nil;
                if (updatedAutoCompleteList.count > 100) {
                    newList = [updatedAutoCompleteList subarrayWithRange:NSMakeRange(0, 100)];
                } else {
                    newList = updatedAutoCompleteList;
                }

                weakself.keyboardProperties.autoCompleteList = (newList.count > 0) ? newList : @[];
                weakself.keyboardProperties.autoCompleteText = (newList.count > 0) ? newList.firstObject : nil;
                [weakself sdl_updateKeyboardPropertiesWithCompletionHandler:nil];
            }];
        } else if ([self.keyboardDelegate respondsToSelector:@selector(updateAutocompleteWithInput:completionHandler:)]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            [self.keyboardDelegate updateAutocompleteWithInput:onKeyboard.data completionHandler:^(NSString * _Nullable updatedAutocompleteText) {
                weakself.keyboardProperties.autoCompleteText = updatedAutocompleteText;
                [weakself sdl_updateKeyboardPropertiesWithCompletionHandler:nil];
            }];
#pragma clang diagnostic pop
        }

        if ([self.keyboardDelegate respondsToSelector:@selector(updateCharacterSetWithInput:completionHandler:)]) {
            [self.keyboardDelegate updateCharacterSetWithInput:onKeyboard.data completionHandler:^(NSArray<NSString *> *updatedCharacterSet) {
                weakself.keyboardProperties.limitedCharacterList = updatedCharacterSet;
                [self sdl_updateKeyboardPropertiesWithCompletionHandler:nil];
            }];
        }
    } else if ([onKeyboard.event isEqualToEnum:SDLKeyboardEventAborted] || [onKeyboard.event isEqualToEnum:SDLKeyboardEventCancelled]) {
        // Notify of abort / cancellation
        [self.keyboardDelegate keyboardDidAbortWithReason:onKeyboard.event];
    }
}

#pragma mark - Property Overrides

- (nullable NSString *)name {
    return [NSString stringWithFormat:@"%@ - %@", self.class, self.operationId];
}

- (NSOperationQueuePriority)queuePriority {
    return NSOperationQueuePriorityNormal;
}

- (void)finishOperation {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    // We need to reset the keyboard properties
    SDLSetGlobalProperties *setProperties = [[SDLSetGlobalProperties alloc] init];
    setProperties.keyboardProperties = self.originalKeyboardProperties;

    [self.connectionManager sendConnectionRequest:setProperties withResponseHandler:^(__kindof SDLRPCRequest * _Nullable request, __kindof SDLRPCResponse * _Nullable response, NSError * _Nullable error) {
        if (error != nil) {
            SDLLogE(@"Error resetting keyboard properties to values: %@, with error: %@", request, error);
        }

        [super finishOperation];
    }];
}

- (nullable NSError *)error {
    return self.internalError;
}

@end

NS_ASSUME_NONNULL_END
