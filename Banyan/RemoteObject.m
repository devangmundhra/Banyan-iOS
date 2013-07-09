//
//  RemoteObject.m
//  Banyan
//
//  Created by Devang Mundhra on 5/15/13.
//
//

#import "RemoteObject.h"
#import "Comment.h"
#import "Media.h"
#import "Story.h"

@implementation RemoteObject

@dynamic author;
@dynamic bnObjectId;
@dynamic createdAt;
@dynamic isLocationEnabled;
@dynamic lastSynced;
@dynamic location;
@dynamic remoteStatusNumber, primitiveRemoteStatusNumber;
@dynamic updatedAt;
@dynamic permaLink;
@dynamic comments;
@dynamic media;
@dynamic viewedByCurUser, likedByCurUser, favoriteByCurUser, numberOfLikes, numberOfViews;

#pragma mark -
#pragma mark Revision management
- (void)cloneFrom:(RemoteObject *)source {
    for (NSString *key in [[[source entity] attributesByName] allKeys]) {
        NSLog(@"Copying attribute %@", key);
        [self setValue:[source valueForKey:key] forKey:key];
    }
    for (NSString *key in [[[source entity] relationshipsByName] allKeys]) {
        if ([key isEqualToString:@"original"] || [key isEqualToString:@"revision"]) {
            NSLog(@"Skipping relationship %@", key);
        } else if ([key isEqualToString:@"comments"]) {
            NSLog(@"Copying relationship %@", key);
            [self setComments:[source comments]];
        } else if ([key isEqualToString:@"media"] || [key isEqualToString:@"pieces"]) {
            NSLog(@"Skipping relationship %@", key);
            // Media if changed during editing will be persisted.
            //            [self setMedia:[source media]];
            //            self.media = [Media newMediaForObject:self];
            //            for (NSString *key in [[[source.media entity] attributesByName] allKeys]) {
            //                NSLog(@"Copying media attribute %@", key);
            //                [self.media setValue:[source.media valueForKey:key] forKey:key];
            //            }
        } else {
            NSLog(@"Copying relationship %@", key);
            [self setValue: [source valueForKey:key] forKey: key];
        }
    }
}

- (RemoteObjectStatus)remoteStatus {
    return (RemoteObjectStatus)[[self remoteStatusNumber] intValue];
}

- (void)setRemoteStatus:(RemoteObjectStatus)aStatus {
    [self setRemoteStatusNumber:[NSNumber numberWithInt:aStatus]];
}


+ (NSString *)titleForRemoteStatus:(NSNumber *)remoteStatus {
    switch ([remoteStatus intValue]) {
        case RemoteObjectStatusPushing:
            return NSLocalizedString(@"Uploading", @"");
            break;
        case RemoteObjectStatusFailed:
            return NSLocalizedString(@"Failed", @"");
            break;
        case RemoteObjectStatusSync:
            return NSLocalizedString(@"Stories", @"");
            break;
        default:
            return NSLocalizedString(@"Local", @"");
            break;
    }
}

- (void)save
{
    NSError *error = nil;
    if (![self.managedObjectContext saveToPersistentStore:&error]) {
        NSLog(@"Unresolved Core Data Save error %@, %@ in saving remote object", error, [error userInfo]);
        exit(-1);
    }
    UPDATE_STORY_LIST(self);
}

- (void) remove
{
    if (self.remoteStatus == RemoteObjectStatusPushing || self.remoteStatus == RemoteObjectStatusLocal) {
        // Send notification to cancel this upload
    }
    
    [self.managedObjectContext performBlockAndWait:^(void) {
        [[self managedObjectContext] deleteObject:self];
    }];
    [self save];
}

+ (void)validateAllObjects
{
    // Any objects which are in the Uploading state should be marked as failed
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"RemoteObject" inManagedObjectContext:[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(remoteStatusNumber = %@)",
                              [NSNumber numberWithInt:RemoteObjectStatusPushing]];
    [request setPredicate:predicate];
    
    NSError *error = nil;
    NSArray *array = [[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext executeFetchRequest:request error:&error];
    for (RemoteObject *obj in array) {
        obj.remoteStatus = RemoteObjectStatusFailed;
    }
    
//    [request setEntity:[NSEntityDescription entityForName:kBNStoryClassKey inManagedObjectContext:[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext]];
//    request.predicate = [NSPredicate predicateWithFormat:@"(ANY pieces.remoteStatusNumber != %@)",
//                         [NSNumber numberWithInt:RemoteObjectStatusSync]];;
//    array = [[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext executeFetchRequest:request error:&error];
//    for (Story *story in array) {
//        story.uploadStatusNumber = story.uploadStatusNumber;
//    }
}

#pragma mark-
#pragma mark RestKit dynamic mapping
- (BOOL)validateLocation:(id *)ioValue error:(NSError **)outError
{
    *ioValue = [FBGraphObject graphObjectWrappingDictionary:*ioValue];
    return YES;
}

# pragma mark sharing
- (void)share {
}

@end

@implementation RemoteObject (CoreDataGeneratedAccessors)

- (void)addCommentsObject:(Comment *)value
{
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"comments" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"comments"] addObject:value];
    [self didChangeValueForKey:@"comments" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
}

- (void)removeCommentsObject:(Comment *)value
{
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"comments" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"comments"] removeObject:value];
    [self didChangeValueForKey:@"comments" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
}

- (void)addComments:(NSSet *)value
{
    [self willChangeValueForKey:@"comments" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"comments"] unionSet:value];
    [self didChangeValueForKey:@"comments" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
}

- (void)removeComments:(NSSet *)value
{
    [self willChangeValueForKey:@"comments" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"comments"] minusSet:value];
    [self didChangeValueForKey:@"comments" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
}

- (void)addMediaObject:(Media *)value
{
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"media" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"media"] addObject:value];
    [self didChangeValueForKey:@"media" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
}

- (void)removeMediaObject:(Media *)value
{
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"media" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"media"] removeObject:value];
    [self didChangeValueForKey:@"media" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
}

- (void)addMedia:(NSSet *)value
{
    [self willChangeValueForKey:@"media" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"media"] unionSet:value];
    [self didChangeValueForKey:@"media" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
}

- (void)removeMedia:(NSSet *)value
{
    [self willChangeValueForKey:@"media" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"media"] minusSet:value];
    [self didChangeValueForKey:@"media" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
}

@end

