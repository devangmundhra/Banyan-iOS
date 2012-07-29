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

@implementation BNOperation

@synthesize object = _object;
@synthesize action = _action;
@synthesize dependency = _dependency;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        _object = [aDecoder decodeObjectForKey:@"object"];
        _action = [aDecoder decodeObjectForKey:@"action"];
        _dependency = [aDecoder decodeObjectForKey:@"dependency"];
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

- (BOOL)performOperation
{
    BOOL        ranIt = NO;
    
    if ([self isReady] && ![self isCancelled])
    {
        if (![self isConcurrent]) {
            [self start];
        }
        else {
            [NSThread detachNewThreadSelector:@selector(start)
                                     toTarget:self withObject:nil];
        }
        ranIt = YES;
    }
    else if ([self isCancelled])
    {
        
        // Set ranIt to YES to prevent the operation from
        // being passed to this method again in the future.
        ranIt = YES;
    }
    return ranIt;
}

#pragma mark NSOperation overriding methods

- (BOOL)isReady
{
    BOOL ready = ![[BNOperationQueue shared] processingOperation] && [super isReady];
    return ready;
}

- (void)main
{
    Scene *scene = nil;
    Story *story = nil;
    NSMutableDictionary *editParams = nil;
    
    // This method is called by a thread that's set up for us by the NSOperationQueue.
    assert( ! [NSThread isMainThread] );
    
    NSLog(@"Executing req %@", self);
    // Since the network requests are asynchronous, we don't want a new operation to start until we get a response for the
    // previous operation. The isReady method of NSOperation peeks into the queue to check if any operation is in process.
    [BNOperationQueue shared].processingOperation = YES;
    
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
        
        [self removeDependencyObject:depObj];
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
            
            // DEFAULT
        default:
            NSLog(@"%s Unknown object type %d", __PRETTY_FUNCTION__, self.object.type);
            break;
    }
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"Object: %@\n Action: %@\n Dependency: %@", 
            self.object, self.action, self.dependency];
}

@end
