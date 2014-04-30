//
//  Piece.m
//  Banyan
//
//  Created by Devang Mundhra on 4/25/13.
//
//

#import "Piece.h"
#import "Story.h"
#import "User.h"
#import "Media.h"
#import "RemoteObject+Share.h"
#import "Piece+Create.h"
#import "Piece+Edit.h"

@implementation Piece

@dynamic longText;
@dynamic shortText;
@dynamic story;
@dynamic tags;

+ (NSArray *)oldPiecesInStory:(Story *)story
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:kBNPieceClassKey inManagedObjectContext:story.managedObjectContext]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(remoteStatusNumber = %@) AND (bnObjectId != NULL) AND (story = %@) AND (lastSynced <= %@)",
							  [NSNumber numberWithInt:RemoteObjectStatusSync], story, [NSDate dateWithTimeIntervalSinceNow:-60*2]];
    [request setPredicate:predicate];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createdAt" ascending:YES];
    [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    
    NSError *error = nil;
    NSArray *array = [story.managedObjectContext executeFetchRequest:request error:&error];
    if (array == nil) {
        array = [NSArray array];
    }
    return array;
}

+ (NSArray *)unsavedPiecesInStory:(Story *)story
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:kBNPieceClassKey inManagedObjectContext:story.managedObjectContext]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(remoteStatusNumber = %@) AND (bnObjectId == NULL) AND (story = %@)",
							  [NSNumber numberWithInt:RemoteObjectStatusLocal], story];
    [request setPredicate:predicate];
    
    NSError *error = nil;
    NSArray *array = [story.managedObjectContext executeFetchRequest:request error:&error];
    if (array == nil) {
        array = [NSArray array];
    }
    return array;
}

+ (NSArray *)piecesFailedToBeUploaded
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:kBNPieceClassKey inManagedObjectContext:[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(remoteStatusNumber = %@)",
							  [NSNumber numberWithInt:RemoteObjectStatusFailed]];
    [request setPredicate:predicate];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createdAt" ascending:YES];
    [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    
    NSError *error = nil;
    NSArray *array = [[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext executeFetchRequest:request error:&error];
    if (array == nil) {
        array = [NSArray array];
    }
    return array;
}

+ (Piece *)pieceForStory:(Story *)story withAttribute:(NSString *)attribute asValue:(id)value
{
    NSArray *array = [self piecesForStory:story withAttribute:attribute asValue:value];
    return array.count ? [array objectAtIndex:0] : nil;
}

+ (NSUInteger)numPiecesForStory:(Story *)story withAttribute:(NSString *)attribute asValue:(id)value
{
    NSArray *array = [self piecesForStory:story withAttribute:attribute asValue:value];
    return array.count;
}

+ (NSArray *)piecesForStory:(Story *)story withAttribute:(NSString *)attribute asValue:(id)value
{
    if (!story) {
        /* This is possible in the following scenario:
         * 1. Story list refresh is occuring
         * 2. A new piece is created
         * 3. Story refresh completes before the new piece is fully uploaded, so the connection to the story of the piece is deleted
         * 4. piece.story is nil, so calling this method after that will return here
         */
        return nil;
    }
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:kBNPieceClassKey inManagedObjectContext:story.managedObjectContext]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(%K == %@) AND (story = %@)",
							  attribute, value, story];
    [request setPredicate:predicate];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timeStamp" ascending:YES];
    [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    
    NSError *error = nil;
    NSArray *array = [story.managedObjectContext executeFetchRequest:request error:&error];
    
    return array;
}

- (void)uploadFailedRemoteObject
{
    if (NUMBER_EXISTS(self.bnObjectId)) {
        [Piece editPiece:self];
    }
    else {
        [Piece createNewPiece:self];
    }
}

-(void)setRemoteStatusNumber:(NSNumber *)remoteStatusNumber
{
    [self willChangeValueForKey:@"remoteStatusNumber"];
    [self setPrimitiveRemoteStatusNumber:remoteStatusNumber];
    [self didChangeValueForKey:@"remoteStatusNumber"];
    
    [self.story setUploadStatusNumber:[self.story calculateUploadStatusNumber]];
}

- (void) remove
{
    Story *story = self.story;
    [super remove];
    // This needs to be done because otherwise removing a piece does not update the story's uploadStatusNumber
    [story setUploadStatusNumber:[story calculateUploadStatusNumber]];
}

