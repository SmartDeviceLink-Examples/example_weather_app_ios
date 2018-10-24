//
//  SDLErrorConstants.m
//  SmartDeviceLink-iOS
//
//  Created by Joel Fischer on 10/5/15.
//  Copyright © 2015 smartdevicelink. All rights reserved.
//

#import "SDLError.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark Error Domains

SDLErrorDomain *const SDLErrorDomainLifecycleManager = @"com.sdl.lifecyclemanager.error";
SDLErrorDomain *const SDLErrorDomainFileManager = @"com.sdl.filemanager.error";
SDLErrorDomain *const SDLErrorDomainTextAndGraphicManager = @"com.sdl.textandgraphicmanager.error";
SDLErrorDomain *const SDLErrorDomainSoftButtonManager = @"com.sdl.softbuttonmanager.error";
SDLErrorDomain *const SDLErrorDomainMenuManager = @"com.sdl.menumanager.error";
SDLErrorDomain *const SDLErrorDomainChoiceSetManager = @"com.sdl.choicesetmanager.error";
SDLErrorDomain *const SDLErrorDomainTransport = @"com.sdl.transport.error";

@implementation NSError (SDLErrors)

#pragma mark - SDLManager

+ (NSError *)sdl_lifecycle_rpcErrorWithDescription:(NSString *)description andReason:(NSString *)reason {
    NSDictionary<NSString *, NSString *> *userInfo = @{
        NSLocalizedDescriptionKey: NSLocalizedString(description, nil),
        NSLocalizedFailureReasonErrorKey: NSLocalizedString(reason, nil),
        NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Have you tried turning it off and on again?", nil)
    };
    return [NSError errorWithDomain:SDLErrorDomainLifecycleManager
                               code:SDLManagerErrorRPCRequestFailed
                           userInfo:userInfo];
}

+ (NSError *)sdl_lifecycle_notConnectedError {
    NSDictionary<NSString *, NSString *> *userInfo = @{
        NSLocalizedDescriptionKey: NSLocalizedString(@"Could not find a connection", nil),
        NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"The SDL library could not find a current connection to an SDL hardware device", nil),
        NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Have you tried turning it off and on again?", nil)
    };

    return [NSError errorWithDomain:SDLErrorDomainLifecycleManager
                               code:SDLManagerErrorNotConnected
                           userInfo:userInfo];
}

+ (NSError *)sdl_lifecycle_notReadyError {
    NSDictionary<NSString *, NSString *> *userInfo = @{
        NSLocalizedDescriptionKey: NSLocalizedString(@"Lifecycle manager not ready", nil),
        NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"The SDL library is not finished setting up the connection, please wait until the lifecycleState is SDLLifecycleStateReady", nil),
        NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Have you tried turning it off and on again?", nil)
    };

    return [NSError errorWithDomain:SDLErrorDomainLifecycleManager
                               code:SDLManagerErrorNotConnected
                           userInfo:userInfo];
}

+ (NSError *)sdl_lifecycle_unknownRemoteErrorWithDescription:(NSString *)description andReason:(NSString *)reason {
    NSDictionary<NSString *, NSString *> *userInfo = @{
        NSLocalizedDescriptionKey: NSLocalizedString(description, nil),
        NSLocalizedFailureReasonErrorKey: NSLocalizedString(reason, nil),
        NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Have you tried turning it off and on again?", nil)
    };
    return [NSError errorWithDomain:SDLErrorDomainLifecycleManager
                               code:SDLManagerErrorUnknownRemoteError
                           userInfo:userInfo];
}

+ (NSError *)sdl_lifecycle_managersFailedToStart {
    return [NSError errorWithDomain:SDLErrorDomainLifecycleManager
                               code:SDLManagerErrorManagersFailedToStart
                           userInfo:nil];
}

