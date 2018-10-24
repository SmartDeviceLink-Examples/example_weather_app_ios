//
//  SDLTextAndGraphicManager.m
//  SmartDeviceLink
//
//  Created by Joel Fischer on 2/22/18.
//  Copyright © 2018 smartdevicelink. All rights reserved.
//

#import "SDLTextAndGraphicManager.h"

#import "SDLArtwork.h"
#import "SDLConnectionManagerType.h"
#import "SDLDisplayCapabilities.h"
#import "SDLDisplayCapabilities+ShowManagerExtensions.h"
#import "SDLError.h"
#import "SDLFileManager.h"
#import "SDLImage.h"
#import "SDLLogMacros.h"
#import "SDLMetadataTags.h"
#import "SDLNotificationConstants.h"
#import "SDLOnHMIStatus.h"
#import "SDLRegisterAppInterfaceResponse.h"
#import "SDLRPCNotificationNotification.h"
#import "SDLRPCResponseNotification.h"
#import "SDLSetDisplayLayoutResponse.h"
#import "SDLShow.h"
#import "SDLTextField.h"

NS_ASSUME_NONNULL_BEGIN

@interface SDLTextAndGraphicManager()

// Dependencies
@property (weak, nonatomic) id<SDLConnectionManagerType> connectionManager;
@property (weak, nonatomic) SDLFileManager *fileManager;

/**
 A show describing the current text and images on the screen (not soft buttons, etc.)
 */
@property (strong, nonatomic) SDLShow *currentScreenData;

/**
 This is the "full" update, including both text and image names, whether or not that will succeed at the moment (e.g. if images are in the process of uploading)
 */
@property (strong, nonatomic, nullable) SDLShow *inProgressUpdate;
@property (copy, nonatomic, nullable) SDLTextAndGraphicUpdateCompletionHandler inProgressHandler;

@property (strong, nonatomic, nullable) SDLShow *queuedImageUpdate;
@property (assign, nonatomic) BOOL hasQueuedUpdate;
@property (copy, nonatomic, nullable) SDLTextAndGraphicUpdateCompletionHandler queuedUpdateHandler;

@property (strong, nonatomic, nullable) SDLDisplayCapabilities *displayCapabilities;
@property (strong, nonatomic, nullable) SDLHMILevel currentLevel;

@property (strong, nonatomic, nullable) SDLArtwork *blankArtwork;

@property (assign, nonatomic) BOOL waitingOnHMILevelUpdateToUpdate;
@property (assign, nonatomic) BOOL isDirty;

@end

@implementation SDLTextAndGraphicManager

- (instancetype)initWithConnectionManager:(id<SDLConnectionManagerType>)connectionManager fileManager:(nonnull SDLFileManager *)fileManager {
    self = [super init];
    if (!self) { return nil; }

    _connectionManager = connectionManager;
    _fileManager = fileManager;

    _alignment = SDLTextAlignmentCenter;

    _currentScreenData = [[SDLShow alloc] init];
    _currentLevel = SDLHMILevelNone;

    _waitingOnHMILevelUpdateToUpdate = NO;
    _isDirty = NO;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sdl_registerResponse:) name:SDLDidReceiveRegisterAppInterfaceResponse object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sdl_displayLayoutResponse:) name:SDLDidReceiveSetDisplayLayoutResponse object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sdl_hmiStatusNotification:) name:SDLDidChangeHMIStatusNotification object:nil];

    return self;
}

- (void)stop {
    _textField1 = nil;
    _textField2 = nil;
    _textField3 = nil;
    _textField4 = nil;
    _mediaTrackTextField = nil;
    _primaryGraphic = nil;
    _secondaryGraphic = nil;
    _alignment = SDLTextAlignmentCenter;
    _textField1Type = nil;
    _textField2Type = nil;
    _textField3Type = nil;
    _textField4Type = nil;

    _currentScreenData = [[SDLShow alloc] init];
    _inProgressUpdate = nil;
    _inProgressHandler = nil;
    _queuedImageUpdate = nil;
    _hasQueuedUpdate = NO;
    _queuedUpdateHandler = nil;
    _displayCapabilities = nil;
    _currentLevel = SDLHMILevelNone;
    _blankArtwork = nil;
    _waitingOnHMILevelUpdateToUpdate = NO;
    _isDirty = NO;
}

