//
//  HttpConnection.m
//  MobileWeather
//
//  Copyright (c) 2013-2015 Ford Motor Company. All rights reserved.
//

#import "HttpConnection.h"

/**
 * Lists all results codes from a HTTP request that describes a successful operation.
 */
static NSInteger HttpConnectionSuccessCodes[] = { 200, 201, 202, 203, 204, 205, 206, 207, 208, 226 };

@interface HttpConnection()

- (BOOL)isResponseCodeSuccess:(NSInteger)responseCode;

@end

@implementation HttpConnection

- (NSData *)sendRequestForURL:(NSURL *)url withMethod:(HttpConnectionRequestMethod)requestMethod withData:(NSData *)contentData ofType:(NSString *)contentType {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    NSHTTPURLResponse *response;
    NSError *error;
    NSData *result;
    
    request.URL = url;
    request.timeoutInterval = 30.0;
    
    if ((requestMethod == HttpConnectionRequestMethodPUT || requestMethod == HttpConnectionRequestMethodPOST) && (contentData != nil)) {

        if (contentType != nil) {
            [request setValue:contentType forHTTPHeaderField:@"Content-Type"];
        }
        else {
            [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        }
    
        [request setValue:@"en-US" forHTTPHeaderField:@"Content-Language"];
        [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)contentData.length] forHTTPHeaderField:@"Content-Length"];
        request.HTTPBody = contentData;
    }
    
    result = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    NSInteger responseCode = response.statusCode;
    // If it doesn't equal 'OK' or we performed a DELETE, return the code and message
    if (result == nil && ([self isResponseCodeSuccess:responseCode] == NO || requestMethod == HttpConnectionRequestMethodDELETE)) {
        result = [[NSString stringWithFormat:@"STATUS=%li:%@", (long)responseCode, [NSHTTPURLResponse localizedStringForStatusCode:responseCode]] dataUsingEncoding:NSUTF8StringEncoding];
    }
    
    return result;
}

- (NSString *)getErrorMessageFromStatusString:(NSString *)statusString {
    if (statusString != nil && [statusString hasPrefix:@"STATUS="]) {
        NSUInteger separator = [statusString rangeOfString:@":"].location;
        if (separator != NSNotFound) {
            return [statusString substringFromIndex:separator];
        }
    }
    return nil;
}

- (NSInteger)getStatusCodeFromStatusString:(NSString *)statusString {
    if (statusString != nil && [statusString hasPrefix:@"STATUS="]) {
        NSUInteger separator = [statusString rangeOfString:@":"].location;
        if (separator != NSNotFound) {
            return [statusString substringWithRange:NSMakeRange(7, separator - 7)].integerValue;
        }
    }
    
    return -1;
}

- (BOOL)isResponseCodeSuccess:(NSInteger)responseCode {
    for (int i = 0; i < sizeof(HttpConnectionSuccessCodes); i++) {
        if (responseCode == HttpConnectionSuccessCodes[i]) {
            return YES;
        }
    }
    return NO;
}

@end
