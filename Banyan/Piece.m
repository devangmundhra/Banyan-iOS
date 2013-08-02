//
//  Piece.m
//  Banyan
//
//  Created by Devang Mundhra on 4/25/13.
//
//

#import "Piece.h"
#import "Story.h"


@implementation Piece

@dynamic longText;
@dynamic pieceNumber;
@dynamic shortText;
@dynamic story;
@dynamic tags;
@dynamic timeStamp;
@dynamic creatingGifFromMedia;

+ (NSArray *)oldPiecesInStory:(Story *)story
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:kBNPieceClassKey inManagedObjectContext:[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(remoteStatusNumber = %@) AND (bnObjectId != NULL) AND (story = %@) AND (lastSynced <= %@)",
							  [NSNumber numberWithInt:RemoteObjectStatusSync], story, [NSDate dateWithTimeIntervalSinceNow:-60*2]];
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

+ (NSArray *)unsavedPiecesInStory:(Story *)story
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:kBNPieceClassKey inManagedObjectContext:[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(remoteStatusNumber = %@) AND (bnObjectId == NULL) AND (story = %@)",
							  [NSNumber numberWithInt:RemoteObjectStatusLocal], story];
    [request setPredicate:predicate];
    
    NSError *error = nil;
    NSArray *array = [[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext executeFetchRequest:request error:&error];
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
    [request setEntity:[NSEntityDescription entityForName:kBNPieceClassKey inManagedObjectContext:[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(%K == %@) AND (story = %@)",
							  attribute, value, story];
    [request setPredicate:predicate];
    [request setFetchLimit:1];
    
    NSError *error = nil;
    NSArray *array = [[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext executeFetchRequest:request error:&error];
    
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
    UPDATE_STORY_LIST(nil);
}

#pragma mark share
- (void) shareOnFacebook
{
    
}

@end
