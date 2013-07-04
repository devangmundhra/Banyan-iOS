//
//  Story+Edit.m
//  Storied
//
//  Created by Devang Mundhra on 3/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Story+Edit.h"
#import "AFBanyanAPIClient.h"
#import "Media.h"
#import "BanyanDataSource.h"
#import "Story+Create.h"
#import "Story+Delete.h"

@implementation Story (Edit)

+ (void) editStory:(Story *)story
{
    [story save];

    // If the object has not been created yet, don't ask for editing it on the server.
    if (!story.bnObjectId.length) {
        // TODO: There is still a race condition here when the story is being created
        // and an edit comes in
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Can't synchronize the story with the server."
                                                        message:@"A previous synchronization is going on. Try in a bit!"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    story.remoteStatus = RemoteObjectStatusPushing;
    
     NSLog(@"Edit Story %@", story);
    
    // Block to upload the story
    void (^updateStory)(Story *) = ^(Story *story) {
        RKObjectManager *objectManager = [[RKObjectManager alloc] initWithHTTPClient:[AFBanyanAPIClient sharedClient]];
        // For serializing
        RKObjectMapping *storyRequestMapping = [RKObjectMapping requestMapping];
        [storyRequestMapping addAttributeMappingsFromArray:@[STORY_TITLE, STORY_WRITE_ACCESS, STORY_READ_ACCESS, STORY_TAGS, @"isLocationEnabled"]];

        RKObjectMapping *locationMapping = [RKObjectMapping requestMapping];
        [locationMapping addAttributeMappingsFromArray:@[@"id", @"category", @"name"]];
        RKObjectMapping *locationLocationMapping = [RKObjectMapping requestMapping];
        [locationLocationMapping addAttributeMappingsFromArray:@[@"street", @"city", @"state", @"country", @"zip", @"latitude", @"longitude"]];
        [locationMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"location" toKeyPath:@"location" withMapping:locationLocationMapping]];
        [storyRequestMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"location" toKeyPath:@"location" withMapping:locationMapping]];
        
        RKObjectMapping *mediaMapping = [RKObjectMapping requestMapping];
        [mediaMapping addAttributeMappingsFromDictionary:@{@"remoteURL": @"url"}];
        [mediaMapping addAttributeMappingsFromArray:@[@"filename", @"filesize", @"height", @"length", @"orientation", @"title", @"width", @"mediaType"]];
        [storyRequestMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"media" toKeyPath:@"media" withMapping:mediaMapping]];
        
        RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor
                                                  requestDescriptorWithMapping:storyRequestMapping
                                                  objectClass:[Story class]
                                                  rootKeyPath:nil];
        RKEntityMapping *storyResponseMapping = [RKEntityMapping mappingForEntityForName:kBNStoryClassKey
                                                                    inManagedObjectStore:[RKManagedObjectStore defaultStore]];

        [storyResponseMapping addAttributeMappingsFromArray:@[PARSE_OBJECT_UPDATED_AT]];
        
        RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:storyResponseMapping
                                                                                           pathPattern:nil
                                                                                               keyPath:nil
                                                                                           statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
        [objectManager addRequestDescriptor:requestDescriptor];
        [objectManager addResponseDescriptor:responseDescriptor];
        
        [objectManager putObject:story
                            path:BANYAN_API_OBJECT_URL(@"Story", story.bnObjectId)
                      parameters:nil
                         success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                             NSLog(@"Update story successful %@", story);
                             story.remoteStatus = RemoteObjectStatusSync;
                             [story save];
                         }
                         failure:^(RKObjectRequestOperation *operation, NSError *error) {
                             story.remoteStatus = RemoteObjectStatusFailed;
                             if ([[error localizedDescription] rangeOfString:@"got 400"].location != NSNotFound) {
                                 // The story is no longer available on the server. This is now a local copy
                                 story.remoteStatus = RemoteObjectStatusLocal;
                                 [Story deleteStory:story];
                             }
                             NSLog(@"Error in updating story");
                         }];
    };
    
    updateStory(story);
    [story save];
}
@end

@implementation Story (CoreDataGeneratedAccessors)

- (void)insertObject:(Piece *)value inPiecesAtIndex:(NSUInteger)idx
{
    [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndex:idx] forKey:@"pieces"];
    [[self primitiveValueForKey:@"pieces"] insertObject:value atIndex:idx];
    [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndex:idx] forKey:@"pieces"];
}

- (void)removeObjectFromPiecesAtIndex:(NSUInteger)idx
{
    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:[NSIndexSet indexSetWithIndex:idx] forKey:@"pieces"];
    [[self primitiveValueForKey:@"pieces"] removeObjectAtIndex:idx];
    [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:[NSIndexSet indexSetWithIndex:idx] forKey:@"pieces"];
}

- (void)insertPieces:(NSArray *)value atIndexes:(NSIndexSet *)indexes
{
    
}
- (void)removePiecesAtIndexes:(NSIndexSet *)indexes
{
    
}
- (void)replaceObjectInPiecesAtIndex:(NSUInteger)idx withObject:(Piece *)value
{
    
}
- (void)replacePiecesAtIndexes:(NSIndexSet *)indexes withPieces:(NSArray *)values
{
    
}

- (void)addPiecesObject:(Piece *)value
{
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"pieces" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"pieces"] addObject:value];
    [self didChangeValueForKey:@"pieces" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
}

- (void)removePiecesObject:(Piece *)value
{
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"pieces" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"pieces"] removeObject:value];
    [self didChangeValueForKey:@"pieces" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
}

- (void)addPieces:(NSSet *)value
{
    [self willChangeValueForKey:@"pieces" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"pieces"] unionSet:value];
    [self didChangeValueForKey:@"pieces" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
}

- (void)removePieces:(NSSet *)value
{
    [self willChangeValueForKey:@"pieces" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"pieces"] minusSet:value];
    [self didChangeValueForKey:@"pieces" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
}
@end
