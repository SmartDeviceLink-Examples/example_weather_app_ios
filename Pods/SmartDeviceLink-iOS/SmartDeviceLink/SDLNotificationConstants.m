//
//  SDLNotificationConstants.m
//  SmartDeviceLink-iOS
//
//  Created by Justin Dickow on 9/30/15.
//  Copyright © 2015 smartdevicelink. All rights reserved.
//

#import "SDLNotificationConstants.h"

SDLNotificationUserInfoKey const SDLNotificationUserInfoObject = @"SDLNotificationUserInfoObject";


#pragma mark - General notifications
SDLNotificationName const SDLTransportDidDisconnect = @"com.sdl.transport.disconnect";
SDLNotificationName const SDLTransportDidConnect = @"com.sdl.transport.connect";
SDLNotificationName const SDLDidReceiveError = @"com.sdl.general.error";
SDLNotificationName const SDLDidReceiveLockScreenIcon = @"com.sdl.general.lockscreenIconReceived";
SDLNotificationName const SDLDidBecomeReady = @"com.sdl.notification.managerReady";
SDLNotificationName const SDLDidReceiveVehicleIconNotification = @"com.sdl.notification.vehicleIcon";

#pragma mark - RPC Responses
SDLNotificationName const SDLDidReceiveAddCommandResponse = @"com.sdl.response.addCommand";
SDLNotificationName const SDLDidReceiveAddSubMenuResponse = @"com.sdl.response.addSubMenu";
SDLNotificationName const SDLDidReceiveAlertResponse = @"com.sdl.response.alert";
SDLNotificationName const SDLDidReceiveAlertManeuverResponse = @"com.sdl.response.alertManeuver";
SDLNotificationName const SDLDidReceiveChangeRegistrationResponse = @"com.sdl.response.changeRegistration";
SDLNotificationName const SDLDidReceiveCreateInteractionChoiceSetResponse = @"com.sdl.response.createInteractionChoiceSet";
SDLNotificationName const SDLDidReceiveDeleteCommandResponse = @"com.sdl.response.deleteCommand";
SDLNotificationName const SDLDidReceiveDeleteFileResponse = @"com.sdl.response.deleteFile";
SDLNotificationName const SDLDidReceiveDeleteInteractionChoiceSetResponse = @"com.sdl.response.deleteInteractionChoiceSet";
SDLNotificationName const SDLDidReceiveDeleteSubmenuResponse = @"com.sdl.response.deleteSubmenu";
SDLNotificationName const SDLDidReceiveDiagnosticMessageResponse = @"com.sdl.response.diagnosticMessage";
SDLNotificationName const SDLDidReceiveDialNumberResponse = @"com.sdl.response.dialNumber";
SDLNotificationName const SDLDidReceiveEncodedSyncPDataResponse = @"com.sdl.response.encodedSyncPData";
SDLNotificationName const SDLDidReceiveEndAudioPassThruResponse = @"com.sdl.response.endAudioPassThru";
SDLNotificationName const SDLDidReceiveGenericResponse = @"com.sdl.response.generic";
SDLNotificationName const SDLDidReceiveGetDTCsResponse = @"com.sdl.response.getDTCs";
SDLNotificationName const SDLDidReceiveGetVehicleDataResponse = @"com.sdl.response.getVehicleData";
SDLNotificationName const SDLDidReceiveListFilesResponse = @"com.sdl.response.listFiles";
SDLNotificationName const SDLDidReceivePerformAudioPassThruResponse = @"com.sdl.response.performAudioPassThru";
SDLNotificationName const SDLDidReceivePerformInteractionResponse = @"com.sdl.response.performInteraction";
SDLNotificationName const SDLDidReceivePutFileResponse = @"com.sdl.response.putFile";
SDLNotificationName const SDLDidReceiveReadDIDResponse = @"com.sdl.response.readDID";
SDLNotificationName const SDLDidReceiveRegisterAppInterfaceResponse = @"com.sdl.response.registerAppInterface";
SDLNotificationName const SDLDidReceiveResetGlobalPropertiesResponse = @"com.sdl.response.resetGlobalProperties";
SDLNotificationName const SDLDidReceiveScrollableMessageResponse = @"com.sdl.response.scrollableMessage";
SDLNotificationName const SDLDidReceiveSendLocationResponse = @"com.sdl.response.sendLocation";
SDLNotificationName const SDLDidReceiveSetAppIconResponse = @"com.sdl.response.setAppIcon";
SDLNotificationName const SDLDidReceiveSetDisplayLayoutResponse = @"com.sdl.response.setDisplayLayout";
SDLNotificationName const SDLDidReceiveSetGlobalPropertiesResponse = @"com.sdl.response.setGlobalProperties";
SDLNotificationName const SDLDidReceiveSetMediaClockTimerResponse = @"com.sdl.response.setMediaClockTimer";
SDLNotificationName const SDLDidReceiveShowConstantTBTResponse = @"com.sdl.response.showConstantTBT";
SDLNotificationName const SDLDidReceiveShowResponse = @"com.sdl.response.show";
SDLNotificationName const SDLDidReceiveSliderResponse = @"com.sdl.response.slider";
SDLNotificationName const SDLDidReceiveSpeakResponse = @"com.sdl.response.speak";
SDLNotificationName const SDLDidReceiveSubscribeButtonResponse = @"com.sdl.response.subscribeButton";
SDLNotificationName const SDLDidReceiveSubscribeVehicleDataResponse = @"com.sdl.response.subscribeVehicleData";
SDLNotificationName const SDLDidReceiveSyncPDataResponse = @"com.sdl.response.syncPData";
SDLNotificationName const SDLDidReceiveUpdateTurnListResponse = @"com.sdl.response.updateTurnList";
SDLNotificationName const SDLDidReceiveUnregisterAppInterfaceResponse = @"com.sdl.response.unregisterAppInterface";
SDLNotificationName const SDLDidReceiveUnsubscribeButtonResponse = @"com.sdl.response.unsubscribeButton";
SDLNotificationName const SDLDidReceiveUnsubscribeVehicleDataResponse = @"com.sdl.response.unsubscribeVehicleData";

