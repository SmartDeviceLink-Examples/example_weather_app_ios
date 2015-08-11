//
//  AlertType.h
//  MobileWeather
//
//  Copyright (c) 2013-2015 Ford Motor Company. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "EnumType.h"

@interface AlertType : EnumType

+ (instancetype)HUR;

+ (instancetype)TOR;

+ (instancetype)TOW;

+ (instancetype)WRN;

+ (instancetype)SEW;

+ (instancetype)WIN;

+ (instancetype)FLO;

+ (instancetype)WAT;

+ (instancetype)WND;

+ (instancetype)SVR;

+ (instancetype)HEA;

+ (instancetype)FOG;

+ (instancetype)SPE;

+ (instancetype)FIR;

+ (instancetype)VOL;

+ (instancetype)HWW;

+ (instancetype)REC;

+ (instancetype)REP;

+ (instancetype)PUB;

@end
