//
//  AFBanyanAPIClient.h
//  Banyan
//
//  Created by Devang Mundhra on 10/14/12.
//
//

#import "AFHTTPClient.h"
#import "AFHTTPRequestOperation.h"
#import "AFNetworking+ApiKeyAuthentication.h"

@interface AFBanyanAPIClient : AFHTTPClient

+ (AFBanyanAPIClient *)sharedClient;
- (BOOL) isReachable;

@end