+ (NSError *)sdl_lifecycle_startedWithBadResult:(SDLResult)result info:(NSString *)info {
    NSDictionary<NSString *, NSString *> *userInfo = @{
        NSLocalizedDescriptionKey: NSLocalizedString(result, nil),
        NSLocalizedFailureReasonErrorKey: NSLocalizedString(info, nil)
    };
    return [NSError errorWithDomain:SDLErrorDomainLifecycleManager
                               code:SDLManagerErrorRegistrationFailed
                           userInfo:userInfo];
}

+ (NSError *)sdl_lifecycle_startedWithWarning:(SDLResult)result info:(NSString *)info {
    NSDictionary<NSString *, NSString *> *userInfo = @{
                                                       NSLocalizedDescriptionKey: NSLocalizedString(result, nil),
                                                       NSLocalizedFailureReasonErrorKey: NSLocalizedString(info, nil)
                                                       };
    return [NSError errorWithDomain:SDLErrorDomainLifecycleManager
                               code:SDLManagerErrorRegistrationSuccessWithWarning
                           userInfo:userInfo];
}

+ (NSError *)sdl_lifecycle_failedWithBadResult:(SDLResult)result info:(NSString *)info {
    NSDictionary<NSString *, NSString *> *userInfo = @{
        NSLocalizedDescriptionKey: NSLocalizedString(result, nil),
        NSLocalizedFailureReasonErrorKey: NSLocalizedString(info, nil)
    };
    return [NSError errorWithDomain:SDLErrorDomainLifecycleManager
                               code:SDLManagerErrorRegistrationFailed
                           userInfo:userInfo];
}

+ (NSError *)sdl_lifecycle_multipleRequestsCancelled {
    return [NSError errorWithDomain:SDLErrorDomainLifecycleManager
                               code:SDLManagerErrorCancelled
                           userInfo:nil];
}


#pragma mark SDLFileManager

+ (NSError *)sdl_fileManager_cannotOverwriteError {
    NSDictionary<NSString *, NSString *> *userInfo = @{
        NSLocalizedDescriptionKey: NSLocalizedString(@"Cannot overwrite remote file", nil),
        NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"The remote file system already has a file of this name, and the file manager is set to not automatically overwrite files", nil),
        NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Set SDLFileManager autoOverwrite to YES, or call forceUploadFile:completion:", nil)
    };
    return [NSError errorWithDomain:SDLErrorDomainFileManager code:SDLFileManagerErrorCannotOverwrite userInfo:userInfo];
}

+ (NSError *)sdl_fileManager_noKnownFileError {
    NSDictionary<NSString *, NSString *> *userInfo = @{
        NSLocalizedDescriptionKey: NSLocalizedString(@"No such remote file is currently known", nil),
        NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"The remote file is not currently known by the file manager. It could be that this file does not exist on the remote system or that the file manager has not completed its initialization and received a list of files from the remote system.", nil),
        NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Make sure a file with this name is present on the remote system and that the file manager has finished its initialization.", nil)
    };
    return [NSError errorWithDomain:SDLErrorDomainFileManager code:SDLFileManagerErrorNoKnownFile userInfo:userInfo];
}

+ (NSError *)sdl_fileManager_unableToStartError {
    NSDictionary<NSString *, NSString *> *userInfo = @{
        NSLocalizedDescriptionKey: NSLocalizedString(@"The file manager was unable to start", nil),
        NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"This may be because files are not supported on this unit and / or LISTFILES returned an error", nil),
        NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Make sure that the system is sending back a proper LIST FILES response", nil)
    };
    return [NSError errorWithDomain:SDLErrorDomainFileManager code:SDLFileManagerErrorUnableToStart userInfo:userInfo];
}

+ (NSError *)sdl_fileManager_unableToUploadError {
    NSDictionary<NSString *, NSString *> *userInfo = @{
        NSLocalizedDescriptionKey: NSLocalizedString(@"The file manager was unable to send this file", nil),
        NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"This could be because the file manager has not started, or the head unit does not support files", nil),
        NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Make sure that the system is sending back a proper LIST FILES response and check the file manager's state", nil)
    };
    return [NSError errorWithDomain:SDLErrorDomainFileManager code:SDLFileManagerErrorUnableToUpload userInfo:userInfo];
}

