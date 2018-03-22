//
//  SDLRPCStruct.m


#import "SDLRPCStruct.h"

#import "SDLEnum.h"
#import "SDLNames.h"

NS_ASSUME_NONNULL_BEGIN

@implementation SDLRPCStruct

- (id)initWithDictionary:(NSDictionary<NSString *, id> *)dict {
    if (self = [super init]) {
        if (dict != nil) {
            store = [dict mutableCopy];
        } else {
            store = [NSMutableDictionary dictionary];
        }
    }
    return self;
}

- (id)init {
    if (self = [super init]) {
        store = [NSMutableDictionary dictionary];
    }
    return self;
}

- (NSDictionary<NSString *, id> *)serializeAsDictionary:(Byte)version {
    if (version >= 2) {
        NSString *messageType = [[store keyEnumerator] nextObject];
        NSMutableDictionary<NSString *, id> *function = [store objectForKey:messageType];
        if ([function isKindOfClass:NSMutableDictionary.class]) {
            NSMutableDictionary<NSString *, id> *parameters = [function objectForKey:SDLNameParameters];
            return [self.class sdl_serializeDictionary:parameters version:version];
        } else {
            return [self.class sdl_serializeDictionary:store version:version];
        }
    } else {
        return [self.class sdl_serializeDictionary:store version:version];
    }
}

- (NSString *)description {
    return [store description];
}

+ (NSDictionary<NSString *, id> *)sdl_serializeDictionary:(NSDictionary *)dict version:(Byte)version {
    NSMutableDictionary<NSString *, id> *ret = [NSMutableDictionary dictionaryWithCapacity:dict.count];
    for (NSString *key in [dict keyEnumerator]) {
        NSObject *value = [dict objectForKey:key];
        if ([value isKindOfClass:SDLRPCStruct.class]) {
            [ret setObject:[(SDLRPCStruct *)value serializeAsDictionary:version] forKey:key];
        } else if ([value isKindOfClass:NSDictionary.class]) {
            [ret setObject:[self sdl_serializeDictionary:(NSDictionary *)value version:version] forKey:key];
        } else if ([value isKindOfClass:NSArray.class]) {
            NSArray<NSObject *> *arrayVal = (NSArray<NSObject *> *)value;
            
            if (arrayVal.count > 0 && ([[arrayVal objectAtIndex:0] isKindOfClass:SDLRPCStruct.class])) {
                NSMutableArray<NSDictionary<NSString *, id> *> *serializedList = [NSMutableArray arrayWithCapacity:arrayVal.count];
                for (SDLRPCStruct *serializeable in arrayVal) {
                    [serializedList addObject:[serializeable serializeAsDictionary:version]];
                }
                [ret setObject:serializedList forKey:key];
            } else {
                [ret setObject:value forKey:key];
            }
        } else {
            [ret setObject:value forKey:key];
        }
    }
    return ret;
}

-(id)copyWithZone:(nullable NSZone *)zone {
    SDLRPCStruct *newStruct = [[[self class] allocWithZone:zone] init];
    newStruct->store = [self->store copy];

    return newStruct;
}

- (BOOL)isEqualToRPC:(SDLRPCStruct *)rpc {
    return [rpc->store isEqualToDictionary:self->store];
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }

    if (![object isMemberOfClass:self.class]) {
        return NO;
    }

    return [self isEqualToRPC:(SDLRPCStruct *)object];
}

@end

NS_ASSUME_NONNULL_END
