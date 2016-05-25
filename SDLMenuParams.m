//  SDLMenuParams.m
//


#import "SDLMenuParams.h"

#import "SDLNames.h"

@implementation SDLMenuParams

- (instancetype)init {
    if (self = [super init]) {
    }
    return self;
}

- (instancetype)initWithDictionary:(NSMutableDictionary *)dict {
    if (self = [super initWithDictionary:dict]) {
    }
    return self;
}

- (void)setParentID:(NSNumber *)parentID {
    if (parentID != nil) {
        [store setObject:parentID forKey:NAMES_parentID];
    } else {
        [store removeObjectForKey:NAMES_parentID];
    }
}

- (NSNumber *)parentID {
    return [store objectForKey:NAMES_parentID];
}

- (void)setPosition:(NSNumber *)position {
    if (position != nil) {
        [store setObject:position forKey:NAMES_position];
    } else {
        [store removeObjectForKey:NAMES_position];
    }
}

- (NSNumber *)position {
    return [store objectForKey:NAMES_position];
}

- (void)setMenuName:(NSString *)menuName {
    if (menuName != nil) {
        [store setObject:menuName forKey:NAMES_menuName];
    } else {
        [store removeObjectForKey:NAMES_menuName];
    }
}

- (NSString *)menuName {
    return [store objectForKey:NAMES_menuName];
}

@end