#pragma mark - Upload / Send

- (void)updateWithCompletionHandler:(nullable SDLTextAndGraphicUpdateCompletionHandler)handler {
    if (self.isBatchingUpdates) { return; }

    // Don't send if we're in HMI NONE
    if (self.currentLevel == nil || [self.currentLevel isEqualToString:SDLHMILevelNone]) {
        self.waitingOnHMILevelUpdateToUpdate = YES;
        return;
    } else {
        self.waitingOnHMILevelUpdateToUpdate = NO;
    }

    if (self.isDirty) {
        self.isDirty = NO;
        [self sdl_updateWithCompletionHandler:handler];
    }
}

- (void)sdl_updateWithCompletionHandler:(nullable SDLTextAndGraphicUpdateCompletionHandler)handler {
    SDLLogD(@"Updating text and graphics");
    if (self.inProgressUpdate != nil) {
        SDLLogV(@"In progress update exists, queueing update");
        // If we already have a pending update, we're going to tell the old handler that it was superseded by a new update and then return
        if (self.queuedUpdateHandler != nil) {
            SDLLogV(@"Queued update already exists, superseding previous queued update");
            self.queuedUpdateHandler([NSError sdl_textAndGraphicManager_pendingUpdateSuperseded]);
            self.queuedUpdateHandler = nil;
        }

        if (handler != nil) {
            self.queuedUpdateHandler = handler;
        } else {
            self.hasQueuedUpdate = YES;
        }

        return;
    }

    SDLShow *fullShow = [[SDLShow alloc] init];
    fullShow.alignment = self.alignment;
    fullShow.metadataTags = [[SDLMetadataTags alloc] init];
    fullShow = [self sdl_assembleShowText:fullShow];
    fullShow = [self sdl_assembleShowImages:fullShow];

    self.inProgressHandler = handler;

    __weak typeof(self)weakSelf = self;
    if (!([self sdl_shouldUpdatePrimaryImage] || [self sdl_shouldUpdateSecondaryImage])) {
        SDLLogV(@"No images to send, sending text");
        // If there are no images to update, just send the text
        self.inProgressUpdate = [self sdl_extractTextFromShow:fullShow];
    } else if ([self sdl_isArtworkUploadedOrNonExistent:self.primaryGraphic] && [self sdl_isArtworkUploadedOrNonExistent:self.secondaryGraphic]) {
        SDLLogV(@"Images already uploaded, sending full update");
        // The files to be updated are already uploaded, send the full show immediately
        self.inProgressUpdate = fullShow;
    } else {
        SDLLogV(@"Images need to be uploaded, sending text and uploading images");

        // We need to upload or queue the upload of the images
        // Send the text immediately
        self.inProgressUpdate = [self sdl_extractTextFromShow:fullShow];

        // Start uploading the images
        __block SDLShow *thisUpdate = fullShow;
        [self sdl_uploadImagesWithCompletionHandler:^(NSError * _Nonnull error) {
            __strong typeof(weakSelf) strongSelf = weakSelf;

            if (error != nil) {
                SDLShow *showWithGraphics = [self sdl_createImageOnlyShowWithPrimaryArtwork:self.primaryGraphic secondaryArtwork:self.secondaryGraphic];
                if (showWithGraphics != nil) {
                    SDLLogW(@"Some images failed to upload. Sending update with the successfully uploaded images");
                    self.inProgressUpdate = showWithGraphics;
                } else {
                    SDLLogE(@"All images failed to upload. No graphics to show, skipping update.");
                    self.inProgressUpdate = nil;
                }
                return;
            }

            // Check if queued image update still matches our images (there could have been a new Show in the meantime) and send a new update if it does. Since the images will already be on the head unit, the whole show will be sent
            // TODO: Send delete if it doesn't?
            if ([strongSelf sdl_showImages:thisUpdate isEqualToShowImages:strongSelf.queuedImageUpdate]) {
                SDLLogV(@"Queued image update matches the images we need, sending update");
                return [strongSelf sdl_updateWithCompletionHandler:strongSelf.inProgressHandler];
            } else {
                SDLLogV(@"Queued image update does not match the images we need, skipping update");
            }
        }];
        // When the images are done uploading, send another show with the images
        self.queuedImageUpdate = fullShow;
    }

    if (self.inProgressUpdate == nil) { return; }

    [self.connectionManager sendConnectionRequest:self.inProgressUpdate withResponseHandler:^(__kindof SDLRPCRequest * _Nullable request, __kindof SDLRPCResponse * _Nullable response, NSError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        SDLLogD(@"Text and Graphic update completed");

        // TODO: Monitor and delete old images when space is low?
        if (response.success) {
            [strongSelf sdl_updateCurrentScreenDataFromShow:(SDLShow *)request];
        }

        strongSelf.inProgressUpdate = nil;
        if (strongSelf.inProgressHandler != nil) {
            strongSelf.inProgressHandler(error);
            strongSelf.inProgressHandler = nil;
        }

        if (strongSelf.hasQueuedUpdate) {
            SDLLogV(@"Queued update exists, sending another update");
            [strongSelf sdl_updateWithCompletionHandler:[strongSelf.queuedUpdateHandler copy]];
            strongSelf.queuedUpdateHandler = nil;
            strongSelf.hasQueuedUpdate = NO;
        }
    }];
}

