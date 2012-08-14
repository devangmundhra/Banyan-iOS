//
//  BanyanAPIEngine.h
//  Storied
//
//  Created by Devang Mundhra on 6/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MKNetworkEngine.h"
#import "BanyanAppDelegate.h"
#import "BNOperationQueue.h"

@interface BanyanAPIEngine : MKNetworkEngine

#define BANYAN_API_GET_OBJECT_LINK_URL() @"link/"


#define BANYAN_ERROR_BLOCK() ^(NSError *error) {\
NSLog(@"%@\t%@\t%@\t%@", [error localizedDescription], [error localizedFailureReason], \
[error localizedRecoveryOptions], [error localizedRecoverySuggestion]); \
}

+ (BanyanAPIEngine *)sharedEngine;
- (void)enqueueOperation:(MKNetworkOperation *)request;
+ (void)showNetworkUnavailableAlert;

@end
