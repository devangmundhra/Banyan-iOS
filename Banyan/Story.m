//
//  Story.m
//  Banyan
//
//  Created by Devang Mundhra on 4/25/13.
//
//

#import "Story.h"
#import "Piece.h"
#import "Media.h"
#import "Story+Permissions.h"
#import "User.h"
#import "Story_Defines.h"

@implementation Story

@dynamic canContribute;
@dynamic canView;
@dynamic contributors;
@dynamic isInvited;
@dynamic length;
@dynamic readAccess;
@dynamic currentPieceNum;
@dynamic tags;
@dynamic title;
@dynamic writeAccess;
@dynamic pieces;
@dynamic uploadStatusNumber, primitiveUploadStatusNumber;
@dynamic sectionIdentifier, primitiveSectionIdentifier;
@dynamic newPiecesToView;

- (void)awakeFromFetch
{
    [super awakeFromFetch];
    self.currentPieceNum = self.currentPieceNum > self.length ? self.length : self.currentPieceNum;
    self.newPiecesToView = self.viewedByCurUser && self.currentPieceNum > 0 ? YES  : NO;
    [self setUploadStatusNumber:[self calculateUploadStatusNumber]];
}

+ (NSArray *)syncedStories
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:kBNStoryClassKey inManagedObjectContext:[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(remoteStatusNumber = %@) AND (bnObjectId != NULL)",
							  [NSNumber numberWithInt:RemoteObjectStatusSync]];
    [request setPredicate:predicate];
    
    NSError *error = nil;
    NSArray *array = [[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext executeFetchRequest:request error:&error];
    if (array == nil) {
        array = [NSArray array];
    }
    return array;
}

+ (NSArray *)unsavedStories
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:kBNStoryClassKey inManagedObjectContext:[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(remoteStatusNumber = %@) AND (bnObjectId == NULL)",
							  [NSNumber numberWithInt:RemoteObjectStatusLocal]];
    [request setPredicate:predicate];
    
    NSError *error = nil;
    NSArray *array = [[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext executeFetchRequest:request error:&error];
    if (array == nil) {
        array = [NSArray array];
    }
    return array;
}

+ (NSArray *)storiesFailedToBeUploaded
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:kBNStoryClassKey inManagedObjectContext:[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(remoteStatusNumber = %@)",
							  [NSNumber numberWithInt:RemoteObjectStatusFailed]];
    [request setPredicate:predicate];
    
    NSError *error = nil;
    NSArray *array = [[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext executeFetchRequest:request error:&error];
    if (array == nil) {
        array = [NSArray array];
    }
    return array;
}

+ (Story *)getCurrentOngoingStoryToContribute
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSURL *currentOngingStory = [defaults URLForKey:BNUserDefaultsCurrentOngoingStoryToContribute];
    
    if (!currentOngingStory)
        return nil;
    
    NSManagedObjectID *storyId = [[RKManagedObjectStore defaultStore].persistentStoreCoordinator managedObjectIDForURIRepresentation:currentOngingStory];
    NSError *error = nil;
    Story *story = (Story *)[[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext existingObjectWithID:storyId error:&error];
    if (error) {
        NSLog(@"Error in fetching current story: %@", error);
        [defaults removeObjectForKey:BNUserDefaultsCurrentOngoingStoryToContribute];
    }
    return story;
}

+ (NSArray *)getStoriesUserCanContributeTo
{
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:kBNStoryClassKey];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(canContribute == YES)",
							  [NSNumber numberWithInt:RemoteObjectStatusFailed]];
    [request setPredicate:predicate];
    
    NSSortDescriptor *uploadStatusSD = [NSSortDescriptor sortDescriptorWithKey:@"uploadStatusNumber" ascending:YES];
    NSSortDescriptor *newPiecesSD = [NSSortDescriptor sortDescriptorWithKey:@"newPiecesToView" ascending:YES];
    NSSortDescriptor *dateSD = [NSSortDescriptor sortDescriptorWithKey:@"updatedAt"
                                                             ascending:NO
                                                              selector:@selector(compare:)];
    request.sortDescriptors = [NSArray arrayWithObjects:uploadStatusSD, newPiecesSD, dateSD, nil];
    
    NSError *error = nil;
    NSArray *array = [[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext executeFetchRequest:request error:&error];
    if (array == nil) {
        array = [NSArray array];
    }
    return array;
}

