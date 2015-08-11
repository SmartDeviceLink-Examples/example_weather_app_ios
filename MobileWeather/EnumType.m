//
//  EnumType.h
//  MobileWeather
//
//  Copyright (c) 2013-2015 Ford Motor Company. All rights reserved.
//

#import <objc/runtime.h>
#import <objc/message.h>

#import "EnumType.h"

@implementation EnumType

+ (NSArray *)elements {
    // copy a list of available methods of the class
    unsigned int count = 0;
    Method *methods = class_copyMethodList(object_getClass(self), &count);
    // create a mutable array to hold the instances of the enumeration
    NSMutableArray *elements = [NSMutableArray arrayWithCapacity:count];
    
    // go through the list of methods
    for (unsigned int i = 0; i < count; i++) {
        // get a selector of the method
        SEL selector = method_getName(methods[i]);
        // get the name of the method / selector
        NSString *name = NSStringFromSelector(selector);
        
        // check if the name matches the format of an element e.g. _123 or ABC_DEF or ELEMENT
        NSRange range = [name rangeOfString:@"^[A-Z_][A-Z0-9_]+$" options:NSRegularExpressionSearch];

        // does the name match the regular expression?
        if (range.location != NSNotFound) {
            // does the class respond to this selector?
            if ([self respondsToSelector:selector]) {
                // get the method implementation based on the selector
                IMP method = [self methodForSelector:selector];
                // cast it to the c function that will be called
                id (*func)(id, SEL) = (void *)method;
                // call the c function and perform the selector
                id element = func(self, selector);
            
                // the element is fetched. add it to the list
                [elements addObject:element];
            }
        }
    }
    
    // if we have received a copy of the method list then free the memory now
    if (methods) {
        free(methods);
    }
    
    // return an imutable array
    return [NSArray arrayWithArray:elements];
}

+ (instancetype)elementWithValue:(NSString *)value {
    // check if the name matches the format of an element eg. _123 or ABC_DEF or ELEMENT
    NSRange range = [value rangeOfString:@"^[A-Z_][A-Z0-9_]+$" options:NSRegularExpressionSearch];
    
    // does the name match the regular expression?
    if (range.location != NSNotFound) {
        // get a selector by name
        SEL selector = NSSelectorFromString(value);
        
        // does the class respond to the selector?
        if ([self respondsToSelector:selector]) {
            // get the method implementation based on the selector
            IMP method = [self methodForSelector:selector];
            // cast it to the c function that will be called
            id (*func)(id, SEL) = (void *)method;
            // return the element
            return func(self, selector);
        }
    }
    
    return nil;
}

- (instancetype)initWithValue:(NSString *)value {
    if (self = [super init]) {
        self->_value = value;
    }
    return self;
}


- (NSString *)description {
    return [NSString stringWithFormat:@"%@::%@", NSStringFromClass([self class]), [self value]];
}

@end
