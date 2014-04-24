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
#import "objc/runtime.h"
#import "BNS3TransferManager.h"

static char operationKey;

@implementation RemoteObject

@dynamic author;
@dynamic bnObjectId;
@dynamic createdAt;
@dynamic lastSynced;
@dynamic location;
@dynamic remoteStatusNumber, primitiveRemoteStatusNumber;
@dynamic updatedAt;
@dynamic permaLink;
@dynamic comments;
@dynamic media;
@dynamic viewedByCurUser, likeActivityResourceUri, numberOfLikes, numberOfViews;
@dynamic timeStamp;
@dynamic resourceUri;
@synthesize ongoingOperation = _ongoingOperation;
@synthesize transferManager = _transferManager;

#pragma mark -
#pragma mark Revision management

- (RemoteObject *) cloneIntoNSManagedObjectContext:(NSManagedObjectContext *)newContext
{
    [self save];
    NSError *error = nil;
    RemoteObject *obj = (RemoteObject *)[newContext existingObjectWithID:self.objectID error:&error];
    NSAssert1(obj, @"cloneIntoNSManagedObjectContext_object", error.localizedDescription);
    [newContext refreshObject:obj mergeChanges:YES];
    return obj;
}

- (void)cloneFrom:(RemoteObject *)source
{
    for (NSString *key in [[[source entity] attributesByName] allKeys]) {
        if ([key isEqualToString:@"bnObjectId"]) {
            BNLogTrace(@"Skipping attribute %@", key);
            continue;
        }
        BNLogTrace(@"Copying attribute %@", key);
        [self setValue:[source valueForKey:key] forKey:key];
    }
    for (NSString *key in [[[source entity] relationshipsByName] allKeys]) {
        if ([key isEqualToString:@"original"] || [key isEqualToString:@"revision"]) {
            BNLogTrace(@"Skipping relationship %@", key);
        } else if ([key isEqualToString:@"comments"]) {
            BNLogTrace(@"Copying relationship %@", key);
            [self setComments:[source comments]];
        } else if ([key isEqualToString:@"pieces"]) {
            BNLogTrace(@"Skipping relationship %@", key);
        } else if ([key isEqualToString:@"media"]) {
            BNLogTrace(@"Skipping relationship %@", key);
        } else if ([key isEqualToString:@"author"]) {
            NSLog(@"Skipping relationship %@", key);
        } else {
            BNLogTrace(@"Copying relationship %@", key);
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
        NSAssert2(false, @"Unresolved Core Data Save error %@, %@ in saving remote object", error, [error userInfo]);
    }
}

- (void) remove
{
    if (self.remoteStatus == RemoteObjectStatusPushing || self.remoteStatus == RemoteObjectStatusLocal) {
        // Cancel any ongoing operations
        [self cancelAnyOngoingOperation];
    }
    
    [self.managedObjectContext performBlockAndWait:^(void) {
        [[self managedObjectContext] deleteObject:self];
    }];
    [self save];
}

+ (NSUInteger) numRemoteObjectsWithPendingChanges
{
    // If there are any remoteObjects which are not in sync state, return YES
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"RemoteObject" inManagedObjectContext:[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(remoteStatusNumber != %@)",
                              [NSNumber numberWithInt:RemoteObjectStatusSync]];
    [request setPredicate:predicate];
    
    NSError *error = nil;
    NSArray *array = [[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext executeFetchRequest:request error:&error];
    return [array count];
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
        [obj cancelAnyOngoingOperation];
        obj.remoteStatus = RemoteObjectStatusFailed;
    }
    
    // Delete all remote objects which are local at start time
    // Suppose a crash happens while a piece/story was being created. Since the next time the app starts, those objects
    // will be in 'Drafts' state, the story refresh will be cancelled. And the local remote object won't get deleted.
    predicate = [NSPredicate predicateWithFormat:@"(remoteStatusNumber = %@)",
                 [NSNumber numberWithInt:RemoteObjectStatusLocal]];
    [request setPredicate:predicate];
    error = nil;
    array = [[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext executeFetchRequest:request error:&error];
    for (RemoteObject *remoteObj in array) {
        [remoteObj remove];
    }

    // This is possible when there is a piece cached in core-data and that piece is deleted in the server. Therefore when the story arrives, the connection between
    // this piece and the story is broken and the piece is left hanging around. So the next time this method is called, all such pieces get deleted from the local cache
    [request setEntity:[NSEntityDescription entityForName:kBNPieceClassKey inManagedObjectContext:[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext]];
    request.predicate = [NSPredicate predicateWithFormat:@"(story = nil)"];
    error = nil;
    array = [[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext executeFetchRequest:request error:&error];
    for (Piece *piece in array) {
        [piece remove];
    }
    
    [Media validateAllMedias];
}

- (BNS3TransferManager *)transferManager
{
    @synchronized(self) {
        if (!_transferManager) {
            _transferManager = [[BNS3TransferManager alloc] init];
            _transferManager.s3 = [BNAWSS3Client sharedClient];
        }
    }
    
    return _transferManager;
}

- (RKObjectRequestOperation *)ongoingOperation
{
    return objc_getAssociatedObject(self, &operationKey);
}

- (void)setOngoingOperation:(RKObjectRequestOperation *)ongoingOperation
{
    objc_setAssociatedObject(self, &operationKey, ongoingOperation, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)cancelAnyOngoingOperation
{
    [self.transferManager cancelAllTransfers];
    RKObjectRequestOperation *operation = [self ongoingOperation];
    if (operation)
    {
        [operation cancel];
        [self setOngoingOperation:nil];
    }
}

- (void)uploadFailedRemoteObject
{
    // Do nothing
    // To be implemented by subclasses if required
}

#pragma mark-
#pragma mark RestKit dynamic mapping
- (BOOL)validateLocation:(id *)ioValue error:(NSError **)outError
{
    *ioValue = [BNDuckTypedObject duckTypedObjectWrappingDictionary:*ioValue];
    return YES;
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

