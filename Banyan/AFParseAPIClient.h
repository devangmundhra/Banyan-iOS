//
//  AFParseAPIClient.h
//  Storied
//
//  Created by Devang Mundhra on 5/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFHTTPClient.h"
#import "BanyanAppDelegate.h"
#import "BNOperationQueue.h"
#import "AFHTTPRequestOperation.h"

#define PARSE_API_CLASS_URL(__class__) [NSString stringWithFormat:@"classes/%@", __class__]
#define PARSE_API_OBJECT_URL(__class__, __objectId__) [NSString stringWithFormat:@"classes/%@/%@", __class__, __objectId__]
#define PARSE_API_USER_URL(__userId__) [NSString stringWithFormat:@"users/%@", __userId__]
#define PARSE_API_FUNCTION_URL(__function__) [NSString stringWithFormat:@"functions/%@", __function__]

#define AF_PARSE_ERROR_BLOCK() ^(AFHTTPRequestOperation *operation, NSError *error) {             \
NSLog(@"operation: %@, response: %@, error: %@", operation, [operation responseString], error);   \
}

@interface AFParseAPIClient : AFHTTPClient

+ (AFParseAPIClient *)sharedClient;
- (BOOL) isReachable;
@end
