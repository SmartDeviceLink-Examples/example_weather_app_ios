//
//  SDLScreenManager.m
//  SmartDeviceLink
//
//  Created by Joel Fischer on 3/5/18.
//  Copyright © 2018 smartdevicelink. All rights reserved.
//

#import "SDLScreenManager.h"

#import "SDLArtwork.h"
#import "SDLChoiceSetManager.h"
#import "SDLMenuManager.h"
#import "SDLSoftButtonManager.h"
#import "SDLTextAndGraphicManager.h"
#import "SDLVoiceCommandManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface SDLScreenManager()

@property (strong, nonatomic) SDLTextAndGraphicManager *textAndGraphicManager;
@property (strong, nonatomic) SDLSoftButtonManager *softButtonManager;
@property (strong, nonatomic) SDLMenuManager *menuManager;
@property (strong, nonatomic) SDLVoiceCommandManager *voiceCommandMenuManager;
@property (strong, nonatomic) SDLChoiceSetManager *choiceSetManager;

@property (weak, nonatomic) id<SDLConnectionManagerType> connectionManager;
@property (weak, nonatomic) SDLFileManager *fileManager;

@end

@implementation SDLScreenManager

- (instancetype)initWithConnectionManager:(id<SDLConnectionManagerType>)connectionManager fileManager:(SDLFileManager *)fileManager {
    self = [super init];
    if (!self) { return nil; }

    _connectionManager = connectionManager;
    _fileManager = fileManager;

    _textAndGraphicManager = [[SDLTextAndGraphicManager alloc] initWithConnectionManager:connectionManager fileManager:fileManager];
    _softButtonManager = [[SDLSoftButtonManager alloc] initWithConnectionManager:connectionManager fileManager:fileManager];
    _menuManager = [[SDLMenuManager alloc] initWithConnectionManager:connectionManager fileManager:fileManager];
    _voiceCommandMenuManager = [[SDLVoiceCommandManager alloc] initWithConnectionManager:connectionManager];
    _choiceSetManager = [[SDLChoiceSetManager alloc] initWithConnectionManager:connectionManager fileManager:fileManager];

    return self;
}

- (void)startWithCompletionHandler:(void (^)(NSError * _Nullable))handler {
    [self.choiceSetManager start];

    handler(nil);
}

- (void)stop {
    [self.textAndGraphicManager stop];
    [self.softButtonManager stop];
    [self.menuManager stop];
    [self.voiceCommandMenuManager stop];
    [self.choiceSetManager stop];
}

- (nullable SDLSoftButtonObject *)softButtonObjectNamed:(NSString *)name {
    return [self.softButtonManager softButtonObjectNamed:name];
}

#pragma mark - Setters

- (void)setTextField1:(nullable NSString *)textField1 {
    self.textAndGraphicManager.textField1 = textField1;
    self.softButtonManager.currentMainField1 = textField1;
}

- (void)setTextField2:(nullable NSString *)textField2 {
    self.textAndGraphicManager.textField2 = textField2;
}

- (void)setTextField3:(nullable NSString *)textField3 {
    self.textAndGraphicManager.textField3 = textField3;
}

- (void)setTextField4:(nullable NSString *)textField4 {
    self.textAndGraphicManager.textField4 = textField4;
}

- (void)setMediaTrackTextField:(nullable NSString *)mediaTrackTextField {
    self.textAndGraphicManager.mediaTrackTextField = mediaTrackTextField;
}

- (void)setPrimaryGraphic:(nullable SDLArtwork *)primaryGraphic {
    if (primaryGraphic == nil) {
        self.textAndGraphicManager.primaryGraphic = self.textAndGraphicManager.blankArtwork;
        return;
    }

    self.textAndGraphicManager.primaryGraphic = primaryGraphic;
}

- (void)setSecondaryGraphic:(nullable SDLArtwork *)secondaryGraphic {
    if (secondaryGraphic == nil) {
        self.textAndGraphicManager.secondaryGraphic = self.textAndGraphicManager.blankArtwork;
        return;
    }

    self.textAndGraphicManager.secondaryGraphic = secondaryGraphic;
}

- (void)setTextAlignment:(SDLTextAlignment)textAlignment {
    self.textAndGraphicManager.alignment = textAlignment;
}

- (void)setTextField1Type:(nullable SDLMetadataType)textField1Type {
    self.textAndGraphicManager.textField1Type = textField1Type;
}

- (void)setTextField2Type:(nullable SDLMetadataType)textField2Type {
    self.textAndGraphicManager.textField2Type = textField2Type;
}

- (void)setTextField3Type:(nullable SDLMetadataType)textField3Type {
    self.textAndGraphicManager.textField3Type = textField3Type;
}

- (void)setTextField4Type:(nullable SDLMetadataType)textField4Type {
    self.textAndGraphicManager.textField4Type = textField4Type;
}