- (void)sdl_uploadImagesWithCompletionHandler:(void (^)(NSError *error))handler {
    NSMutableArray<SDLArtwork *> *artworksToUpload = [NSMutableArray array];
    if ([self sdl_shouldUpdatePrimaryImage]) {
        [artworksToUpload addObject:self.primaryGraphic];
    }
    if ([self sdl_shouldUpdateSecondaryImage]) {
        [artworksToUpload addObject:self.secondaryGraphic];
    }

    [self.fileManager uploadArtworks:artworksToUpload completionHandler:^(NSArray<NSString *> * _Nonnull artworkNames, NSError * _Nullable error) {
        if (error != nil) {
            SDLLogW(@"Text and graphic manager artwork failed to upload with error: %@", error.localizedDescription);
        }

        handler(error);
    }];
}

#pragma mark - Assembly of Shows

#pragma mark Images

- (SDLShow *)sdl_assembleShowImages:(SDLShow *)show {
    if (![self sdl_shouldUpdatePrimaryImage] && ![self sdl_shouldUpdateSecondaryImage]) {
        return show;
    }

    if ([self sdl_shouldUpdatePrimaryImage]) {
        show.graphic = [[SDLImage alloc] initWithName:self.primaryGraphic.name ofType:SDLImageTypeDynamic isTemplate:self.primaryGraphic.isTemplate];
    }
    if ([self sdl_shouldUpdateSecondaryImage]) {
        show.secondaryGraphic = [[SDLImage alloc] initWithName:self.secondaryGraphic.name ofType:SDLImageTypeDynamic isTemplate:self.secondaryGraphic.isTemplate];
    }

    return show;
}

#pragma mark Text

- (SDLShow *)sdl_assembleShowText:(SDLShow *)show {
    [self sdl_setBlankTextFieldsWithShow:show];

    if (self.mediaTrackTextField != nil) {
        show.mediaTrack = self.mediaTrackTextField;
    } else {
        show.mediaTrack = @"";
    }
    
    NSArray *nonNilFields = [self sdl_findNonNilTextFields];
    if (nonNilFields.count == 0) { return show; }

    NSUInteger numberOfLines = self.displayCapabilities ? self.displayCapabilities.maxNumberOfMainFieldLines : 4;
    if (numberOfLines == 1) {
        show = [self sdl_assembleOneLineShowText:show withShowFields:nonNilFields];
    } else if (numberOfLines == 2) {
        show = [self sdl_assembleTwoLineShowText:show];
    } else if (numberOfLines == 3) {
        show = [self sdl_assembleThreeLineShowText:show];
    } else if (numberOfLines == 4) {
        show = [self sdl_assembleFourLineShowText:show];
    }

    return show;
}

- (SDLShow *)sdl_assembleOneLineShowText:(SDLShow *)show withShowFields:(NSArray<NSString *> *)fields {
    NSMutableString *showString1 = [NSMutableString stringWithString:fields[0]];
    for (NSUInteger i = 1; i < fields.count; i++) {
        [showString1 appendFormat:@" - %@", fields[i]];
    }
    show.mainField1 = showString1.copy;

    SDLMetadataTags *tags = [[SDLMetadataTags alloc] init];
    NSMutableArray<SDLMetadataType> *metadataArray = [NSMutableArray array];
    self.textField1Type ? [metadataArray addObject:self.textField1Type] : nil;
    self.textField2Type ? [metadataArray addObject:self.textField2Type] : nil;
    self.textField3Type ? [metadataArray addObject:self.textField3Type] : nil;
    self.textField4Type ? [metadataArray addObject:self.textField4Type] : nil;
    tags.mainField1 = [metadataArray copy];
    show.metadataTags = tags;

    return show;
}

