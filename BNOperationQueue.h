//
//  BNOperationQueue.h
//  Banyan
//
//  Created by Devang Mundhra on 7/17/12.
//  Copyright (c) 2012 Devang Mundhra. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BNOperation.h"

@class BNOperation, BNOperationObject;

#define NETWORK_OPERATION_COMPLETE() [[BNOperationQueue shared] doneWithOperationWithError:NO]
#define NETWORK_OPERATION_INCOMPLETE() [[BNOperationQueue shared] doneWithOperationWithError:YES]
#define ADD_OPERATION_TO_QUEUE(__operation__) [[BNOperationQueue shared] addOperation:__operation__]

#define BN_ERROR_BLOCK_OPERATION_COMPLETE() ^(AFHTTPRequestOperation *operation, NSError *error) {  \
NSLog(@"%@\t%@\t%@\t%@", [error localizedDescription], [error localizedFailureReason],              \
[error localizedRecoveryOptions], [error localizedRecoverySuggestion]);                             \
NETWORK_OPERATION_COMPLETE();                                                                       \
}

#define BN_ERROR_BLOCK_OPERATION_INCOMPLETE() ^(AFHTTPRequestOperation *operation, NSError *error) { \
NSLog(@"%@\t%@\t%@\t%@", [error localizedDescription], [error localizedFailureReason],               \
[error localizedRecoveryOptions], [error localizedRecoverySuggestion]);                              \
NETWORK_OPERATION_INCOMPLETE();                                                                      \
}

@interface BNOperationQueue : NSOperationQueue

@property (weak, atomic) BNOperation *ongoingOperation;

+(BNOperationQueue *)shared;
- (void) updateQueuewithOldDependency:(BNOperationObject *)oldObject
                    withNewDependency:(BNOperationObject *)newDep;
- (void) addOperation:(BNOperation *)operation;
- (void) doneWithOperationWithError:(BOOL)error;
- (void) archiveOperations;
@end