+ (NSError *)sdl_fileManager_unableToUpload_ErrorWithUserInfo:(NSDictionary *)userInfo {
    return [NSError errorWithDomain:SDLErrorDomainFileManager code:SDLFileManagerMultipleFileUploadTasksFailed userInfo:userInfo];
}

+ (NSError *)sdl_fileManager_unableToDelete_ErrorWithUserInfo:(NSDictionary *)userInfo {
    return [NSError errorWithDomain:SDLErrorDomainFileManager code:SDLFileManagerMultipleFileDeleteTasksFailed userInfo:userInfo];
}

+ (NSError *)sdl_fileManager_fileUploadCanceled {
    NSDictionary<NSString *, NSString *> *userInfo = @{
                                                       NSLocalizedDescriptionKey: NSLocalizedString(@"The file upload was canceled", nil),
                                                       NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"The file upload transaction was canceled before it could be completed", nil),
                                                       NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"The file upload was canceled", nil)
                                                       };
    return [NSError errorWithDomain:SDLErrorDomainFileManager code:SDLFileManagerUploadCanceled userInfo:userInfo];
}

+ (NSError *)sdl_fileManager_dataMissingError {
    NSDictionary<NSString *, NSString *> *userInfo = @{
                                                       NSLocalizedDescriptionKey: NSLocalizedString(@"The file upload was canceled", nil),
                                                       NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"The data for the file is missing", nil),
                                                       NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Make sure the data used to create the file is valid", nil)
                                                       };
    return [NSError errorWithDomain:SDLErrorDomainFileManager code:SDLFileManagerErrorFileDataMissing userInfo:userInfo];
}

#pragma mark SDLUploadFileOperation

+ (NSError *)sdl_fileManager_fileDoesNotExistError {
    NSDictionary<NSString *, NSString *> *userInfo = @{
                                                       NSLocalizedDescriptionKey: NSLocalizedString(@"The file manager was unable to send the file", nil),
                                                       NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"This could be because the file does not exist at the specified file path or that passed data is invalid", nil),
                                                       NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Make sure that the the correct file path is being set and that the passed data is valid", nil)
                                                       };
    return [NSError errorWithDomain:SDLErrorDomainFileManager code:SDLFileManagerErrorFileDoesNotExist userInfo:userInfo];
}

#pragma mark Screen Managers

+ (NSError *)sdl_textAndGraphicManager_pendingUpdateSuperseded {
    return [NSError errorWithDomain:SDLErrorDomainTextAndGraphicManager code:SDLTextAndGraphicManagerErrorPendingUpdateSuperseded userInfo:nil];
}

+ (NSError *)sdl_softButtonManager_pendingUpdateSuperseded {
    return [NSError errorWithDomain:SDLErrorDomainSoftButtonManager code:SDLSoftButtonManagerErrorPendingUpdateSuperseded userInfo:nil];
}

#pragma mark Menu Manager

+ (NSError *)sdl_menuManager_failedToUpdateWithDictionary:(NSDictionary *)userInfo {
    return [NSError errorWithDomain:SDLErrorDomainMenuManager code:SDLMenuManagerErrorRPCsFailed userInfo:userInfo];
}

#pragma mark Choice Set Manager

+ (NSError *)sdl_choiceSetManager_choicesDeletedBeforePresentation:(NSDictionary *)userInfo {
    return [NSError errorWithDomain:SDLErrorDomainChoiceSetManager code:SDLChoiceSetManagerErrorPendingPresentationDeleted userInfo:userInfo];
}

+ (NSError *)sdl_choiceSetManager_choiceDeletionFailed:(NSDictionary *)userInfo {
    return [NSError errorWithDomain:SDLErrorDomainChoiceSetManager code:SDLChoiceSetManagerErrorDeletionFailed userInfo:userInfo];
}

+ (NSError *)sdl_choiceSetManager_choiceUploadFailed:(NSDictionary *)userInfo {
    return [NSError errorWithDomain:SDLErrorDomainChoiceSetManager code:SDLChoiceSetManagerErrorUploadFailed userInfo:userInfo];
}

