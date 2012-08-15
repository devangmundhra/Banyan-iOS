//
//  ParseAPIEngine.m
//  Storied
//
//  Created by Devang Mundhra on 6/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ParseAPIEngine.h"

static NSString * const kParseAPIBaseURLString = @"1";

@implementation ParseAPIEngine

+ (ParseAPIEngine *)sharedEngine 
{
    static ParseAPIEngine *_sharedEngine = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableDictionary *headerFields = [NSMutableDictionary dictionaryWithCapacity:2];
        [headerFields setValue:PARSE_APP_ID forKey:@"X-Parse-Application-Id"];
        [headerFields setValue:PARSE_REST_API_KEY forKey:@"X-Parse-REST-API-Key"];
        
        _sharedEngine = [[ParseAPIEngine alloc] initWithHostName:@"api.parse.com"
                                                         apiPath:kParseAPIBaseURLString 
                                              customHeaderFields:headerFields];
        /*
        _sharedEngine.reachabilityChangedHandler = ^(NetworkStatus ns) {
            if (ns != NotReachable) {
                [[BNOperationQueue shared] setSuspended:NO];
            } else {
                [[BNOperationQueue shared] setSuspended:YES];
                [[BNOperationQueue shared] archiveOperations];
            }
        };
         */
    });
    
    return _sharedEngine;
}

- (id)initWithHostName:(NSString *)hostName apiPath:(NSString *)apiPath customHeaderFields:(NSDictionary *)headers
{
    self = [super initWithHostName:hostName apiPath:apiPath customHeaderFields:headers];
    if (!self) {
        return nil;
    }
    [self useCache];
    return self;
}

- (void)enqueueOperation:(MKNetworkOperation *)request
{
    [request setFreezable:YES];
    [request setPostDataEncoding:MKNKPostDataEncodingTypeJSON];
    [self enqueueOperation:request forceReload:YES];
}

+(void)showNetworkUnavailableAlert
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No internet connection"
                                                    message:@"Internet connection is not available. Please connect and try again."
                                                   delegate:nil
                                          cancelButtonTitle:NSLocalizedString(@"Dismiss", @"")
                                          otherButtonTitles:nil];
    [alert show];
}
@end