- (SDLShow *)sdl_assembleTwoLineShowText:(SDLShow *)show {
    NSMutableString *tempString = [NSMutableString string];
    if (self.textField1.length > 0) {
        // If text 1 exists, put it in slot 1
        [tempString appendString:self.textField1];
        show.metadataTags.mainField1 = self.textField1Type.length > 0 ? @[self.textField1Type] : @[];
    }

    if (self.textField2.length > 0) {
        if (!(self.textField3.length > 0 || self.textField4.length > 0)) {
            // If text 3 & 4 do not exist, put it in slot 2
            show.mainField2 = self.textField2;
            show.metadataTags.mainField2 = self.textField2Type.length > 0 ? @[self.textField2Type] : @[];
        } else if (self.textField1.length > 0) {
            // If text 1 exists, put it in slot 1 formatted
            [tempString appendFormat:@" - %@", self.textField2];
            show.metadataTags.mainField1 = self.textField2Type.length > 0 ? [show.metadataTags.mainField1 arrayByAddingObjectsFromArray:@[self.textField2Type]] : show.metadataTags.mainField1;
        } else {
            // If text 1 does not exist, put it in slot 1 unformatted
            [tempString appendString:self.textField2];
            show.metadataTags.mainField1 = self.textField2Type.length > 0 ? @[self.textField2Type] : @[];
        }
    }

    show.mainField1 = [tempString copy];

    tempString = [NSMutableString string];
    if (self.textField3.length > 0) {
        // If text 3 exists, put it in slot 2
        [tempString appendString:self.textField3];
        show.metadataTags.mainField2 = self.textField3Type.length > 0 ? @[self.textField3Type] : @[];
    }

    if (self.textField4.length > 0) {
        if (self.textField3.length > 0) {
            // If text 3 exists, put it in slot 2 formatted
            [tempString appendFormat:@" - %@", self.textField4];
            show.metadataTags.mainField2 = self.textField4Type.length > 0 ? [show.metadataTags.mainField2 arrayByAddingObjectsFromArray:@[self.textField4Type]] : show.metadataTags.mainField2;
        } else {
            // If text 3 does not exist, put it in slot 3 unformatted
            [tempString appendString:self.textField4];
            show.metadataTags.mainField2 = self.textField4Type.length > 0 ? @[self.textField4Type] : @[];
        }
    }

    if (tempString.length > 0) {
        show.mainField2 = [tempString copy];
    }

    return show;
}

- (SDLShow *)sdl_assembleThreeLineShowText:(SDLShow *)show {
    if (self.textField1.length > 0) {
        show.mainField1 = self.textField1;
        show.metadataTags.mainField1 = self.textField1Type.length > 0 ? @[self.textField1Type] : @[];
    }

    if (self.textField2.length > 0) {
        show.mainField2 = self.textField2;
        show.metadataTags.mainField2 = self.textField2Type.length > 0 ? @[self.textField2Type] : @[];
    }

    NSMutableString *tempString = [NSMutableString string];
    if (self.textField3.length > 0) {
        [tempString appendString:self.textField3];
        show.metadataTags.mainField3 = self.textField3Type.length > 0 ? @[self.textField3Type] : @[];
    }

    if (self.textField4.length > 0) {
        if (self.textField3.length > 0) {
            // If text 3 exists, put it in slot 3 formatted
            [tempString appendFormat:@" - %@", self.textField4];
            show.metadataTags.mainField3 = self.textField4Type.length > 0 ? [show.metadataTags.mainField3 arrayByAddingObjectsFromArray:@[self.textField4Type]] : show.metadataTags.mainField3;
        } else {
            // If text 3 does not exist, put it in slot 3 formatted
            [tempString appendString:self.textField4];
            show.metadataTags.mainField3 = self.textField4Type.length > 0 ? @[self.textField4Type] : @[];
        }
    }

    show.mainField3 = [tempString copy];

    return show;
}

