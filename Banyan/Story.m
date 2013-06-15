//
//  Story.m
//  Banyan
//
//  Created by Devang Mundhra on 4/25/13.
//
//

#import "Story.h"
#import "Piece.h"


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
@dynamic uploadStatusNumber;
@synthesize uploadStatusString = _uploadStatusString;

+ (NSArray *)syncedStories
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:kBNStoryClassKey inManagedObjectContext:[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(remoteStatusNumber = %@) AND (bnObjectId != NULL)",
							  [NSNumber numberWithInt:RemoteObjectStatusSync]];
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

+ (NSArray *)unsavedStories
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:kBNStoryClassKey inManagedObjectContext:[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(remoteStatusNumber = %@) AND (bnObjectId == NULL)",
							  [NSNumber numberWithInt:RemoteObjectStatusLocal]];
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

+ (NSArray *)storiesFailedToBeUploaded
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:kBNStoryClassKey inManagedObjectContext:[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext]];
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

- (NSNumber *)uploadStatusNumber
{    
    if (self.remoteStatus != RemoteObjectStatusSync)
        return self.remoteStatusNumber;
    
    // This story is synchronized, but there could be
    // some pieces that have not been updated yet.
    NSPredicate *unsavedPredicate = [NSPredicate predicateWithFormat:@"(remoteStatusNumber != %@)", [NSNumber numberWithInt:RemoteObjectStatusSync]];
    NSOrderedSet *unsavedPieces = [self.pieces filteredOrderedSetUsingPredicate:unsavedPredicate];
    if (unsavedPieces.count)
        return ((Piece *)[unsavedPieces firstObject]).remoteStatusNumber;
    else
        return self.remoteStatusNumber;
}

- (NSString *)uploadStatusString
{    
    switch ([self.uploadStatusNumber intValue]) {
        case RemoteObjectStatusPushing:
            return NSLocalizedString(@"Uploading...", @"");
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
    
    [TestFlight passCheckpoint:@"Piece shared"];
}

@end
