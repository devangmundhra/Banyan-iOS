//
//  BanyanNetworkRequestQueue.m
//  Banyan
//
//  Created by Devang Mundhra on 7/17/12.
//  Copyright (c) 2012 Devang Mundhra. All rights reserved.
//

#import "BNOperationQueue.h"

@implementation BNOperationQueue

static BNOperationQueue *_sharedBanyanNetworkOperationQueue;

@synthesize ongoingOperation = _ongoingOperation;

+ (BNOperationQueue *)shared 
{
    if (!_sharedBanyanNetworkOperationQueue) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _sharedBanyanNetworkOperationQueue = [[BNOperationQueue alloc] init];
            [_sharedBanyanNetworkOperationQueue setMaxConcurrentOperationCount:1];
            [_sharedBanyanNetworkOperationQueue setSuspended:YES];
            [_sharedBanyanNetworkOperationQueue unarchiveOperations];
            [_sharedBanyanNetworkOperationQueue setName:@"Banyan Network Operations Queue"];
            NSLog(@"%s Creating a new BNOperationsQueue now", __PRETTY_FUNCTION__);
            
            [_sharedBanyanNetworkOperationQueue addObserver:[self self] forKeyPath:@"operationCount" options:0 context:NULL];
            
            // Register for notifications to figure out when to archive
            [[NSNotificationCenter defaultCenter] addObserver:_sharedBanyanNetworkOperationQueue
                                                     selector:@selector(applicationClosing:)
                                                         name:UIApplicationDidEnterBackgroundNotification
                                                       object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:_sharedBanyanNetworkOperationQueue
                                                     selector:@selector(applicationClosing:)
                                                         name:UIApplicationWillTerminateNotification
                                                       object:nil];
        });
    }
    return _sharedBanyanNetworkOperationQueue;
}

#pragma mark Notifications
- (void)applicationClosing:(NSNotification *)notification
{
    [self archiveOperations];
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
    // The dependency check is needed in the case the edit operation is not a simple one. For example, uploading a file. In that case we cannot
    // ignore the operation as we would have the first upload the file and then edit. So we would like to queue that operation.
    if ((newOperation.action.actionType == BNOperationActionEdit || newOperation.action.actionType == BNOperationActionIncrementAttribute)
         && ![newOperation dependency])
    {
        for (BNOperation *operation in self.operations)
        {
            // The isFinished check is a bit sketchy here. Ideally it should have been a check for isExecuting which was required so that if we had already
            // but an operation on network then we do queue the edit changes. But at this point it takes a long time for an operation to be in the isExecuting
            // state and then actually get on the network. In that duration, there might be some changes that we might want to ignore (like an increase in
            // number of views from that might happen when the operation was in the inExecuting state but not yet on network)
            if (operation.action.actionType == BNOperationActionCreate && [operation.object isEqual:newOperation.object] && !operation.isFinished) {
                // This operation is to edit parameters. But this is not needed since there is a create command still pending
                // and creation is done from the local copy of the object. So the edit command would be a mere duplication
                return;
            }
        }
    }
    [super addOperation:newOperation];
    [self archiveOperations];
}

- (void) doneWithOperationWithError:(BOOL)error
{
    [[BNOperationQueue shared].ongoingOperation completeOperationWithError:error];
    [self archiveOperations];
}

#pragma mark Archiving and Unarchiving operations
+ (NSString *)pathToArchivedBNOperations
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *operationsPath = [paths objectAtIndex:0];
    operationsPath = [operationsPath stringByAppendingPathComponent:@"BNOperations"];
    
    return operationsPath;
}

- (void) archiveOperations
{
    if (![self operationCount]) {
        return;
    }
    
//    BOOL isSuspended = [self isSuspended];
//    [self setSuspended:YES];
    
    NSString *path = [BNOperationQueue pathToArchivedBNOperations];
    
    BOOL success = [NSKeyedArchiver archiveRootObject:self.operations toFile:path];
    if (!success) {
        NSLog(@"%s Error archiving operations at path: %@", __PRETTY_FUNCTION__, path);
    }
    
    [BanyanDataSource archiveHashTable];
    // Get the suspension as it was before
//    [self setSuspended:isSuspended];    
}

- (void) unarchiveOperations
{
    NSString *path = [BNOperationQueue pathToArchivedBNOperations];
    // Do nothing if there are no archived operations
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSLog(@"%s No archived operations.", __PRETTY_FUNCTION__);
        return;
    }
    
    NSArray *operations = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    for (BNOperation *operation in operations)
    {
        [self addOperation:operation];
    }
    [self deleteArchives];
}

- (void) deleteArchives
{
    NSString *path = [BNOperationQueue pathToArchivedBNOperations];
    
    NSError *error = nil;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:path] &&[[NSFileManager defaultManager] isDeletableFileAtPath:path]) {
        NSLog(@"%s Deleting archived operations at path %@", __PRETTY_FUNCTION__, path);
        
        BOOL success = [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
        if (!success) {
            NSLog(@"Error removing archived operations at path: %@", error.localizedDescription);
        }
    } else if ([[NSFileManager defaultManager] isDeletableFileAtPath:path]) {
        NSLog(@"%s Archived operations can not be deleted at path %@", __PRETTY_FUNCTION__, path);
    }
}

- (void)setSuspended:(BOOL)b
{
    [super setSuspended:b];
}

- (void) dealloc {
    NSLog(@"%s Deallocating BNOperationQueue", __PRETTY_FUNCTION__);
    [self archiveOperations];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_sharedBanyanNetworkOperationQueue removeObserver:[self self] forKeyPath:@"operationCount"];
}

+ (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                         change:(NSDictionary *)change context:(void *)context
{
    if (object == _sharedBanyanNetworkOperationQueue && [keyPath isEqualToString:@"operationCount"] && _sharedBanyanNetworkOperationQueue.operationCount == 0) {
        [_sharedBanyanNetworkOperationQueue deleteArchives];
        [BanyanDataSource deleteArchives];
    }
}
@end