//
//  Piece.m
//  Banyan
//
//  Created by Devang Mundhra on 3/26/13.
//
//

#import "Piece.h"
#import "Story.h"

@implementation Piece

@dynamic favourite;
@dynamic geocodedLocation;
@dynamic imageChanged;
@dynamic imageName;
@dynamic imageURL;
@dynamic liked;
@dynamic likers;
@dynamic longText;
@dynamic numberOfContributors;
@dynamic numberOfLikes;
@dynamic numberOfViews;
@dynamic pieceNumber;
@dynamic shortText;
@dynamic viewed;
@dynamic latitude;
@dynamic location;
@dynamic longitude;
@dynamic story;

+ (NSArray *)syncedPiecesInStory:(Story *)story
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:kBNPieceClassKey inManagedObjectContext:[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(remoteStatusNumber = %@) AND (bnObjectId != NULL) AND (story = %@)",
							  [NSNumber numberWithInt:RemoteObjectStatusSync], story];
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
    
    NSError *error = nil;
    NSArray *array = [[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext executeFetchRequest:request error:&error];

    return array.count ? [array objectAtIndex:0] : nil;
}

@end
