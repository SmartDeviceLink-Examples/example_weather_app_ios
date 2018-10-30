//
//  SDLErrorConstants.h
//  SmartDeviceLink-iOS
//
//  Created by Joel Fischer on 10/5/15.
//  Copyright © 2015 smartdevicelink. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SDLErrorConstants.h"

#import "SDLResult.h"


NS_ASSUME_NONNULL_BEGIN

#pragma mark Error Domains
typedef NSString SDLErrorDomain;
extern SDLErrorDomain *const SDLErrorDomainLifecycleManager;
extern SDLErrorDomain *const SDLErrorDomainFileManager;
extern SDLErrorDomain *const SDLErrorDomainTextAndGraphicManager;
extern SDLErrorDomain *const SDLErrorDomainSoftButtonManager;
extern SDLErrorDomain *const SDLErrorDomainMenuManager;
extern SDLErrorDomain *const SDLErrorDomainChoiceSetManager;
extern SDLErrorDomain *const SDLErrorDomainTransport;

@interface NSError (SDLErrors)

#pragma mark SDLManager

+ (NSError *)sdl_lifecycle_rpcErrorWithDescription:(NSString *)description andReason:(NSString *)reason;
+ (NSError *)sdl_lifecycle_notConnectedError;
+ (NSError *)sdl_lifecycle_notReadyError;
+ (NSError *)sdl_lifecycle_unknownRemoteErrorWithDescription:(NSString *)description andReason:(NSString *)reason;
+ (NSError *)sdl_lifecycle_managersFailedToStart;
+ (NSError *)sdl_lifecycle_startedWithBadResult:(SDLResult)result info:(NSString *)info;
+ (NSError *)sdl_lifecycle_startedWithWarning:(SDLResult)result info:(NSString *)info;
+ (NSError *)sdl_lifecycle_failedWithBadResult:(SDLResult)result info:(NSString *)info;
+ (NSError *)sdl_lifecycle_multipleRequestsCancelled;

#pragma mark SDLFileManager

+ (NSError *)sdl_fileManager_cannotOverwriteError;
+ (NSError *)sdl_fileManager_noKnownFileError;
+ (NSError *)sdl_fileManager_unableToStartError;
+ (NSError *)sdl_fileManager_unableToUploadError;
+ (NSError *)sdl_fileManager_unableToUpload_ErrorWithUserInfo:(NSDictionary *)userInfo;
+ (NSError *)sdl_fileManager_unableToDelete_ErrorWithUserInfo:(NSDictionary *)userInfo;
+ (NSError *)sdl_fileManager_fileDoesNotExistError;
+ (NSError *)sdl_fileManager_fileUploadCanceled;
+ (NSError *)sdl_fileManager_dataMissingError;

#pragma mark Show Managers

+ (NSError *)sdl_softButtonManager_pendingUpdateSuperseded;
+ (NSError *)sdl_textAndGraphicManager_pendingUpdateSuperseded;

#pragma mark Menu Manager

+ (NSError *)sdl_menuManager_failedToUpdateWithDictionary:(NSDictionary *)userInfo;

#pragma mark Choice Set Manager

+ (NSError *)sdl_choiceSetManager_choicesDeletedBeforePresentation:(NSDictionary *)userInfo;
+ (NSError *)sdl_choiceSetManager_choiceDeletionFailed:(NSDictionary *)userInfo;
+ (NSError *)sdl_choiceSetManager_choiceUploadFailed:(NSDictionary *)userInfo;

#pragma mark Transport

+ (NSError *)sdl_transport_unknownError;
+ (NSError *)sdl_transport_connectionRefusedError;
+ (NSError *)sdl_transport_connectionTimedOutError;
+ (NSError *)sdl_transport_networkDownError;

@end

@interface NSException (SDLExceptions)

+ (NSException *)sdl_missingHandlerException;
+ (NSException *)sdl_missingIdException;
+ (NSException *)sdl_missingFilesException;
+ (NSException *)sdl_invalidSoftButtonStateException;
+ (NSException *)sdl_carWindowOrientationException;

@end

NS_ASSUME_NONNULL_END
