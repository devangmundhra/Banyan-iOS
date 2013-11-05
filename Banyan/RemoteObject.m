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
#import "Piece.h"
#import "GooglePlacesObject.h"

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
@dynamic timeStamp;
@dynamic resourceUri;

#pragma mark -
#pragma mark Revision management
- (void)cloneFrom:(RemoteObject *)source
{
    for (NSString *key in [[[source entity] attributesByName] allKeys]) {
        if ([key isEqualToString:@"bnObjectId"]) {
            NSLog(@"Skipping attribute %@", key);
            continue;
        }
        NSLog(@"Copying attribute %@", key);
        [self setValue:[source valueForKey:key] forKey:key];
    }
    for (NSString *key in [[[source entity] relationshipsByName] allKeys]) {
        if ([key isEqualToString:@"original"] || [key isEqualToString:@"revision"]) {
            NSLog(@"Skipping relationship %@", key);
        } else if ([key isEqualToString:@"comments"]) {
            NSLog(@"Copying relationship %@", key);
            [self setComments:[source comments]];
        } else if ([key isEqualToString:@"pieces"]) {
            NSLog(@"Skipping relationship %@", key);
        } else if ([key isEqualToString:@"media"]) {
            NSLog(@"Skipping relationship %@", key);
        } else if ([key isEqualToString:@"author"]) {
            NSLog(@"Skipping relationship %@", key);
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
        if ([obj isKindOfClass:[Piece class]]) {
            ((Piece *)obj).creatingGifFromMedia = NO;
        }
    }
    
    // It is possible that a clone of a piece was created and then the app crashed. So the clone is hanging around. Delete the clone.
    // TO-DO: Check if this can really occur. If so, check how to handle it for stories.
    [request setEntity:[NSEntityDescription entityForName:kBNPieceClassKey inManagedObjectContext:[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext]];
    request.predicate = [NSPredicate predicateWithFormat:@"(story = nil)"];
    array = [[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext executeFetchRequest:request error:&error];
    for (Piece *piece in array) {
        [piece remove];
    }
    
    [Media validateAllMedias];
}

#pragma mark-
#pragma mark RestKit dynamic mapping
- (BOOL)validateLocation:(id *)ioValue error:(NSError **)outError
{
    *ioValue = [BNDuckTypedObject duckTypedObjectWrappingDictionary:*ioValue];
    return YES;
}

# pragma mark sharing
- (void)shareOnFacebook
{
}

// Convenience method to perform some action that requires the "publish_actions" permissions.
- (void) performFacebookPublishAction:(void (^)(void)) action {
    // we defer request for permission to post to the moment of post, then we check for the permission
    if ([FBSession.activeSession.permissions indexOfObject:@"publish_actions"] == NSNotFound) {
        // if we don't already have the permission, then we request it now
        [FBSession.activeSession requestNewPublishPermissions:@[@"publish_actions"]
                                              defaultAudience:FBSessionDefaultAudienceFriends
                                            completionHandler:^(FBSession *session, NSError *error) {
                                                if (!error) {
                                                    action();
                                                }
                                                //For this example, ignore errors (such as if user cancels).
                                            }];
    } else {
        action();
    }
    
}

// UIAlertView helper for post buttons
- (void)showAlert:(NSString *)message
           result:(id)result
            error:(NSError *)error {
    
    NSString *alertMsg;
    NSString *alertTitle;
    if (error) {
        alertTitle = @"Error";
        // For simplicity, we will use any error message provided by the SDK,
        // but you may consider inspecting the fberrorShouldNotifyUser or
        // fberrorCategory to provide better recourse to users. See the Scrumptious
        // sample for more examples on error handling.
        if (error.fberrorUserMessage) {
            alertMsg = error.fberrorUserMessage;
        } else {
            alertMsg = @"Operation failed due to a connection problem, retry later.";
        }
    } else {
//        NSDictionary *resultDict = (NSDictionary *)result;
        alertMsg = [NSString stringWithFormat:@"Successfully posted '%@'.", message];
//        NSString *postId = [resultDict valueForKey:@"id"];
//        if (!postId) {
//            postId = [resultDict valueForKey:@"postId"];
//        }
//        if (postId) {
//            alertMsg = [NSString stringWithFormat:@"%@\nPost ID: %@", alertMsg, postId];
//        }
        alertTitle = @"Success";
    }
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:alertTitle
                                                        message:alertMsg
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertView show];
}

- (NSString *)getIdentifierForMediaFileName
{
    return [BNMisc genRandStringLength:10];
}

@end

@implementation RemoteObject (CoreDataGeneratedAccessors)

#pragma mark Comments
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

#pragma mark Media
- (void)insertObject:(Media *)value inMediaAtIndex:(NSUInteger)idx {
    NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:idx];
    [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"media"];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self mutableOrderedSetValueForKey:@"media"]];
    [tmpOrderedSet insertObject:value atIndex:idx];
    [self setPrimitiveValue:tmpOrderedSet forKey:@"media"];
    [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"media"];
}

