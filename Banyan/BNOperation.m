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
#import "Scene+Create.h"
#import "Scene+Edit.h"
#import "Story_Defines.h"
#import "Scene_Defines.h"
#import "File+Create.h"
#import "User+Edit.h"

@interface BNOperation()
@property (assign, atomic) BOOL executing;
@property (assign, atomic) BOOL finished;
#define MAX_NUM_TRIALS_FOR_OPERATION 10
@property (assign, nonatomic) BOOL numTried;

@end

@implementation BNOperation

@synthesize object = _object;
@synthesize action = _action;
@synthesize dependency = _dependency;
@synthesize executing = _executing;
@synthesize finished = _finished;
@synthesize numTried = _numTried;

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

- (BOOL)checkDependencyForObject:(BNOperationDependency *)object
{
    if ([self.dependency containsObject:object])
        return true;
    
    return false;
}

- (void)completeOperationWithError:(BOOL)error
{
    NSLog(@"%s operation %@ finished with error %d.",
          __PRETTY_FUNCTION__, self, error);
    
    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    
    _executing = NO;
    _finished = !error;
    
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
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
        // Must move the operation to the finished state if it is canceled.
        [self willChangeValueForKey:@"isFinished"];
        _finished = YES;
        [self didChangeValueForKey:@"isFinished"];
        return;
    }
    
    // If the operation is not canceled, begin executing the task.
    [self willChangeValueForKey:@"isExecuting"];
    [BNOperationQueue shared].ongoingOperation = self;
    [NSThread detachNewThreadSelector:@selector(main) toTarget:self withObject:nil];
    _executing = YES;
    [self didChangeValueForKey:@"isExecuting"];
}

- (void)main
{    
    @try {
        Scene *scene = nil;
        Story *story = nil;
        User *user = nil;
        NSMutableDictionary *editParams = nil;
        
        // This method is called by a thread that's set up for us by the NSOperationQueue.
        assert( ! [NSThread isMainThread] );
        
        NSLog(@"Executing req %@", self);
        
        // First check if any dependencies are resolved. If yes, remove that dependency.
        // Add edit operation for the other dependencies
        for (BNOperationDependency *depObj in self.dependency)
        {
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
        
        NSLog(@"%s Parameters that will be edited: %@", __PRETTY_FUNCTION__, editParams);
        
        if (self.action.actionType == BNOperationActionEdit || self.action.actionType == BNOperationActionIncrementAttribute) {
            assert([self.object isObjectInitialized]);
        }
        
        if (self.action.actionType == BNOperationActionEdit) {
            if (!editParams) {
                editParams = [NSMutableDictionary dictionary];
            }
            [editParams addEntriesFromDictionary:self.action.context];
        }
        
        // Execute the network operation
        switch (self.object.type) {
                // SCENE
            case BNOperationObjectTypeScene:
                if (scene == nil)
                    scene = [BanyanDataSource lookForSceneId:self.object.tempId inStoryId:self.object.storyId];
                switch (self.action.actionType) {
                    case BNOperationActionCreate:
                        // call network operation for creating scene
                        [Scene createSceneOnServer:scene];
                        break;
                        
                    case BNOperationActionEdit:
                        // call network operation for editing scene
                        [Scene editScene:scene withAttributes:editParams];
                        NSLog(@"Edit network operation for scene %@", scene);
                        break;
                        
                    case BNOperationActionIncrementAttribute:
                        [scene incrementSceneAttribute:[self.action.context objectForKey:@"attribute"]
                                              byAmount:[self.action.context objectForKey:@"amount"]];
                        break;
                        
                    default:
                        NSLog(@"%s Unknown action for scene %d", __PRETTY_FUNCTION__, self.action);
                        break;
                }
                break;
                
                // STORY
            case BNOperationObjectTypeStory:
                if (story == nil)
                    story = [BanyanDataSource lookForStoryId:self.object.tempId];
                switch (self.action.actionType) {
                    case BNOperationActionCreate:
                        // call network operation for creating story
                        [Story createStoryOnServer:story];
                        break;
                        
                    case BNOperationActionEdit:
                        // call network operation for editing story
                        [Story editStory:story withAttributes:editParams];
                        NSLog(@"Edit network operation for story %@", story);
                        break;
                        
                    case BNOperationActionIncrementAttribute:
                        [story incrementStoryAttribute:[self.action.context objectForKey:@"attribute"]
                                              byAmount:[self.action.context objectForKey:@"amount"]];
                        break;
                        
                    default:
                        NSLog(@"%s Unknown action for story %@", __PRETTY_FUNCTION__, self.action);
                        break;
                }
                break;
                
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
                
            case BNOperationObjectTypeFile:
                switch (self.action.actionType) {
                    case BNOperationActionCreate:
                        [File uploadFileForLocalURL:self.object.tempId];
                        break;
                        
                    default:
                        NSLog(@"%s Unsupported action for file %@", __PRETTY_FUNCTION__, self.action);
                        break;
                }
                break;
                // DEFAULT
            default:
                NSLog(@"%s Unknown object type %d", __PRETTY_FUNCTION__, self.object.type);
                break;
        }

    }
    @catch (NSException *exception) {
        NSLog(@"%s ******ERROR****** %@", exception);
    }

}

- (NSString *)description
{
    return [NSString stringWithFormat:@"Object: %@\n Action: %@\n Dependency: %@", 
            self.object, self.action, self.dependency];
}

@end
