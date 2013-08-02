//
//  BanyanConnection.m
//  Banyan
//
//  Created by Devang Mundhra on 11/11/12.
//
//

#import "BanyanConnection.h"
#import "AFBanyanAPIClient.h"
#import "Story_Defines.h"
#import "Story+Stats.h"
#import "Piece+Stats.h"
#import "Story+Permissions.h"
#import "Story+Edit.h"
#import "Piece+Edit.h"
#import "User.h"
#import "Media.h"
#import "Story+Create.h"
#import "Piece+Create.h"

@implementation BanyanConnection

+ (void)initialize
{
    // Notifications to handle permission controls
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userLoginStatusChanged:)
                                                 name:BNUserLogInNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userLoginStatusChanged:)
                                                 name:BNUserLogOutNotification
                                               object:nil];
}

+ (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

# pragma Storing the stories for this app
+ (void) userLoginStatusChanged:(NSNotification *)notification
{
    if ([[notification name] isEqualToString:BNUserLogOutNotification]) {
        // Get all the stories in the database
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kBNStoryClassKey];
        
        NSError *error = nil;
        NSArray *stories = [[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext executeFetchRequest:request error:&error];
        
        if (stories)
        {
            [BanyanConnection resetPermissionsForStories:stories];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:BNStoryListRefreshedNotification
                                                                object:self];
        });
    } else if ([[notification name] isEqualToString:BNUserLogInNotification]) {
        [self loadDataSource];
    } else {
        NSLog(@"%s Unknown notification %@", __PRETTY_FUNCTION__, [notification name]);
    }
}

+ (void) loadDataSource
{    
    NSLog(@"%s loadDataSource begin", __PRETTY_FUNCTION__);
    
    [BanyanConnection
     loadStoriesFromBanyanWithSuccessBlock:^ {
         NSLog(@"%s loadDataSource completed", __PRETTY_FUNCTION__);
         dispatch_async(dispatch_get_main_queue(), ^{
             [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
             NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
             [userDefaults setObject:[NSDate date] forKey:BNUserDefaultsLastSuccessfulStoryUpdateTime];
             [userDefaults synchronize];
             
             [[NSNotificationCenter defaultCenter] postNotificationName:BNStoryListRefreshedNotification
                                                                 object:self];
             NSError *error = nil;
             [[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext saveToPersistentStore:&error];
         });
     } errorBlock:^(NSError *error) {
         UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error in fetching stories."
                                                         message:[error localizedDescription]
                                                        delegate:nil
                                               cancelButtonTitle:@"OK"
                                               otherButtonTitles:nil];
         [alert show];
         [[NSNotificationCenter defaultCenter] postNotificationName:BNStoryListRefreshedNotification
                                                             object:self];
         NSLog(@"Hit error: %@", error);
     }];
}

+ (void)loadStoriesFromBanyanWithSuccessBlock:(void (^)())successBlock errorBlock:(void (^)(NSError *error))errorBlock
{
    NSString *getPath = BANYAN_API_GET_PUBLIC_STORIES();
    if ([PFUser currentUser]) {
        getPath = BANYAN_API_GET_USER_STORIES([PFUser currentUser]);
    }
    
    // Initialize RestKit
    RKObjectManager *objectManager = [[RKObjectManager alloc] initWithHTTPClient:[AFBanyanAPIClient sharedClient]];
    objectManager.managedObjectStore = [RKManagedObjectStore defaultStore];
    
    // Story attributes
    RKEntityMapping *storyMapping = [RKEntityMapping mappingForEntityForName:kBNStoryClassKey
                                                        inManagedObjectStore:[RKManagedObjectStore defaultStore]];
    [storyMapping addAttributeMappingsFromDictionary:@{
     STORY_CAN_VIEW : @"canView",
     STORY_CAN_CONTRIBUTE : @"canContribute",
     STORY_IS_INVITED: @"isInvited",
     PARSE_OBJECT_ID : @"bnObjectId",
     @"numViews" : @"numberOfViews",
     @"numLikes" : @"numberOfLikes",
     @"userViewed" : @"viewedByCurUser",
     @"userLiked" : @"likedByCurUser",
     @"firstUnviewedPieceNumByUser" : @"currentPieceNum"
     }];
    storyMapping.identificationAttributes = @[@"bnObjectId"];
    
    [storyMapping addAttributeMappingsFromArray:@[STORY_TITLE, STORY_READ_ACCESS, STORY_WRITE_ACCESS, STORY_TAGS, STORY_LENGTH, @"permaLink",
                                                    PARSE_OBJECT_CREATED_AT, PARSE_OBJECT_UPDATED_AT, @"isLocationEnabled", @"location"]];
    // Media
    [storyMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"media" toKeyPath:@"media" withMapping:[Media mediaMappingForRK]]];
    
    // Author
    [storyMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"author" toKeyPath:@"author" withMapping:[User UserMappingForRK]]];
    
    // Response
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:storyMapping
                                                                                            method:RKRequestMethodGET
                                                                                       pathPattern:nil
                                                                                           keyPath:nil
                                                                                       statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    [objectManager addResponseDescriptor:responseDescriptor];
    
    NSDictionary *params = nil;
    if ([PFUser currentUser]) params = @{@"user": [PFUser currentUser].objectId};
    
    [objectManager getObjectsAtPath:getPath
                         parameters:params
                            success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
//                                // Delete all unsaved stories
//                                NSArray *unsavedStories = [Story unsavedStories];
//                                for (Story *story in unsavedStories) {
//                                    [story remove];
//                                }
                                
                                NSArray *stories = [mappingResult array];
                                // Delete stories that have been deleted on the server
                                NSArray *syncedStories =[Story syncedStories];
                                for (Story *story in syncedStories) {
                                    if (![stories containsObject:story])
                                        [story remove];
                                }
                                [stories enumerateObjectsUsingBlock:^(Story *story, NSUInteger idx, BOOL *stop) {
                                    NSArray *unsavedPieces = [Piece unsavedPiecesInStory:story];
                                    if (unsavedPieces.count)
                                        NSLog(@"%u unsaved pieces in story :%@", unsavedPieces.count, story.title);
//                                    for (Piece *piece in unsavedPieces) {
//                                        [piece remove];
//                                    }
                                    story.remoteStatus = RemoteObjectStatusSync;
                                    story.lastSynced = [NSDate date];
                                }];
                                if (successBlock)
                                    successBlock();                            }
                            failure:^(RKObjectRequestOperation *operation, NSError *error) {
                                if (errorBlock)
                                    errorBlock(error);
                            }];
}

