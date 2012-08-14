//
//  BanyanAPIEngine.m
//  Storied
//
//  Created by Devang Mundhra on 6/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BanyanAPIEngine.h"

static NSString * const kParseAPIBaseURLString = @"api/v1";

@implementation BanyanAPIEngine

+ (BanyanAPIEngine *)sharedEngine 
{
    static BanyanAPIEngine *_sharedEngine = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
//        NSMutableDictionary *headerFields = [NSMutableDictionary dictionaryWithCapacity:2];
//        [headerFields setValue:@"Q82knolRSmsGKKNK13WCvISIReVVoR3yFP3qTF1J" forKey:@"X-Parse-Application-Id"];
//        [headerFields setValue:@"iHiN4Hlw835d7aig6vtcTNhPOkNyJpjpvAL2aSoL" forKey:@"X-Parse-REST-API-Key"];
        
        _sharedEngine = [[BanyanAPIEngine alloc] initWithHostName:@"banyan.io"
                                                         apiPath:kParseAPIBaseURLString 
                                              customHeaderFields:nil];
        _sharedEngine.reachabilityChangedHandler = ^(NetworkStatus ns) {
            if (ns != NotReachable) {
                [[BNOperationQueue shared] setSuspended:NO];
            } else {
                [[BNOperationQueue shared] setSuspended:YES];
                [[BNOperationQueue shared] archiveOperations];
            }
        };
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
    [request setFreezable:NO];
    [request setPostDataEncoding:MKNKPostDataEncodingTypeJSON];
    [self enqueueOperation:request forceReload:YES];
}

+(void)showNetworkUnavailableAlert
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Unable to reach Banyan servers"
                                                    message:@"Internet connection is not available. Please connect and try again."
                                                   delegate:nil
                                          cancelButtonTitle:NSLocalizedString(@"Dismiss", @"")
                                          otherButtonTitles:nil];
    [alert show];
}

@end
