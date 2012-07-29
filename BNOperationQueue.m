//
//  BanyanNetworkRequestQueue.m
//  Banyan
//
//  Created by Devang Mundhra on 7/17/12.
//  Copyright (c) 2012 Devang Mundhra. All rights reserved.
//

#import "BNOperationQueue.h"

@implementation BNOperationQueue

@synthesize processingOperation = _processingOperation;
//@synthesize operations = _operations;

+ (BNOperationQueue *)shared 
{
    static BNOperationQueue *_sharedBanyanNetworkOperationQueue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedBanyanNetworkOperationQueue = [[BNOperationQueue alloc] init];
//        [_sharedBanyanNetworkOperationQueue setMaxConcurrentOperationCount:1];
//        [_sharedBanyanNetworkOperationQueue setName:@"Banyan Network Operations Queue"];
        // TODO: Check if anything is archived. If so, obtain from the archive.
        _sharedBanyanNetworkOperationQueue.operations = [NSMutableArray array];
        [_sharedBanyanNetworkOperationQueue setProcessingOperation:NO];
        // dispatch a thread and start executing the queue
        [NSThread detachNewThreadSelector:@selector(process) toTarget:_sharedBanyanNetworkOperationQueue withObject:nil];
    });
    
    return _sharedBanyanNetworkOperationQueue;
}

- (void) updateQueuewithOldDependency:(BNOperationDependency *)oldObject 
                    withNewDependency:(BNOperationDependency *)newDep
{
    for (BNOperation *op in self.operations)
    {
        if ([op checkDependencyForObject:oldObject]) {
            [op removeDependencyObject:oldObject];
            [op addDependencyObject:newDep];
        }
    }
}

- (void) addOperation:(BNOperation *)newOperation
{
    if ((newOperation.action.actionType == BNOperationActionEdit || newOperation.action.actionType == BNOperationActionIncrementAttribute)
         && ![newOperation dependency])
    {
        for (BNOperation *operation in self.operations)
        {
            if (operation.action.actionType == BNOperationActionCreate && [operation.object isEqual:newOperation.object]) {
                // This operation is to edit parameters. But this is not needed since there is a create command still pending
                // and creation is done from the local copy of the object. So the edit command would be a mere duplication
                return;
            }
        }
    }
    [self.operations addObject:newOperation];
//    [super addOperation:newOperation];
//    NSLog(@"%s Operation count: %d with req: %@", __PRETTY_FUNCTION__, [self operationCount], newOperation);
}

- (void) operate
{
    if (self.operations.count) {
        BNOperation *operation = [self.operations objectAtIndex:0];
        if ([operation performOperation])
            [self.operations removeObject:operation];
    }
}

- (void) process
{
    do {
//        NSLog(@"%s New thread works", __PRETTY_FUNCTION__);
        [self operate];
    } while (TRUE);
}
@end
