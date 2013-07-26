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
@dynamic uploadStatusNumber, primitiveUploadStatusNumber;
@dynamic sectionIdentifier, primitiveSectionIdentifier;
@dynamic newPiecesToView;

- (void)awakeFromFetch
{
    [super awakeFromFetch];
    self.newPiecesToView = self.viewedByCurUser && self.currentPieceNum > 0 ? YES  : NO;
    
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

@end
