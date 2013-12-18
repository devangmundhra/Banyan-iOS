//
//  AFBanyanAPIClient.h
//  Banyan
//
//  Created by Devang Mundhra on 10/14/12.
//
//

#import "AFHTTPClient.h"
#import "AFHTTPRequestOperation.h"

@interface AFBanyanAPIClient : AFHTTPClient

+ (AFBanyanAPIClient *)sharedClient;
- (BOOL) isReachable;
- (void)setAuthorizationHeaderWithUsername:(NSString *)username apikey:(NSString *)apikey;

@end