- (SDLShow *)sdl_assembleFourLineShowText:(SDLShow *)show {
    if (self.textField1.length > 0) {
        show.mainField1 = self.textField1;
        show.metadataTags.mainField1 = self.textField1Type.length > 0 ? @[self.textField1Type] : @[];
    }

    if (self.textField2.length > 0) {
        show.mainField2 = self.textField2;
        show.metadataTags.mainField2 = self.textField2Type.length > 0 ? @[self.textField2Type] : @[];
    }

    if (self.textField3.length > 0) {
        show.mainField3 = self.textField3;
        show.metadataTags.mainField3 = self.textField3Type.length > 0 ? @[self.textField3Type] : @[];
    }

    if (self.textField4.length > 0) {
        show.mainField4 = self.textField4;
        show.metadataTags.mainField4 = self.textField4Type.length > 0 ? @[self.textField4Type] : @[];
    }

    return show;
}

- (SDLShow *)sdl_setBlankTextFieldsWithShow:(SDLShow *)show {
    show.mainField1 = @"";
    show.mainField2 = @"";
    show.mainField3 = @"";
    show.mainField4 = @"";
    show.mediaTrack = @"";

    return show;
}

#pragma mark - Extraction

- (SDLShow *)sdl_extractTextFromShow:(SDLShow *)show {
    SDLShow *newShow = [[SDLShow alloc] init];
    newShow.mainField1 = show.mainField1;
    newShow.mainField2 = show.mainField2;
    newShow.mainField3 = show.mainField3;
    newShow.mainField4 = show.mainField4;
    newShow.mediaTrack = show.mediaTrack;
    newShow.metadataTags = show.metadataTags;

    return newShow;
}

- (SDLShow *)sdl_extractImageFromShow:(SDLShow *)show {
    SDLShow *newShow = [[SDLShow alloc] init];
    newShow.graphic = show.graphic;
    newShow.secondaryGraphic = show.secondaryGraphic;

    return newShow;
}

- (nullable SDLShow *)sdl_createImageOnlyShowWithPrimaryArtwork:(nullable SDLArtwork *)primaryArtwork secondaryArtwork:(nullable SDLArtwork *)secondaryArtwork  {
    SDLShow *newShow = [[SDLShow alloc] init];
    newShow.graphic = [self sdl_isArtworkUploadedOrNonExistent:primaryArtwork] ? [[SDLImage alloc] initWithName:primaryArtwork.name ofType:SDLImageTypeDynamic isTemplate:primaryArtwork.isTemplate] : nil;
    newShow.secondaryGraphic = [self sdl_isArtworkUploadedOrNonExistent:secondaryArtwork] ? [[SDLImage alloc] initWithName:secondaryArtwork.name ofType:SDLImageTypeDynamic isTemplate:secondaryArtwork.isTemplate] : nil;

    if (newShow.graphic == nil && newShow.secondaryGraphic == nil) {
        SDLLogV(@"No graphics to upload");
        return nil;
    }

    return newShow;
}

- (void)sdl_updateCurrentScreenDataFromShow:(SDLShow *)show {
    // If the items are nil, they were not updated, so we can't just set it directly
    self.currentScreenData.mainField1 = show.mainField1 ?: self.currentScreenData.mainField1;
    self.currentScreenData.mainField2 = show.mainField2 ?: self.currentScreenData.mainField2;
    self.currentScreenData.mainField3 = show.mainField3 ?: self.currentScreenData.mainField3;
    self.currentScreenData.mainField4 = show.mainField4 ?: self.currentScreenData.mainField4;
    self.currentScreenData.mediaTrack = show.mediaTrack ?: self.currentScreenData.mediaTrack;
    self.currentScreenData.metadataTags = show.metadataTags ?: self.currentScreenData.metadataTags;
    self.currentScreenData.alignment = show.alignment ?: self.currentScreenData.alignment;
    self.currentScreenData.graphic = show.graphic ?: self.currentScreenData.graphic;
    self.currentScreenData.secondaryGraphic = show.secondaryGraphic ?: self.currentScreenData.secondaryGraphic;
}

#pragma mark - Helpers

/**
 *  Checks if an artwork needs to be uploaded to Core.
 *
 *  @param artwork     The artwork to be uploaded to Core
 *  @return            True if the artwork does not need to be uploaded to Core; false if artwork stills needs to be sent to Core.
 */