- (NSString *)getIdentifierForMediaFileName
{
    if (self.shortText.length)
        return [self.shortText substringToIndex:MIN(10, self.shortText.length)];
    else if (self.longText.length)
        return [self.longText substringToIndex:MIN(10, self.longText.length)];
    else
        return [BNMisc genRandStringLength:10];
}
@end

@implementation Piece (RestKitMappings)

+ (RKEntityMapping *)pieceMappingForRKGET
{
    RKEntityMapping *pieceMapping = [RKEntityMapping mappingForEntityForName:kBNPieceClassKey
                                                        inManagedObjectStore:[RKManagedObjectStore defaultStore]];
    [pieceMapping addAttributeMappingsFromArray:@[@"bnObjectId", @"longText", @"shortText", @"location",
                                                  @"createdAt", @"updatedAt", @"timeStamp"]];
    [pieceMapping addAttributeMappingsFromDictionary:@{@"stats.numViews" : @"numberOfViews",
                                                       @"stats.numLikes" : @"numberOfLikes",
                                                       @"stats.userViewed" : @"viewedByCurUser",
                                                       @"stats.likeActivity" : @"likeActivityResourceUri",
                                                       @"resource_uri" : @"resourceUri",
                                                       @"perma_link" : @"permaLink",
                                                       }];
    pieceMapping.identificationAttributes = @[@"bnObjectId"];
    
    // Media
    [pieceMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"media"
                                                                                 toKeyPath:@"media"
                                                                               withMapping:[Media mediaMappingForRKGET]]];
    
    // Author
    [pieceMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"author" toKeyPath:@"author" withMapping:[User UserMappingForRKGET]]];
    return pieceMapping;
}

+ (RKObjectMapping *)pieceRequestMappingForRKPOST
{
    RKObjectMapping *pieceRequestMapping = [RKObjectMapping requestMapping];
    [pieceRequestMapping addAttributeMappingsFromDictionary:@{@"author.resourceUri" : @"author", @"story.resourceUri" : @"story"}];
    [pieceRequestMapping addAttributeMappingsFromArray:@[@"longText", @"shortText", @"timeStamp", @"location"]];
    [pieceRequestMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"media" toKeyPath:@"media" withMapping:[Media mediaRequestMapping]]];
    return pieceRequestMapping;
}

+ (RKEntityMapping *)pieceResponseMappingForRKPOST
{
    RKEntityMapping *pieceResponseMapping = [RKEntityMapping mappingForEntityForName:kBNPieceClassKey
                                                                inManagedObjectStore:[RKManagedObjectStore defaultStore]];
    [pieceResponseMapping addAttributeMappingsFromDictionary:@{@"resource_uri": @"resourceUri",
                                                               @"stats.numViews" : @"numberOfViews",
                                                               @"stats.numLikes" : @"numberOfLikes",
                                                               @"stats.userViewed" : @"viewedByCurUser",
                                                               @"stats.likeActivity" : @"likeActivityResourceUri",}];
    [pieceResponseMapping addAttributeMappingsFromArray:@[@"createdAt", @"updatedAt", @"permaLink", @"bnObjectId"]];
    pieceResponseMapping.identificationAttributes = @[@"bnObjectId"];
    return pieceResponseMapping;
}

+ (RKObjectMapping *)pieceRequestMappingForRKPUT
{
    // We start with the request mapping for POST because it is possible that while the piece is being updated, somebody deletes the piece.
    // In that case, it we start with the request mapping for POST, then the piece will atleast get recreated.
    RKObjectMapping *pieceRequestMapping = [Piece pieceRequestMappingForRKPOST];
    return pieceRequestMapping;
}

+ (RKEntityMapping *)pieceResponseMappingForRKPUT
{
    RKEntityMapping *pieceResponseMapping = [RKEntityMapping mappingForEntityForName:kBNPieceClassKey
                                                                inManagedObjectStore:[RKManagedObjectStore defaultStore]];
    [pieceResponseMapping addAttributeMappingsFromArray:@[@"updatedAt"]];
    pieceResponseMapping.identificationAttributes = @[@"bnObjectId"];
    return pieceResponseMapping;
}


@end