- (NSNumber *)calculateUploadStatusNumber
{
    if (self.remoteStatus != RemoteObjectStatusSync)
        return self.remoteStatusNumber;
    
    // This story is synchronized, but there could be
    // some pieces that have not been updated yet.
    __block NSNumber *statusNum = self.remoteStatusNumber;
    [self.pieces enumerateObjectsUsingBlock:^(Piece *piece, NSUInteger idx, BOOL *stop) {
        if (piece.remoteStatus != RemoteObjectStatusSync) {
            statusNum = [NSNumber numberWithInt:piece.remoteStatus];
            *stop = YES;
        }
    }];
    
    return statusNum;
}

- (NSString *)uploadStatusString
{
    switch ([self.uploadStatusNumber intValue]) {
        case RemoteObjectStatusPushing:
            return NSLocalizedString(@"Uploading", @"");
            break;
        case RemoteObjectStatusFailed:
            return NSLocalizedString(@"Failed to upload", @"");
            break;
        case RemoteObjectStatusSync:
            return NSLocalizedString(@"Stories", @"");
            break;
        default:
            return NSLocalizedString(@"Drafts", @"");
            break;
    }
}

-(NSString*) sectionIdentifier
{
    [self willAccessValueForKey:@"sectionIdentifier"];
    NSString *tmp = [self primitiveSectionIdentifier];
    [self didAccessValueForKey:@"sectionIdentifier"];
    
    if (!tmp) {
        tmp = [self uploadStatusString];
        [self setPrimitiveSectionIdentifier:tmp];
    }
    
    return tmp;
}

+ (NSSet*) keyPathsForValuesAffectingSectionIdentifier
{
    return [NSSet setWithObject:@"uploadStatusNumber"];
}

-(void)setRemoteStatusNumber:(NSNumber *)remoteStatusNumber
{
    [self willChangeValueForKey:@"remoteStatusNumber"];
    [self setPrimitiveRemoteStatusNumber:remoteStatusNumber];
    [self didChangeValueForKey:@"remoteStatusNumber"];
    
    [self setUploadStatusNumber:[self calculateUploadStatusNumber]];
}

- (void) setUploadStatusNumber:(NSNumber *)uploadStatusNumber
{
    [self willChangeValueForKey:@"uploadStatusNumber"];
    [self setPrimitiveUploadStatusNumber:uploadStatusNumber];
    [self didChangeValueForKey:@"uploadStatusNumber"];
    
    [self setPrimitiveSectionIdentifier:nil];
    //    [self.managedObjectContext refreshObject:self mergeChanges:YES];
}

- (void) share
{
    if (self.remoteStatus != RemoteObjectStatusSync) {
        NSLog(@"%s Can't share yet as story with title %@ is not sync'ed", __PRETTY_FUNCTION__, self.title);
        return;
    }
    
    [[FBSession activeSession] requestNewPublishPermissions:[NSArray arrayWithObject:@"publish_stream"]
                                            defaultAudience:FBSessionDefaultAudienceFriends
                                          completionHandler:^(FBSession *session, NSError *error) {
                                              if (error) {
                                                  NSLog(@"Error %@ in getting permissions to publish", [error localizedDescription]);
                                              }
                                          }];
    
    UIImage *image = nil;
    // TO DO: Add image
    
    [FBDialogs presentOSIntegratedShareDialogModallyFrom:[UIApplication sharedApplication].keyWindow.rootViewController
                                             initialText:self.title
                                                   image:image
                                                     url:[NSURL URLWithString:self.permaLink]
                                                 handler:nil];
    
    [TestFlight passCheckpoint:@"Story shared"];
}