- (BOOL)sdl_isArtworkUploadedOrNonExistent:(SDLArtwork *)artwork {
    return (!artwork || [self.fileManager hasUploadedFile:artwork]);
}

- (BOOL)sdl_shouldUpdatePrimaryImage {
    BOOL hasGraphic = self.displayCapabilities ? [self.displayCapabilities hasImageFieldOfName:SDLImageFieldNameGraphic] : YES;

    return (hasGraphic
            && ![self.currentScreenData.graphic.value isEqualToString:self.primaryGraphic.name]
            && self.primaryGraphic != nil);
}

- (BOOL)sdl_shouldUpdateSecondaryImage {
    BOOL hasGraphic = self.displayCapabilities ? [self.displayCapabilities hasImageFieldOfName:SDLImageFieldNameGraphic] : YES;

    // Cannot detect if there is a secondary image, so we'll just try to detect if there's a primary image and allow it if there is.
    return (hasGraphic
            && ![self.currentScreenData.secondaryGraphic.value isEqualToString:self.secondaryGraphic.name]
            && self.secondaryGraphic != nil);
}

- (NSArray<NSString *> *)sdl_findNonNilTextFields {
    NSMutableArray *array = [NSMutableArray array];
    self.textField1.length > 0 ? [array addObject:self.textField1] : nil;
    self.textField2.length > 0 ? [array addObject:self.textField2] : nil;
    self.textField3.length > 0 ? [array addObject:self.textField3] : nil;
    self.textField4.length > 0 ? [array addObject:self.textField4] : nil;

    return [array copy];
}

- (NSArray<SDLMetadataType> *)sdl_findNonNilMetadataFields {
    NSMutableArray *array = [NSMutableArray array];
    self.textField1Type.length > 0 ? [array addObject:self.textField1Type] : nil;
    self.textField2Type.length > 0 ? [array addObject:self.textField2Type] : nil;
    self.textField3Type.length > 0 ? [array addObject:self.textField3Type] : nil;
    self.textField4Type.length > 0 ? [array addObject:self.textField4Type] : nil;

    return [array copy];
}

- (BOOL)sdl_hasData {
    BOOL hasTextFields = ([self sdl_findNonNilTextFields].count > 0);
    BOOL hasImageFields = (self.primaryGraphic != nil) || (self.secondaryGraphic != nil);

    return hasTextFields || hasImageFields;
}

#pragma mark - Equality

- (BOOL)sdl_showImages:(SDLShow *)show isEqualToShowImages:(SDLShow *)show2 {
    BOOL same = NO;
    same = ((show.graphic.value == nil && show.graphic.value == nil)
            || [show.graphic.value isEqualToString:show2.graphic.value]);
    if (!same) { return NO; }

    same = ((show.secondaryGraphic.value == nil && show.secondaryGraphic.value == nil)
            || [show.secondaryGraphic.value isEqualToString:show2.secondaryGraphic.value]);

    return same;
}

#pragma mark - Getters / Setters

#pragma mark - Setters

- (void)setTextField1:(nullable NSString *)textField1 {
    _textField1 = textField1;
    _isDirty = YES;
    if (!self.isBatchingUpdates) {
        // If we aren't batching, send the update immediately, if we are, set ourselves as dirty (so we know we should send an update after the batch ends)
        [self updateWithCompletionHandler:nil];
    }
}

- (void)setTextField2:(nullable NSString *)textField2 {
    _textField2 = textField2;
    _isDirty = YES;
    if (!self.isBatchingUpdates) {
        [self updateWithCompletionHandler:nil];
    }
}

- (void)setTextField3:(nullable NSString *)textField3 {
    _textField3 = textField3;
    _isDirty = YES;
    if (!self.isBatchingUpdates) {
        [self updateWithCompletionHandler:nil];
    }
}

- (void)setTextField4:(nullable NSString *)textField4 {
    _textField4 = textField4;
    _isDirty = YES;
    if (!self.isBatchingUpdates) {
        [self updateWithCompletionHandler:nil];
    }
}

- (void)setMediaTrackTextField:(nullable NSString *)mediaTrackTextField {
    _mediaTrackTextField = mediaTrackTextField;
    _isDirty = YES;
    if (!self.isBatchingUpdates) {
        [self updateWithCompletionHandler:nil];
    }
}

