//  SDLScrollableMessage.m
//


#import "SDLScrollableMessage.h"

#import "SDLNames.h"
#import "SDLSoftButton.h"

@implementation SDLScrollableMessage

- (instancetype)init {
    if (self = [super initWithName:NAMES_ScrollableMessage]) {
    }
    return self;
}

- (instancetype)initWithDictionary:(NSMutableDictionary *)dict {
    if (self = [super initWithDictionary:dict]) {
    }
    return self;
}

- (void)setScrollableMessageBody:(NSString *)scrollableMessageBody {
    if (scrollableMessageBody != nil) {
        [parameters setObject:scrollableMessageBody forKey:NAMES_scrollableMessageBody];
    } else {
        [parameters removeObjectForKey:NAMES_scrollableMessageBody];
    }
}

- (NSString *)scrollableMessageBody {
    return [parameters objectForKey:NAMES_scrollableMessageBody];
}

- (void)setTimeout:(NSNumber *)timeout {
    if (timeout != nil) {
        [parameters setObject:timeout forKey:NAMES_timeout];
    } else {
        [parameters removeObjectForKey:NAMES_timeout];
    }
}

- (NSNumber *)timeout {
    return [parameters objectForKey:NAMES_timeout];
}

- (void)setSoftButtons:(NSMutableArray *)softButtons {
    if (softButtons != nil) {
        [parameters setObject:softButtons forKey:NAMES_softButtons];
    } else {
        [parameters removeObjectForKey:NAMES_softButtons];
    }
}

- (NSMutableArray *)softButtons {
    NSMutableArray *array = [parameters objectForKey:NAMES_softButtons];
    if ([array count] < 1 || [[array objectAtIndex:0] isKindOfClass:SDLSoftButton.class]) {
        return array;
    } else {
        NSMutableArray *newList = [NSMutableArray arrayWithCapacity:[array count]];
        for (NSDictionary *dict in array) {
            [newList addObject:[[SDLSoftButton alloc] initWithDictionary:(NSMutableDictionary *)dict]];
        }
        return newList;
    }
}

@end
