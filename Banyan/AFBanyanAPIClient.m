//
//  AFBanyanAPIClient.m
//  Banyan
//
//  Created by Devang Mundhra on 10/14/12.
//
//

#import "AFBanyanAPIClient.h"
#import "AFJSONRequestOperation.h"
#import "BanyanAppDelegate.h"

static NSString * const kAFBanyanAPIBaseURLString = @"http://www.banyan.io/api/v1/";
//static NSString * const kAFBanyanAPIBaseURLString = @"http://127.0.0.1:8000/api/v1/";

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
    
    // Accept HTTP Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.1
    [self setDefaultHeader:@"Accept" value:@"application/json"];
    
    if ([BanyanAppDelegate loggedIn]) {
        // Set the header authorizations so that the api knows who the user is
        NSDictionary *userInfo = [[NSUserDefaults standardUserDefaults] dictionaryForKey:BNUserDefaultsUserInfo];
        NSString *email = [userInfo objectForKey:@"email"];
        NSString *apikey = [userInfo objectForKey:@"api_key"];
        [self setAuthorizationHeaderWithTastyPieUsername:email andToken:apikey];    }
    [self setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus isNetworkReachable) {
        if (isNetworkReachable == AFNetworkReachabilityStatusReachableViaWiFi || isNetworkReachable == AFNetworkReachabilityStatusReachableViaWWAN) {
            [APP_DELEGATE fireRemoteObjectTimer];
        } else {
            [APP_DELEGATE invalidateRemoteObjectTimer];
        }
    }];
    
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
