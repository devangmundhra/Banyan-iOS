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
#import "Piece_Defines.h"
#import "RemoteObject+Share.h"

@implementation Piece

@dynamic longText;
@dynamic pieceNumber;
@dynamic shortText;
@dynamic story;
@dynamic tags;
@dynamic creatingGifFromMedia;

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
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:kBNPieceClassKey inManagedObjectContext:story.managedObjectContext]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(%K == %@) AND (story = %@)",
							  attribute, value, story];
    [request setPredicate:predicate];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"pieceNumber" ascending:YES];
    [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    [request setFetchLimit:1];
    
    NSError *error = nil;
    NSArray *array = [story.managedObjectContext executeFetchRequest:request error:&error];
    
    return array.count ? [array objectAtIndex:0] : nil;
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
    [pieceMapping addAttributeMappingsFromArray:@[@"bnObjectId", PIECE_NUMBER, PIECE_LONGTEXT, PIECE_SHORTTEXT, @"isLocationEnabled", @"location",
                                                  @"createdAt", @"updatedAt", @"timeStamp"]];
    [pieceMapping addAttributeMappingsFromDictionary:@{@"stats.numViews" : @"numberOfViews",
                                                       @"stats.numLikes" : @"numberOfLikes",
                                                       @"stats.userViewed" : @"viewedByCurUser",
                                                       @"stats.userLiked" : @"likedByCurUser",
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
    [pieceRequestMapping addAttributeMappingsFromDictionary:@{@"author.resourceUri" : @"author", @"story.resourceUri" : PIECE_STORY}];
    [pieceRequestMapping addAttributeMappingsFromArray:@[PIECE_LONGTEXT, PIECE_SHORTTEXT, @"isLocationEnabled", @"timeStamp", @"location"]];
    return pieceRequestMapping;
}

+ (RKEntityMapping *)pieceResponseMappingForRKPOST
{
    RKEntityMapping *pieceResponseMapping = [RKEntityMapping mappingForEntityForName:kBNPieceClassKey
                                                                inManagedObjectStore:[RKManagedObjectStore defaultStore]];
    [pieceResponseMapping addAttributeMappingsFromDictionary:@{@"resource_uri": @"resourceUri"}];
    [pieceResponseMapping addAttributeMappingsFromArray:@[@"createdAt", @"updatedAt", PIECE_NUMBER, @"permaLink", @"bnObjectId"]];
    pieceResponseMapping.identificationAttributes = @[@"bnObjectId"];
    return pieceResponseMapping;
}

+ (RKObjectMapping *)pieceRequestMappingForRKPUT
{
    // We start with the request mapping for POST because it is possible that while the piece is being updated, somebody deletes the piece.
    // In that case, it we start with the request mapping for POST, then the piece will atleast get recreated.
    RKObjectMapping *pieceRequestMapping = [Piece pieceRequestMappingForRKPOST];
    [pieceRequestMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"media" toKeyPath:@"media" withMapping:[Media mediaRequestMapping]]];
    return pieceRequestMapping;
}

+ (RKEntityMapping *)pieceResponseMappingForRKPUT
{
    RKEntityMapping *pieceResponseMapping = [RKEntityMapping mappingForEntityForName:kBNPieceClassKey
                                                                inManagedObjectStore:[RKManagedObjectStore defaultStore]];
    [pieceResponseMapping addAttributeMappingsFromArray:@[@"updatedAt"]];
    return pieceResponseMapping;
}


@end
