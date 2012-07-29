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

#define DONE_WITH_NETWORK_OPERATION() [BNOperationQueue shared].processingOperation = NO; NSLog(@"Setting processing op NO");
#define ADD_OPERATION_TO_QUEUE(__operation__) [[BNOperationQueue shared] addOperation:__operation__]

@interface BNOperationQueue : NSObject

@property (assign, nonatomic) BOOL processingOperation;
@property (strong, nonatomic) NSMutableArray *operations;

+(BNOperationQueue *)shared;
- (void) updateQueuewithOldDependency:(BNOperationObject *)oldObject 
                    withNewDependency:(BNOperationObject *)newDep;
- (void) addOperation:(BNOperation *)operation;
- (void) process;
@end
