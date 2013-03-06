//
//  BNOperation.m
//  Banyan
//
//  Created by Devang Mundhra on 7/15/12.
//  Copyright (c) 2012 Devang Mundhra. All rights reserved.
//

#import "BNOperation.h"
#import "BanyanDataSource.h"
#import "Story+Create.h"
#import "Story+Edit.h"
#import "Story+Delete.h"
#import "Piece+Create.h"
#import "Piece+Edit.h"
#import "Piece+Delete.h"
#import "Story_Defines.h"
#import "File+Create.h"
#import "User+Edit.h"
#import "Activity.h"

@interface BNOperation()
@property (assign, atomic) BOOL executing;
@property (assign, atomic) BOOL finished;
#define MAX_NUM_TRIALS_FOR_OPERATION 10
@property (atomic) NSUInteger numTried;
@property UIBackgroundTaskIdentifier backgroundTask;

@end

@implementation BNOperation

@synthesize object = _object;
@synthesize action = _action;
@synthesize dependency = _dependency;
@synthesize executing = _executing;
@synthesize finished = _finished;
@synthesize numTried = _numTried;
@synthesize backgroundTask = _backgroundTask;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        _object = [aDecoder decodeObjectForKey:@"object"];
        _action = [aDecoder decodeObjectForKey:@"action"];
        _dependency = [aDecoder decodeObjectForKey:@"dependency"];
        _executing = NO;
        _finished = NO;
        _numTried = 0;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_object forKey:@"object"];
    [aCoder encodeObject:_action forKey:@"action"];
    [aCoder encodeObject:_dependency forKey:@"dependency"];
}


- (id)initWithObject:(BNOperationObject *)object
                  action:(BNOperationActionType)actionType
            dependencies:(NSMutableSet *)dependency
{	
    if((self = [super init])) {
        _object = object;
        _action = [[BNOperationAction alloc] initWithActionType:actionType];
        _dependency = dependency;
        _numTried = 0;
    }
    
    return self;
}

- (void)removeBNOpDependencyOnBNOpObject:(BNOperationObject *)object
{
    if (!self.dependency) {
        return;
    }
    NSMutableSet *localDependencySet = [NSMutableSet setWithSet:self.dependency];
    
    for (BNOperationDependency *dep in self.dependency) {
        if ([dep.object isEqual:object]) {
            // Remove dependency from this object
            [localDependencySet removeObject:dep];
        }
    }
    self.dependency = localDependencySet;
}

- (void)addDependencyObject:(BNOperationDependency *)object
{
    if (!self.dependency)
        self.dependency = [NSMutableSet set];
    [self.dependency addObject:object];
}

- (void)removeDependencyObject:(BNOperationDependency *)object
{
    if (self.dependency)
        [self.dependency removeObject:object];
    
    if (self.dependency.count == 0)
        self.dependency = nil;
}

- (BOOL)checkBNOperationDependency:(BNOperationDependency *)object
{
    if ([self.dependency containsObject:object])
        return true;
    
    return false;
}

- (void)completeOperationWithError:(BOOL)error
{
    NSLog(@"%s operation %@ finished with error %d.",
          __PRETTY_FUNCTION__, self, error);
    
    if (error) {
        // If there is an error, start myself again
        [BNOperationQueue shared].ongoingOperation = self;
        [self start];
        return;
    }
    
    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    [BNOperationQueue shared].ongoingOperation = nil;
    
    _executing = NO;
    _finished = YES;
    
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
    
	if ([BNOperation isMultitaskingSupported]) {
		dispatch_async(dispatch_get_main_queue(), ^{
			if (self.backgroundTask != UIBackgroundTaskInvalid) {
				[[UIApplication sharedApplication] endBackgroundTask:self.backgroundTask];
				self.backgroundTask = UIBackgroundTaskInvalid;
			}
		});
	}
}

#pragma mark NSOperation overriding methods

- (BOOL)isConcurrent
{
    return YES;
}

- (BOOL)isFinished
{
    return _finished;
}

- (BOOL)isExecuting
{
    return _executing;
}