- (void)removeObjectFromMediaAtIndex:(NSUInteger)idx {
    NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:idx];
    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"media"];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self mutableOrderedSetValueForKey:@"media"]];
    [tmpOrderedSet removeObjectAtIndex:idx];
    [self setPrimitiveValue:tmpOrderedSet forKey:@"media"];
    [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"media"];
}

- (void)insertMedia:(NSArray *)values atIndexes:(NSIndexSet *)indexes {
    [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"media"];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self mutableOrderedSetValueForKey:@"media"]];
    [tmpOrderedSet insertObjects:values atIndexes:indexes];
    [self setPrimitiveValue:tmpOrderedSet forKey:@"media"];
    [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"media"];
}

- (void)removeMediaAtIndexes:(NSIndexSet *)indexes {
    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"media"];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self mutableOrderedSetValueForKey:@"media"]];
    [tmpOrderedSet removeObjectsAtIndexes:indexes];
    [self setPrimitiveValue:tmpOrderedSet forKey:@"media"];
    [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"media"];
}

- (void)replaceObjectInMediaAtIndex:(NSUInteger)idx withObject:(Media *)value {
    NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:idx];
    [self willChange:NSKeyValueChangeReplacement valuesAtIndexes:indexes forKey:@"media"];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self mutableOrderedSetValueForKey:@"media"]];
    [tmpOrderedSet replaceObjectAtIndex:idx withObject:value];
    [self setPrimitiveValue:tmpOrderedSet forKey:@"media"];
    [self didChange:NSKeyValueChangeReplacement valuesAtIndexes:indexes forKey:@"media"];
}

- (void)replaceMediaAtIndexes:(NSIndexSet *)indexes withMedia:(NSArray *)values {
    [self willChange:NSKeyValueChangeReplacement valuesAtIndexes:indexes forKey:@"media"];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self mutableOrderedSetValueForKey:@"media"]];
    [tmpOrderedSet replaceObjectsAtIndexes:indexes withObjects:values];
    [self setPrimitiveValue:tmpOrderedSet forKey:@"media"];
    [self didChange:NSKeyValueChangeReplacement valuesAtIndexes:indexes forKey:@"media"];
}

- (void)addMediaObject:(Media *)value {
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self mutableOrderedSetValueForKey:@"media"]];
    NSUInteger idx = [tmpOrderedSet count];
    NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:idx];
    [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"media"];
    [tmpOrderedSet addObject:value];
    [self setPrimitiveValue:tmpOrderedSet forKey:@"media"];
    [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"media"];
}

- (void)removeMediaObject:(Media *)value {
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self mutableOrderedSetValueForKey:@"media"]];
    NSUInteger idx = [tmpOrderedSet indexOfObject:value];
    if (idx != NSNotFound) {
        NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:idx];
        [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"media"];
        [tmpOrderedSet removeObject:value];
        [self setPrimitiveValue:tmpOrderedSet forKey:@"media"];
        [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"media"];
    }
}

- (void)addMedia:(NSOrderedSet *)values {
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self mutableOrderedSetValueForKey:@"media"]];
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
    NSUInteger valuesCount = [values count];
    NSUInteger objectsCount = [tmpOrderedSet count];
    for (NSUInteger i = 0; i < valuesCount; ++i) {
        [indexes addIndex:(objectsCount + i)];
    }
    if (valuesCount > 0) {
        [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"media"];
        [tmpOrderedSet addObjectsFromArray:[values array]];
        [self setPrimitiveValue:tmpOrderedSet forKey:@"media"];
        [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"media"];
    }
}

- (void)removeMedia:(NSOrderedSet *)values {
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self mutableOrderedSetValueForKey:@"media"]];
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
    for (id value in values) {
        NSUInteger idx = [tmpOrderedSet indexOfObject:value];
        if (idx != NSNotFound) {
            [indexes addIndex:idx];
        }
    }
    if ([indexes count] > 0) {
        [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"media"];
        [tmpOrderedSet removeObjectsAtIndexes:indexes];
        [self setPrimitiveValue:tmpOrderedSet forKey:@"media"];
        [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"media"];
    }
}

- (void)exchangeObjectInMediaAtIndex:(NSUInteger)idx1 withObjectInMediaAtIndex:(NSUInteger)idx2
{
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
    [indexes addIndex:idx1];
    [indexes addIndex:idx2];
    
    [self willChange:NSKeyValueChangeReplacement valuesAtIndexes:indexes forKey:@"media"];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self mutableOrderedSetValueForKey:@"media"]];
    [tmpOrderedSet exchangeObjectAtIndex:idx1 withObjectAtIndex:idx2];
    [self setPrimitiveValue:tmpOrderedSet forKey:@"media"];
    [self didChange:NSKeyValueChangeReplacement valuesAtIndexes:indexes forKey:@"media"];
}

@end

