//
//  AFBanyanAPIClient.h
//  Banyan
//
//  Created by Devang Mundhra on 10/14/12.
//
//

#import "AFHTTPClient.h"
#import "AFHTTPRequestOperation.h"

#define BANYAN_API_CLASS_URL(__class__) [NSString stringWithFormat:@"%@", __class__]
#define BANYAN_API_OBJECT_URL(__class__, __objectId__) [NSString stringWithFormat:@"%@/%@", __class__, __objectId__]
#define BANYAN_API_GET_OBJECT_LINK_URL() @"link/"
#define BANYAN_API_GET_PIECES_FOR_STORY() @"Pieces/?format=json"
#define BANYAN_API_GET_PERMISSIONS(__class__) [NSString stringWithFormat:@"permission/%@", __class__]
#define BANYAN_API_GET_USER_STORIES(__user__) [NSString stringWithFormat:@"permission/user/%@/?format=json", __user__.userId]
#define BANYAN_API_GET_PUBLIC_STORIES() [NSString stringWithFormat:@"permission/user/?format=json"]

#define AF_BANYAN_ERROR_BLOCK() ^(AFHTTPRequestOperation *operation, NSError *error) {             \
NSLog(@"operation: %@, response: %@, error: %@", operation, [operation responseString], error);   \
}

@interface AFBanyanAPIClient : AFHTTPClient

+ (AFBanyanAPIClient *)sharedClient;
- (BOOL) isReachable;
@end
