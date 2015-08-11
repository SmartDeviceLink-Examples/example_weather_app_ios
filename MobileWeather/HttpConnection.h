//
//  HttpConnection.h
//  MobileWeather
//
//  Copyright (c) 2013-2015 Ford Motor Company. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    HttpConnectionRequestMethodGET,
    HttpConnectionRequestMethodPUT,
    HttpConnectionRequestMethodPOST,
    HttpConnectionRequestMethodDELETE,
} HttpConnectionRequestMethod;

@interface HttpConnection : NSObject

/**
 * Returns the result of a HTTP request.
 *
 * @param url The request URL.
 * @param method The type of HTTP request to perform.
 * @param data The data to send to the server.
 * @param contentType The content type describing the data.
 * @return The result of the request.
 */
- (NSData *)sendRequestForURL:(NSURL *)url withMethod:(HttpConnectionRequestMethod)requestMethod withData:(NSData *)contentData ofType:(NSString *)contentType;

/**
 * Checks for a HTTP error message from the requesting method.
 *
 * @param statusString The results of the request.
 * @return The HTTP error message, if any occurred.
 */
- (NSString *)getErrorMessageFromStatusString:(NSString *)statusString;

/**
 * Converts an HTTP error message from the requesting method into the HTTP status code.
 *
 * @param statusString The results from the request.
 * @return The HTTP status code.
 */
- (NSInteger)getStatusCodeFromStatusString:(NSString *)statusString;

@end