+ (void)loadPiecesForStory:(Story *)story withParams:(NSDictionary *)params completionBlock:(void (^)())completionBlock errorBlock:(void (^)(NSError *))errorBlock
{
    // Initialize RestKit
    RKObjectManager *objectManager = [[RKObjectManager alloc] initWithHTTPClient:[AFBanyanAPIClient sharedClient]];
    objectManager.managedObjectStore = [RKManagedObjectStore defaultStore];
    
    // Piece attributes
    RKEntityMapping *pieceMapping = [RKEntityMapping mappingForEntityForName:kBNPieceClassKey
                                                        inManagedObjectStore:[RKManagedObjectStore defaultStore]];
    [pieceMapping addAttributeMappingsFromArray:@[PIECE_NUMBER, PIECE_LONGTEXT, PIECE_SHORTTEXT, @"isLocationEnabled", @"location",
                                                  PARSE_OBJECT_CREATED_AT, PARSE_OBJECT_UPDATED_AT, @"permaLink", @"timeStamp"]];
    [pieceMapping addAttributeMappingsFromDictionary:@{PARSE_OBJECT_ID : @"bnObjectId",
                                                       @"numViews" : @"numberOfViews",
                                                       @"numLikes" : @"numberOfLikes",
                                                       @"userViewed" : @"viewedByCurUser",
                                                       @"userLiked" : @"likedByCurUser"}];
    pieceMapping.identificationAttributes = @[@"bnObjectId"];
    
    // Media
    [pieceMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"media"
                                                                                 toKeyPath:@"media"
                                                                               withMapping:[Media mediaMappingForRK]]];
    
    // Author
    [pieceMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"author" toKeyPath:@"author" withMapping:[User UserMappingForRK]]];
    
    // Response
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:pieceMapping
                                                                                            method:RKRequestMethodGET
                                                                                       pathPattern:nil
                                                                                           keyPath:@"result.pieces"
                                                                                       statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    NSMutableDictionary *userParams = [NSMutableDictionary dictionaryWithDictionary:params];
    if ([PFUser currentUser])
        [userParams setObject:[PFUser currentUser].objectId forKey:@"user"];
    
    [objectManager addResponseDescriptor:responseDescriptor];
    
    [objectManager getObjectsAtPath:BANYAN_API_OBJECT_URL(kBNStoryClassKey, story.bnObjectId)
                         parameters:userParams
                            success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                                // Delete all unsaved pieces
                                NSArray *pieces = [mappingResult array];
                                if ([story isDeleted] || story.managedObjectContext == nil ) // Don't bother doing anything if story was deleted while fetching pieces
                                    return;
                                [pieces enumerateObjectsUsingBlock:^(Piece *piece, NSUInteger idx, BOOL *stop) {
                                    piece.story = story;
                                    piece.remoteStatus = RemoteObjectStatusSync;
                                    piece.lastSynced = [NSDate date];
                                }];
                                if (completionBlock)
                                    completionBlock();
                            }
                            failure:^(RKObjectRequestOperation *operation, NSError *error) {
                                if (errorBlock)
                                    errorBlock(error);
                            }];
}

+ (void) loadPiecesForStory:(Story *)story completionBlock:(void (^)())completionBlock errorBlock:(void (^)(NSError *error))errorBlock
{
    [self loadPiecesForStory:story
                  withParams:@{@"attributes" : @[@"pieces"]}
             completionBlock:^{
                 // By now we have got all the pieces for the story.
                 // Remove pieces which did not come as a part of this story (meaning they were deleted from the server)
                 NSArray *oldPieces =[Piece oldPiecesInStory:story];
                 for (Piece *piece in oldPieces) {
                     [piece remove];
                 }
                 completionBlock();
             }
                  errorBlock:errorBlock];
}

+ (void) loadPiecesForStory:(Story *)story atPieceNumbers:(NSArray *)pieceNumbers completionBlock:(void (^)())completionBlock errorBlock:(void (^)(NSError *error))errorBlock
{
    [self loadPiecesForStory:story withParams:@{@"pieces" : pieceNumbers}
             completionBlock:completionBlock
                  errorBlock:errorBlock];
}

+ (void) resetPermissionsForStories:(NSArray *)stories
{
    for (Story *story in stories)
    {
        [story resetPermission];
    }
}

+ (void) uploadFailedObjects
{
    NSArray *failedStories = [Story storiesFailedToBeUploaded];
    for (Story *story in failedStories) {
        if (story.bnObjectId.length)
            [Story editStory:story];
        else
            [Story createNewStory:story];
    }
    
    NSArray *failedPieces = [Piece piecesFailedToBeUploaded];
    for (Piece *piece in failedPieces) {
        if (piece.bnObjectId.length)
            [Piece editPiece:piece];
        else
            [Piece createNewPiece:piece];
    }
}

@end