- (void)setSoftButtonObjects:(NSArray<SDLSoftButtonObject *> *)softButtonObjects {
    self.softButtonManager.softButtonObjects = softButtonObjects;
}

- (void)setMenu:(NSArray<SDLMenuCell *> *)menu {
    self.menuManager.menuCells = menu;
}

- (void)setVoiceCommands:(NSArray<SDLVoiceCommand *> *)voiceCommands {
    self.voiceCommandMenuManager.voiceCommands = voiceCommands;
}

- (void)setKeyboardConfiguration:(nullable SDLKeyboardProperties *)keyboardConfiguration {
    self.choiceSetManager.keyboardConfiguration = keyboardConfiguration;
}

#pragma mark - Getters

- (nullable NSString *)textField1 {
    return _textAndGraphicManager.textField1;
}

- (nullable NSString *)textField2 {
    return _textAndGraphicManager.textField2;
}

- (nullable NSString *)textField3 {
    return _textAndGraphicManager.textField3;
}

- (nullable NSString *)textField4 {
    return _textAndGraphicManager.textField4;
}

- (nullable NSString *)mediaTrackTextField {
    return _textAndGraphicManager.mediaTrackTextField;
}

- (nullable SDLArtwork *)primaryGraphic {
    if ([_textAndGraphicManager.primaryGraphic.name isEqualToString:_textAndGraphicManager.blankArtwork.name]) {
        return nil;
    }

    return _textAndGraphicManager.primaryGraphic;
}

- (nullable SDLArtwork *)secondaryGraphic {
    if ([_textAndGraphicManager.secondaryGraphic.name isEqualToString:_textAndGraphicManager.blankArtwork.name]) {
        return nil;
    }

    return _textAndGraphicManager.secondaryGraphic;
}

- (SDLTextAlignment)alignment {
    return _textAndGraphicManager.alignment;
}

- (nullable SDLMetadataType)textField1Type {
    return _textAndGraphicManager.textField1Type;
}

- (nullable SDLMetadataType)textField2Type {
    return _textAndGraphicManager.textField2Type;
}

- (nullable SDLMetadataType)textField3Type {
    return _textAndGraphicManager.textField3Type;
}

- (nullable SDLMetadataType)textField4Type {
    return _textAndGraphicManager.textField4Type;
}

- (NSArray<SDLSoftButtonObject *> *)softButtonObjects {
    return _softButtonManager.softButtonObjects;
}

- (NSArray<SDLMenuCell *> *)menu {
    return _menuManager.menuCells;
}

- (NSArray<SDLVoiceCommand *> *)voiceCommands {
    return _voiceCommandMenuManager.voiceCommands;
}

- (NSSet<SDLChoiceCell *> *)preloadedChoices {
    return _choiceSetManager.preloadedChoices;
}

- (SDLKeyboardProperties *)keyboardConfiguration {
    return _choiceSetManager.keyboardConfiguration;
}

#pragma mark - Begin / End Updates

- (void)beginUpdates {
    self.softButtonManager.batchUpdates = YES;
    self.textAndGraphicManager.batchUpdates = YES;
}

- (void)endUpdates {
    [self endUpdatesWithCompletionHandler:nil];
}

- (void)endUpdatesWithCompletionHandler:(nullable SDLScreenManagerUpdateCompletionHandler)handler {
    self.softButtonManager.batchUpdates = NO;
    self.textAndGraphicManager.batchUpdates = NO;

    [self.textAndGraphicManager updateWithCompletionHandler:handler];
    [self.softButtonManager updateWithCompletionHandler:handler];
}

#pragma mark - Choice Sets

- (void)deleteChoices:(NSArray<SDLChoiceCell *> *)choices {
    [self.choiceSetManager deleteChoices:choices];
}

- (void)preloadChoices:(NSArray<SDLChoiceCell *> *)choices withCompletionHandler:(nullable SDLPreloadChoiceCompletionHandler)handler {
    [self.choiceSetManager preloadChoices:choices withCompletionHandler:handler];
}

- (void)presentChoiceSet:(SDLChoiceSet *)choiceSet mode:(SDLInteractionMode)mode {
    [self.choiceSetManager presentChoiceSet:choiceSet mode:mode withKeyboardDelegate:nil];
}

- (void)presentSearchableChoiceSet:(SDLChoiceSet *)choiceSet mode:(SDLInteractionMode)mode withKeyboardDelegate:(id<SDLKeyboardDelegate>)delegate {
    [self.choiceSetManager presentChoiceSet:choiceSet mode:mode withKeyboardDelegate:delegate];
}

- (void)presentKeyboardWithInitialText:(NSString *)initialText delegate:(id<SDLKeyboardDelegate>)delegate {
    [self.choiceSetManager presentKeyboardWithInitialText:initialText delegate:delegate];
}

@end

NS_ASSUME_NONNULL_END
