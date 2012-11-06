//
//  AFBanyanAPIClient.h
//  Banyan
//
//  Created by Devang Mundhra on 10/14/12.
//
//

#import "AFHTTPClient.h"
#import "AFHTTPRequestOperation.h"

#define BANYAN_API_GET_OBJECT_LINK_URL() @"link/"
#define BANYAN_API_GET_PERMISSIONS(__class__) [NSString stringWithFormat:@"permission/%@", __class__]

#define AF_BANYAN_ERROR_BLOCK() ^(AFHTTPRequestOperation *operation, NSError *error) {             \
NSLog(@"operation: %@, response: %@, error: %@", operation, [operation responseString], error);   \
}

@interface AFBanyanAPIClient : AFHTTPClient

+ (AFBanyanAPIClient *)sharedClient;
- (BOOL) isReachable;
@end