- (void)setPrimaryGraphic:(nullable SDLArtwork *)primaryGraphic {
    _primaryGraphic = primaryGraphic;
    _isDirty = YES;
    if (!self.isBatchingUpdates) {
        [self updateWithCompletionHandler:nil];
    }
}

- (void)setSecondaryGraphic:(nullable SDLArtwork *)secondaryGraphic {
    _secondaryGraphic = secondaryGraphic;
    _isDirty = YES;
    if (!self.isBatchingUpdates) {
        [self updateWithCompletionHandler:nil];
    }
}

- (void)setAlignment:(nullable SDLTextAlignment)alignment {
    _alignment = alignment ? alignment : SDLTextAlignmentCenter;
    _isDirty = YES;
    if (!self.isBatchingUpdates) {
        [self updateWithCompletionHandler:nil];
    }
}

- (void)setTextField1Type:(nullable SDLMetadataType)textField1Type {
    _textField1Type = textField1Type;
    _isDirty = YES;
    if (!self.isBatchingUpdates) {
        [self updateWithCompletionHandler:nil];
    }
}

- (void)setTextField2Type:(nullable SDLMetadataType)textField2Type {
    _textField2Type = textField2Type;
    _isDirty = YES;
    if (!self.isBatchingUpdates) {
        [self updateWithCompletionHandler:nil];
    }
}

- (void)setTextField3Type:(nullable SDLMetadataType)textField3Type {
    _textField3Type = textField3Type;
    _isDirty = YES;
    if (!self.isBatchingUpdates) {
        [self updateWithCompletionHandler:nil];
    }
}

- (void)setTextField4Type:(nullable SDLMetadataType)textField4Type {
    _textField4Type = textField4Type;
    _isDirty = YES;
    if (!self.isBatchingUpdates) {
        [self updateWithCompletionHandler:nil];
    }
}

- (BOOL)hasQueuedUpdate {
    return (_hasQueuedUpdate || _queuedUpdateHandler != nil);
}

- (nullable SDLArtwork *)blankArtwork {
    if (_blankArtwork != nil) {
        return _blankArtwork;
    }

    UIGraphicsBeginImageContextWithOptions(CGSizeMake(5, 5), NO, 0.0);
    UIImage *blankImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    _blankArtwork = [SDLArtwork artworkWithImage:blankImage name:@"sdl_BlankArt" asImageFormat:SDLArtworkImageFormatPNG];

    return _blankArtwork;
}

#pragma mark - RPC Responses

- (void)sdl_registerResponse:(SDLRPCResponseNotification *)notification {
    SDLRegisterAppInterfaceResponse *response = (SDLRegisterAppInterfaceResponse *)notification.response;

    if (!response.success.boolValue) { return; }
    if (response.displayCapabilities == nil) {
        SDLLogE(@"RegisterAppInterface succeeded but didn't send a display capabilities. A lot of things will probably break.");
        return;
    }

    self.displayCapabilities = response.displayCapabilities;
}

- (void)sdl_displayLayoutResponse:(SDLRPCResponseNotification *)notification {
    SDLSetDisplayLayoutResponse *response = (SDLSetDisplayLayoutResponse *)notification.response;

    if (!response.success.boolValue) { return; }
    if (!response.success.boolValue) { return; }
    if (response.displayCapabilities == nil) {
        SDLLogE(@"SetDisplayLayout succeeded but didn't send a display capabilities. A lot of things will probably break.");
        return;
    }

    self.displayCapabilities = response.displayCapabilities;

    // Auto-send an updated show
    if ([self sdl_hasData]) {
        [self sdl_updateWithCompletionHandler:nil];
    }
}

- (void)sdl_hmiStatusNotification:(SDLRPCNotificationNotification *)notification {
    SDLOnHMIStatus *hmiStatus = (SDLOnHMIStatus *)notification.notification;

    SDLHMILevel oldLevel = self.currentLevel;
    self.currentLevel = hmiStatus.hmiLevel;

    // Auto-send an updated show if we were in NONE and now we are not
    if ([oldLevel isEqualToString:SDLHMILevelNone] && ![self.currentLevel isEqualToString:SDLHMILevelNone] && self.waitingOnHMILevelUpdateToUpdate) {
        [self sdl_updateWithCompletionHandler:nil];
    }
}

@end

NS_ASSUME_NONNULL_END
