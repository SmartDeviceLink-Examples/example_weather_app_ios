#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "bson_array.h"
#import "bson_object.h"
#import "bson_util.h"
#import "emhashmap/emhashmap.h"

FOUNDATION_EXPORT double BiSONVersionNumber;
FOUNDATION_EXPORT const unsigned char BiSONVersionString[];

