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
#import "BanyanAppDelegate.h"
#import "Piece_Defines.h"

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
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"pieceNumber" ascending:YES];
    [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
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
    NSURL *urlToShare = [NSURL URLWithString:self.permaLink];
    Media *imageMedia = [Media getMediaOfType:@"image" inMediaSet:self.media];
    NSURL *imageURL = [NSURL URLWithString:REPLACE_EMPTY_STRING_WITH_NIL(imageMedia.remoteURL)];
    
    NSString *message = nil;
    NSString *shortText = REPLACE_EMPTY_STRING_WITH_NIL(self.shortText);
    NSString *longText = REPLACE_EMPTY_STRING_WITH_NIL(self.longText);
    if (shortText) {
        message = [NSString stringWithString:shortText];
        if (longText)
            message = [message stringByAppendingFormat:@"\n%@", longText];
    }
    else if (longText) {
        message = [NSString stringWithString:longText];
    }
    
    // This code demonstrates 3 different ways of sharing using the Facebook SDK.
    // The first method tries to share via the Facebook app. This allows sharing without
    // the user having to authorize your app, and is available as long as the user has the
    // correct Facebook app installed. This publish will result in a fast-app-switch to the
    // Facebook app.
    // The second method tries to share via Facebook's iOS6 integration, which also
    // allows sharing without the user having to authorize your app, and is available as
    // long as the user has linked their Facebook account with iOS6. This publish will
    // result in a popup iOS6 dialog.
    // The third method tries to share via a Graph API request. This does require the user
    // to authorize your app. They must also grant your app publish permissions. This
    // allows the app to publish without any user interaction.
    
    // If it is available, we will first try to post using the share dialog in the Facebook app
    FBAppCall *appCall = [FBDialogs presentShareDialogWithLink:urlToShare
                                                          name:self.story.title
                                                       caption:shortText
                                                   description:longText
                                                       picture:imageURL
                                                   clientState:nil
                                                       handler:^(FBAppCall *call, NSDictionary *results, NSError *error) {
                                                           if (error) {
                                                               NSLog(@"Error: %@", error.description);
                                                           } else {
                                                               NSLog(@"Success!");
                                                           }
                                                       }];
    
    if (!appCall && imageMedia) {
        [imageMedia getImageForMediaWithSuccess:^(UIImage *image) {
            // Next try to post using Facebook's iOS6 integration
            BOOL displayedNativeDialog = [FBDialogs presentOSIntegratedShareDialogModallyFrom:[BanyanAppDelegate topMostController]
                                                                                  initialText:message
                                                                                        image:image
                                                                                          url:urlToShare
                                                                                      handler:nil];
            
            if (!displayedNativeDialog) {
                // Lastly, fall back on a request for permissions and a direct post using the Graph API
                [self performFacebookPublishAction:^{
                    [FBRequestConnection startForUploadPhoto:image
                                           completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                                                [self showAlert:shortText?shortText:longText result:result error:error];
                                           }];
                    
                }];
            }
        } failure:^(NSError *error) {
            [self showAlert:message result:nil error:error];
        }];
    } else {
        BOOL displayedNativeDialog = [FBDialogs presentOSIntegratedShareDialogModallyFrom:[BanyanAppDelegate topMostController]
                                                                              initialText:message
                                                                                    image:nil
                                                                                      url:urlToShare
                                                                                  handler:nil];
        
        if (!displayedNativeDialog) {
            // Lastly, fall back on a request for permissions and a direct post using the Graph API
            [self performFacebookPublishAction:^{
                [FBRequestConnection startForPostStatusUpdate:message place:self.location?self.location:nil tags:nil completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                    [self showAlert:shortText?shortText:longText result:result error:error];
                }];                
            }];
        }
    }
}

+ (RKEntityMapping *)pieceMappingForRK
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
                                                                               withMapping:[Media mediaMappingForRK]]];
    
    // Author
    [pieceMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"author" toKeyPath:@"author" withMapping:[User UserMappingForRK]]];
    return pieceMapping;
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
