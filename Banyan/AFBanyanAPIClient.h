//
//  AFBanyanAPIClient.h
//  Banyan
//
//  Created by Devang Mundhra on 10/14/12.
//
//

#import "AFHTTPClient.h"
#import "AFHTTPRequestOperation.h"

#define BANYAN_API_CLASS_URL(__class__) [NSString stringWithFormat:@"%@/", [__class__ lowercaseString]]
#define BANYAN_API_OBJECT_URL(__class__, __objectId__) [NSString stringWithFormat:@"%@/%@/?format=json", [__class__ lowercaseString], __objectId__]
#define BANYAN_API_GET_OBJECT_LINK_URL() @"link/"
#define BANYAN_API_GET_STORIES() [NSString stringWithFormat:@"story/?format=json"]

#define AF_BANYAN_ERROR_BLOCK() ^(AFHTTPRequestOperation *operation, NSError *error) {             \
NSLog(@"operation: %@, response: %@, error: %@", operation, [operation responseString], error);   \
}

@interface AFBanyanAPIClient : AFHTTPClient

+ (AFBanyanAPIClient *)sharedClient;
- (BOOL) isReachable;
- (void)setAuthorizationHeaderWithUsername:(NSString *)username apikey:(NSString *)apikey;

@end
