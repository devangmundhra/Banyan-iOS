//
//  AFBanyanAPIClient.m
//  Banyan
//
//  Created by Devang Mundhra on 10/14/12.
//
//

#import "AFBanyanAPIClient.h"
#import "AFJSONRequestOperation.h"
#import "BNOperationQueue.h"

static NSString * const kAFBanyanAPIBaseURLString = @"http://www.banyan.io/api/v1/";

@implementation AFBanyanAPIClient

+ (AFBanyanAPIClient *)sharedClient {
    static AFBanyanAPIClient *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[AFBanyanAPIClient alloc] initWithBaseURL:[NSURL URLWithString:kAFBanyanAPIBaseURLString]];
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
    [self setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus isNetworkReachable) {
        if (isNetworkReachable == AFNetworkReachabilityStatusReachableViaWiFi || isNetworkReachable == AFNetworkReachabilityStatusReachableViaWWAN) {
            [[BNOperationQueue shared] setSuspended:NO];
            [[MTStatusBarOverlay sharedInstance] show];
        } else {
            [[BNOperationQueue shared] setSuspended:YES];
            [[BNOperationQueue shared] archiveOperations];
            [[MTStatusBarOverlay sharedInstance] hide];
            NSLog(@"Network to parse.com not reachable!!");
        }
    }];
    
    // Accept HTTP Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.1
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