- (void) saveStoryMOIdToUserDefaults
{
    // Save this story in the UserDefaults so that next time the user will add a piece here.
    NSError *error = nil;
    BOOL returnVal = [self.managedObjectContext obtainPermanentIDsForObjects:@[self] error:&error];
    if (!returnVal) {
        NSLog(@"Failed to obtain the permanentIds of the story because of error %@", error);
    } else {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setURL:[[self objectID] URIRepresentation] forKey:BNUserDefaultsCurrentOngoingStoryToContribute];
        [defaults synchronize];
    }
}

#pragma mark share
- (void) shareOnFacebook
{
    NSArray *contributorsList = [self storyContributors];
    
    NSMutableArray *fbIds = [NSMutableArray arrayWithCapacity:1];
    for (NSDictionary *contributor in contributorsList)
    {
        if (![[contributor objectForKey:@"id"] isEqualToString:[BNSharedUser currentUser].facebookId])
            [fbIds addObject:[contributor objectForKey:@"id"]];
    }
    
    FBShareDialogParams *params = [[FBShareDialogParams alloc] init];
    params.dataFailuresFatal = NO;
    params.caption = self.title;
    params.description = @"Check this new story out!";
    params.friends = fbIds;
    Media *imageMedia = [Media getMediaOfType:@"image" inMediaSet:self.media];
    params.picture = [NSURL URLWithString:imageMedia.remoteURL];
    params.ref = @"Story";
    [FBDialogs presentShareDialogWithParams:params clientState:nil handler:nil];
}

+ (RKEntityMapping *)storyMappingForRK
{
    RKEntityMapping *storyMapping = [RKEntityMapping mappingForEntityForName:kBNStoryClassKey
                                                        inManagedObjectStore:[RKManagedObjectStore defaultStore]];
    [storyMapping addAttributeMappingsFromDictionary:@{
                                                       @"permission.canRead" : @"canView",
                                                       @"permission.canWrite" : @"canContribute",
                                                       @"permission.isInvited" : @"isInvited",
                                                       @"stats.numViews" : @"numberOfViews",
                                                       @"stats.numLikes" : @"numberOfLikes",
                                                       @"stats.userViewed" : @"viewedByCurUser",
                                                       @"stats.userLiked" : @"likedByCurUser",
                                                       @"firstUnviewedPieceNumByUser" : @"currentPieceNum",
                                                       @"resource_uri" : @"resourceUri",
                                                       }];
    storyMapping.identificationAttributes = @[@"bnObjectId"];
    
    [storyMapping addAttributeMappingsFromArray:@[@"bnObjectId", STORY_TITLE, STORY_READ_ACCESS, STORY_WRITE_ACCESS, STORY_TAGS, STORY_LENGTH, @"permaLink",
                                                  @"createdAt", @"updatedAt", @"isLocationEnabled", @"location"]];
    [storyMapping addPropertyMappingsFromArray:@[[RKRelationshipMapping relationshipMappingFromKeyPath:@"pieces" toKeyPath:@"pieces" withMapping:[Piece pieceMappingForRK]],
                                                 [RKRelationshipMapping relationshipMappingFromKeyPath:@"coverMedia" toKeyPath:@"media" withMapping:[Media mediaMappingForRK]],
                                                 [RKRelationshipMapping relationshipMappingFromKeyPath:@"author" toKeyPath:@"author" withMapping:[User UserMappingForRK]]]];
    
    return storyMapping;
}

- (NSString *)getIdentifierForMediaFileName
{
    if (self.title.length)
        return [self.title substringToIndex:MIN(10, self.title.length)];
    else
        return [BNMisc genRandStringLength:10];
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