#pragma mark Transport

+ (NSError *)sdl_transport_unknownError {
    NSDictionary<NSString *, NSString *> *userInfo = @{
                                                       NSLocalizedDescriptionKey: NSLocalizedString(@"TCP connection error", nil),
                                                       NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"TCP connection cannot be established due to unknown error.", nil),
                                                       NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Make sure that correct IP address and TCP port number are specified, and the phone is connected to the correct Wi-Fi network.", nil)
                                                       };
    return [NSError errorWithDomain:SDLErrorDomainTransport code:SDLTransportErrorUnknown userInfo:userInfo];
}

+ (NSError *)sdl_transport_connectionRefusedError {
    NSDictionary<NSString *, NSString *> *userInfo = @{
                                                       NSLocalizedDescriptionKey: NSLocalizedString(@"TCP connection cannot be established", nil),
                                                       NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"The TCP connection is refused by head unit. Possible causes are that the specified TCP port number is not correct, or SDL Core is not running properly on the head unit.", nil),
                                                       NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Make sure that correct IP address and TCP port number are specified. Also, make sure that SDL Core on the head unit enables TCP transport.", nil)
                                                       };
    return [NSError errorWithDomain:SDLErrorDomainTransport code:SDLTransportErrorConnectionRefused userInfo:userInfo];
}

+ (NSError *)sdl_transport_connectionTimedOutError {
    NSDictionary<NSString *, NSString *> *userInfo = @{
                                                       NSLocalizedDescriptionKey: NSLocalizedString(@"TCP connection timed out", nil),
                                                       NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"The TCP connection cannot be established within a given time. Possible causes are that the specified IP address is not correct, or the connection is blocked by a firewall.", nil),
                                                       NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Make sure that correct IP address and TCP port number are specified. Also, make sure that the head unit's system configuration accepts TCP connections.", nil)
                                                       };
    return [NSError errorWithDomain:SDLErrorDomainTransport code:SDLTransportErrorConnectionTimedOut userInfo:userInfo];
}

+ (NSError *)sdl_transport_networkDownError {
    NSDictionary<NSString *, NSString *> *userInfo = @{
                                                       NSLocalizedDescriptionKey: NSLocalizedString(@"Network is not available", nil),
                                                       NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"TCP connection cannot be established because the phone is not connected to the network. Possible causes are: Wi-Fi being disabled on the phone or the phone is connected to a wrong Wi-Fi network.", nil),
                                                       NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Make sure that the phone is connected to the Wi-Fi network that has the head unit on it. Also, make sure that correct IP address and TCP port number are specified.", nil)
                                                       };
    return [NSError errorWithDomain:SDLErrorDomainTransport code:SDLTransportErrorNetworkDown userInfo:userInfo];
}

@end


@implementation NSException (SDLExceptions)

+ (NSException *)sdl_missingHandlerException {
    return [NSException
        exceptionWithName:@"MissingHandlerException"
                   reason:@"This request requires a handler to be specified using the <RPC>WithHandler class"
                 userInfo:nil];
}

+ (NSException *)sdl_missingIdException {
    return [NSException
        exceptionWithName:@"MissingIdException"
                   reason:@"This request requires an ID (command, softbutton, etc) to be specified"
                 userInfo:nil];
}

+ (NSException *)sdl_missingFilesException {
    return [NSException
            exceptionWithName:@"MissingFilesNames"
            reason:@"This request requires that the array of files not be empty"
            userInfo:nil];
}

+ (NSException *)sdl_invalidSoftButtonStateException {
    return [NSException exceptionWithName:@"InvalidSoftButtonState" reason:@"Attempting to transition to a state that does not exist" userInfo:nil];
}

+ (NSException *)sdl_carWindowOrientationException {
    return [NSException exceptionWithName:@"com.sdl.carwindow.orientationException"
                                   reason:@"SDLCarWindow rootViewController must support only a single interface orientation"
                                 userInfo:nil];
}

@end

NS_ASSUME_NONNULL_END
