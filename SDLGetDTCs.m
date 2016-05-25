//  SDLGetDTCs.m
//


#import "SDLGetDTCs.h"

#import "SDLNames.h"

@implementation SDLGetDTCs

- (instancetype)init {
    if (self = [super initWithName:NAMES_GetDTCs]) {
    }
    return self;
}

- (instancetype)initWithDictionary:(NSMutableDictionary *)dict {
    if (self = [super initWithDictionary:dict]) {
    }
    return self;
}

- (void)setEcuName:(NSNumber *)ecuName {
    if (ecuName != nil) {
        [parameters setObject:ecuName forKey:NAMES_ecuName];
    } else {
        [parameters removeObjectForKey:NAMES_ecuName];
    }
}

- (NSNumber *)ecuName {
    return [parameters objectForKey:NAMES_ecuName];
}

- (void)setDtcMask:(NSNumber *)dtcMask {
    if (dtcMask != nil) {
        [parameters setObject:dtcMask forKey:NAMES_dtcMask];
    } else {
        [parameters removeObjectForKey:NAMES_dtcMask];
    }
}

- (NSNumber *)dtcMask {
    return [parameters objectForKey:NAMES_dtcMask];
}

@end