#pragma mark - RPC Notifications
SDLNotificationName const SDLDidChangeDriverDistractionStateNotification = @"com.sdl.notification.changeDriverDistractionStateNotification";
SDLNotificationName const SDLDidChangeHMIStatusNotification = @"com.sdl.notification.changeHMIStatus";
SDLNotificationName const SDLDidReceiveAudioPassThruNotification = @"com.sdl.notification.audioPassThru";
SDLNotificationName const SDLDidReceiveAppUnregisteredNotification = @"com.sdl.notification.appUnregistered";
SDLNotificationName const SDLDidReceiveButtonEventNotification = @"com.sdl.notification.buttonEvent";
SDLNotificationName const SDLDidReceiveButtonPressNotification = @"com.sdl.notification.buttonPress";
SDLNotificationName const SDLDidReceiveCommandNotification = @"com.sdl.notification.command";
SDLNotificationName const SDLDidReceiveEncodedDataNotification = @"com.sdl.notification.encodedData";
SDLNotificationName const SDLDidReceiveKeyboardInputNotification = @"com.sdl.notification.keyboardInput";
SDLNotificationName const SDLDidChangeLanguageNotification = @"com.sdl.notification.changeLanguage";
SDLNotificationName const SDLDidChangeLockScreenStatusNotification = @"com.sdl.notification.lockScreenStatus";
SDLNotificationName const SDLDidReceiveNewHashNotification = @"com.sdl.notification.newHash";
SDLNotificationName const SDLDidChangePermissionsNotification = @"com.sdl.notification.changePermission";
SDLNotificationName const SDLDidReceiveSystemRequestNotification = @"com.sdl.notification.receiveSystemRequest";
SDLNotificationName const SDLDidChangeTurnByTurnStateNotification = @"com.sdl.notification.changeTurnByTurnState";
SDLNotificationName const SDLDidReceiveTouchEventNotification = @"com.sdl.notification.touchEvent";
SDLNotificationName const SDLDidReceiveVehicleDataNotification = @"com.sdl.notification.vehicleData";


@implementation SDLNotificationConstants

+ (NSArray<SDLNotificationName> *)allResponseNames {
    return @[SDLDidReceiveAddCommandResponse,
             SDLDidReceiveAddSubMenuResponse,
             SDLDidReceiveAlertResponse,
             SDLDidReceiveAlertManeuverResponse,
             SDLDidReceiveChangeRegistrationResponse,
             SDLDidReceiveCreateInteractionChoiceSetResponse,
             SDLDidReceiveDeleteCommandResponse,
             SDLDidReceiveDeleteFileResponse,
             SDLDidReceiveDeleteInteractionChoiceSetResponse,
             SDLDidReceiveDeleteSubmenuResponse,
             SDLDidReceiveDiagnosticMessageResponse,
             SDLDidReceiveDialNumberResponse,
             SDLDidReceiveEncodedSyncPDataResponse,
             SDLDidReceiveEndAudioPassThruResponse,
             SDLDidReceiveGenericResponse,
             SDLDidReceiveGetDTCsResponse,
             SDLDidReceiveGetVehicleDataResponse,
             SDLDidReceiveListFilesResponse,
             SDLDidReceivePerformAudioPassThruResponse,
             SDLDidReceivePerformInteractionResponse,
             SDLDidReceivePutFileResponse,
             SDLDidReceiveReadDIDResponse,
             SDLDidReceiveRegisterAppInterfaceResponse,
             SDLDidReceiveResetGlobalPropertiesResponse,
             SDLDidReceiveScrollableMessageResponse,
             SDLDidReceiveSendLocationResponse,
             SDLDidReceiveSetAppIconResponse,
             SDLDidReceiveSetDisplayLayoutResponse,
             SDLDidReceiveSetGlobalPropertiesResponse,
             SDLDidReceiveSetMediaClockTimerResponse,
             SDLDidReceiveShowConstantTBTResponse,
             SDLDidReceiveShowResponse,
             SDLDidReceiveSliderResponse,
             SDLDidReceiveSpeakResponse,
             SDLDidReceiveSubscribeButtonResponse,
             SDLDidReceiveSubscribeVehicleDataResponse,
             SDLDidReceiveSyncPDataResponse,
             SDLDidReceiveUpdateTurnListResponse,
             SDLDidReceiveUnregisterAppInterfaceResponse,
             SDLDidReceiveUnsubscribeButtonResponse,
             SDLDidReceiveUnsubscribeVehicleDataResponse];
}

+ (NSArray<SDLNotificationName> *)allButtonEventNotifications {
    return @[SDLDidReceiveButtonEventNotification,
             SDLDidReceiveButtonPressNotification];
}

@end
