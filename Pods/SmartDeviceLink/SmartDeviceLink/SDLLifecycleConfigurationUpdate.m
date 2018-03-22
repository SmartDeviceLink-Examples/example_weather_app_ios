//
//  SDLLifecycleConfigurationUpdate.m
//  SmartDeviceLink-iOS
//
//  Created by Kujtim Shala on 06.09.17.
//  Copyright © 2017 smartdevicelink. All rights reserved.
//

#import "SDLLifecycleConfigurationUpdate.h"

@implementation SDLLifecycleConfigurationUpdate

- (instancetype)init {
    return [self initWithAppName:nil shortAppName:nil ttsName:nil voiceRecognitionCommandNames:nil];
}

- (instancetype)initWithAppName:(NSString *)appName shortAppName:(NSString *)shortAppName ttsName:(NSArray<SDLTTSChunk *> *)ttsName voiceRecognitionCommandNames:(NSArray<NSString *> *)voiceRecognitionCommandNames {
    if (self = [super init]) {
        self.appName = appName;
        self.shortAppName = shortAppName;
        self.ttsName = ttsName;
        self.voiceRecognitionCommandNames = voiceRecognitionCommandNames;
    }
    
    return self;
}

@end
