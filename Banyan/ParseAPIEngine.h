//
//  ParseAPIEngine.h
//  Storied
//
//  Created by Devang Mundhra on 6/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MKNetworkEngine.h"
#import "BanyanAppDelegate.h"
#import "BNOperationQueue.h"

@interface ParseAPIEngine : MKNetworkEngine

#define PARSE_API_CLASS_URL(__class__) [NSString stringWithFormat:@"classes/%@", __class__]
#define PARSE_API_OBJECT_URL(__class__, __objectId__) [NSString stringWithFormat:@"classes/%@/%@", __class__, __objectId__]
#define PARSE_API_USER_URL(__userId__) [NSString stringWithFormat:@"users/%@", __userId__]

#define PARSE_ERROR_BLOCK() ^(NSError *error) {\
                                NSLog(@"%@\t%@\t%@\t%@", [error localizedDescription], [error localizedFailureReason], \
                                               [error localizedRecoveryOptions], [error localizedRecoverySuggestion]); \
                                                DONE_WITH_NETWORK_OPERATION();                                           \
                                            }

+ (ParseAPIEngine *)sharedEngine;
- (void)enqueueOperation:(MKNetworkOperation *)request;
+ (void)showNetworkUnavailableAlert;

@end