- (void)start {
    // Always check for cancellation before launching the task.
    if ([self isCancelled] || self.numTried >= MAX_NUM_TRIALS_FOR_OPERATION)
    {
        if (self.numTried >= MAX_NUM_TRIALS_FOR_OPERATION) {
            // We see this currently for uploading images on Edge. File operations are not being completed.
            // In that case, remove the dependency for this object from all pending operations
            [[BNOperationQueue shared] removeOperationDependencyFromBNOpObject:self.object];
        }
        // Must move the operation to the finished state if it is canceled.
        [self willChangeValueForKey:@"isFinished"];
        _finished = YES;
        [self didChangeValueForKey:@"isFinished"];
        return;
    }
    
    self.numTried++;
    // If the operation is not canceled, begin executing the task.
    [self willChangeValueForKey:@"isExecuting"];
    [BNOperationQueue shared].ongoingOperation = self;
    [NSThread detachNewThreadSelector:@selector(main) toTarget:self withObject:nil];
    _executing = YES;
    [self didChangeValueForKey:@"isExecuting"];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        MTStatusBarOverlay *overlay = [MTStatusBarOverlay sharedInstance];
        overlay.animation = MTStatusBarOverlayAnimationNone;
        overlay.delegate = nil;
        NSString *message = [NSString stringWithFormat:@"%@ %@", [self.action typeString], [self.object typeString]];
        [overlay postMessage:message];
        NSLog(@"%s Message printed: %@", __PRETTY_FUNCTION__, message);
    });
}

- (void)main
{    
    @try {
        User *user = nil;
        NSMutableDictionary *editParams = nil;
        
        // This method is called by a thread that's set up for us by the NSOperationQueue.
        assert( ! [NSThread isMainThread] );
        
        NSLog(@"Executing req %@", self);
        
		if ([BNOperation isMultitaskingSupported]) {
            if (!self.backgroundTask || self.backgroundTask == UIBackgroundTaskInvalid) {
                self.backgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
                    // Synchronize the cleanup call on the main thread in case
                    // the task actually finishes at around the same time.
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (self.backgroundTask != UIBackgroundTaskInvalid)
                        {
                            [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTask];
                            self.backgroundTask = UIBackgroundTaskInvalid;
                        }
                    });
                }];
            }
		}
        
        // First check if any dependencies are resolved. If yes, remove that dependency.
        // Add edit operation for the other dependencies
        for (BNOperationDependency *depObj in self.dependency)
        {
            // An object being deleted cannot have any dependencies
            assert(self.action.actionType != BNOperationActionDelete);
            
            if (![depObj.object isObjectInitialized]) {
                NSLog(@"Dep object not initialized: %@", depObj);
                BNOperation *operation = [[BNOperation alloc] initWithObject:self.object
                                                                      action:BNOperationActionEdit
                                                                dependencies:[NSMutableSet setWithObject:depObj]];
                [[BNOperationQueue shared] addOperation:operation];
            } else {
                NSLog(@"Dep object initialized: %@", depObj);
                // Update the object with that dependency
                
                if (!editParams) {
                    editParams = [NSMutableDictionary dictionaryWithCapacity:1];
                }
                [editParams setObject:UPDATED(depObj.object.tempId) forKey:depObj.field];
            }
        }
        
        if (self.action.actionType == BNOperationActionEdit) {
            if (!editParams) {
                editParams = [NSMutableDictionary dictionary];
            }
            [editParams addEntriesFromDictionary:self.action.context];
        }
        
        if (self.action.actionType == BNOperationActionEdit || self.action.actionType == BNOperationActionIncrementAttribute) {
            NSLog(@"%s Parameters that will be edited: %@", __PRETTY_FUNCTION__, editParams);
            if (![self.object isObjectInitialized]) {
                NSLog(@"%s ERROR: Object %@ expected to be already initialized for action %@. Ignore this job!", __PRETTY_FUNCTION__, self.object, self.action);
                [self completeOperationWithError:YES];
            }
        }
        
        // Execute the network operation
        switch (self.object.type) {
                
            case BNOperationObjectTypeUser:
                if (user == nil) {
                    user = [User userWithId:self.object.tempId];
                }
                switch (self.action.actionType) {
                    case BNOperationActionEdit:
                        [User editUser:user withAttributes:editParams];
                        break;
                        
                    default:
                        break;
                }

            default:
                NSLog(@"%s Unknown object type %d", __PRETTY_FUNCTION__, self.object.type);
                break;
        }

    }
    @catch (NSException *exception) {
        NSLog(@"%s ******ERROR****** %@", __PRETTY_FUNCTION__, exception);
    }

}

+ (BOOL)isMultitaskingSupported
{
	BOOL multiTaskingSupported = NO;
	if ([[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)]) {
		multiTaskingSupported = [(id)[UIDevice currentDevice] isMultitaskingSupported];
	}
	return multiTaskingSupported;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"Object: %@\n Action: %@\n Dependency: %@", 
            self.object, self.action, self.dependency];
}

@end
