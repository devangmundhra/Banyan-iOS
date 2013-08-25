//
//  AFParseAPIClient.m
//  Storied
//
//  Created by Devang Mundhra on 5/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AFParseAPIClient.h"
#import "AFJSONRequestOperation.h"

static NSString * const kAFParseAPIBaseURLString = @"https://api.parse.com/1/";

@implementation AFParseAPIClient

+ (AFParseAPIClient *)sharedClient {
static AFParseAPIClient *_sharedClient = nil;
static dispatch_once_t onceToken;
dispatch_once(&onceToken, ^{
    _sharedClient = [[AFParseAPIClient alloc] initWithBaseURL:[NSURL URLWithString:kAFParseAPIBaseURLString]];
});

return _sharedClient;
}

- (id)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    if (!self) {
        return nil;
    }
    
    [self registerHTTPOperationClass:[AFJSONRequestOperation class]];
    [self setParameterEncoding:AFJSONParameterEncoding];
    
    // Accept HTTP Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.1
    [self setDefaultHeader:@"Accept" value:@"application/json"];
//    [self setDefaultHeader:@"X-Parse-Application-Id" value:PARSE_APP_ID];
//	[self setDefaultHeader:@"X-Parse-REST-API-Key" value:PARSE_REST_API_KEY];
    return self;
}

- (BOOL)isReachable
{
    if (self.networkReachabilityStatus == AFNetworkReachabilityStatusReachableViaWiFi
        || self.networkReachabilityStatus == AFNetworkReachabilityStatusReachableViaWWAN) {
        return YES;
    } else {
        return NO;
    }
}

@end
