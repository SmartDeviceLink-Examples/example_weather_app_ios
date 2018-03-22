//
//  EnumType.h
//  MobileWeather
//
//  Copyright (c) 2013-2015 Ford Motor Company. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Abstract type used for object oriented enumeration types.
 * Enumerations use this class as their base class to handle their elements.
 * Note: It is not validated that an element can be unique.
 */
@interface EnumType : NSObject

/** Returns an array that contains all elements of the type. */
+ (NSArray *)elements;

/** Returns the element that represents the specified value. */
+ (instancetype)elementWithValue:(NSString *)value;

/** Initializes a new element with the given value. */
- (instancetype)initWithValue:(NSString *)value NS_DESIGNATED_INITIALIZER;

/** Returns the value of the current element. */
@property (strong, readonly) NSString *value;

@end
